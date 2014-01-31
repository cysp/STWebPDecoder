//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2013-2014 Scott Talbot.

#import "STWebPDecoder.h"
#import "STWebPImage+Internal.h"

#import "lib/libwebp/src/webp/decode.h"
#import "lib/libwebp/src/webp/demux.h"


static void STCGDataProviderReleaseDataCallbackFree(void * __unused info, const void *data, size_t __unused size) {
	free((void *)data);
}


@implementation STWebPDecoder

+ (STWebPImage *)imageWithData:(NSData *)data error:(NSError * __autoreleasing *)error {
	WebPData const webpData = (WebPData){ .bytes = data.bytes, .size = data.length };
	WebPDemuxer *demux = WebPDemux(&webpData);
	if (!demux) {
		if (error) {
			*error = [NSError errorWithDomain:STWebPErrorDomain code:STWebPDecodeFailure userInfo:nil];
		}
		return nil;
	}

	uint32_t const w = WebPDemuxGetI(demux, WEBP_FF_CANVAS_WIDTH);
	uint32_t const h = WebPDemuxGetI(demux, WEBP_FF_CANVAS_HEIGHT);
	uint32_t const flags = WebPDemuxGetI(demux, WEBP_FF_FORMAT_FLAGS);
	uint32_t const frameCount = WebPDemuxGetI(demux, WEBP_FF_FRAME_COUNT);
	NSMutableArray *images = [[NSMutableArray alloc] initWithCapacity:frameCount];

	WebPIterator iter;
	if (!WebPDemuxGetFrame(demux, 1, &iter)) {
		WebPDemuxDelete(demux);
		if (error) {
			*error = [NSError errorWithDomain:STWebPErrorDomain code:STWebPDecodeFailure userInfo:nil];
		}
		return nil;
	}

	NSTimeInterval frameDurations[frameCount];
	NSTimeInterval totalDuration = 0;
	WebPDemuxGetFrame(demux, 1, &iter);
	do {
		NSTimeInterval const frameDuration = iter.duration / 1000.;
		frameDurations[iter.frame_num-1] = frameDuration;
		totalDuration += frameDuration;
	} while (WebPDemuxNextFrame(&iter));


	CGColorSpaceRef colorspace = NULL;

	WebPChunkIterator chunk_iter;
	if (flags & ICCP_FLAG) {
		WebPDemuxGetChunk(demux, "ICCP", 1, &chunk_iter);

		CFDataRef const iccpData = CFDataCreateWithBytesNoCopy(NULL, chunk_iter.chunk.bytes, chunk_iter.chunk.size, kCFAllocatorNull);
		colorspace = CGColorSpaceCreateWithICCProfile(iccpData);
		CFRelease(iccpData);
	}
	WebPDemuxReleaseChunkIterator(&chunk_iter);
	if (!colorspace) {
		colorspace = CGColorSpaceCreateDeviceRGB();
	}

	CGBitmapInfo const bitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast;
	CGContextRef canvas = CGBitmapContextCreate(NULL, w, h, 8, 0, colorspace, bitmapInfo);
	if (!canvas) {
		if (error) {
			*error = [NSError errorWithDomain:STWebPErrorDomain code:STWebPDecodeFailure userInfo:nil];
		}
		CGColorSpaceRelease(colorspace);
		return nil;
	}

	WebPDemuxGetFrame(demux, 1, &iter);
	do {
		WebPData const frameData = iter.fragment;

		int frameW = 0, frameH = 0;
		uint8_t *bitmapData = WebPDecodeBGRA(frameData.bytes, frameData.size, &frameW, &frameH);
		if (!bitmapData) {
			if (error) {
				*error = [NSError errorWithDomain:STWebPErrorDomain code:STWebPDecodeFailure userInfo:nil];
			}
			CGContextRelease(canvas);
			CGColorSpaceRelease(colorspace);
			return nil;
		}

		CGPoint const frameOrigin = (CGPoint){ .x = iter.x_offset, .y = (h - frameH) - iter.y_offset };
		CGSize const frameSize = (CGSize){ .width = frameW, .height = frameH };
		CGRect const frameRect = (CGRect){ .origin = frameOrigin, .size = frameSize };

		CGImageRef bitmap = NULL;
		{
			NSUInteger const bitsPerComponent = 8;
			NSUInteger const bytesPerPixel = 4;
			NSUInteger const bitsPerPixel = bitsPerComponent * bytesPerPixel;
			NSUInteger const stride = (NSUInteger)frameW * bytesPerPixel;

			CGBitmapInfo const bitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaFirst;

			CGDataProviderRef bitmapDataProvider = CGDataProviderCreateWithData(NULL, bitmapData, (size_t)(stride * frameH), STCGDataProviderReleaseDataCallbackFree);
			if (bitmapDataProvider) {
				bitmap = CGImageCreate((size_t)frameW, (size_t)frameH, bitsPerComponent, bitsPerPixel, stride, colorspace, bitmapInfo, bitmapDataProvider, NULL, YES, kCGRenderingIntentDefault);
				CGDataProviderRelease(bitmapDataProvider);
			}
		}
		if (!bitmap) {
			if (error) {
				*error = [NSError errorWithDomain:STWebPErrorDomain code:STWebPDecodeFailure userInfo:nil];
			}
			CGContextRelease(canvas);
			CGColorSpaceRelease(colorspace);
			return nil;
		}

		switch (iter.blend_method) {
			case WEBP_MUX_BLEND:
				break;
			case WEBP_MUX_NO_BLEND:
				CGContextClearRect(canvas, frameRect);
		}

		CGContextDrawImage(canvas, frameRect, bitmap);
		CFRelease(bitmap), bitmap = NULL;

		CGImageRef canvasImage = CGBitmapContextCreateImage(canvas);
		[images addObject:(__bridge id)canvasImage];
		CFRelease(canvasImage), canvasImage = NULL;

		switch (iter.dispose_method) {
			case WEBP_MUX_DISPOSE_NONE:
				break;
			case WEBP_MUX_DISPOSE_BACKGROUND:
				CGContextClearRect(canvas, frameRect);
				break;
		}
	} while (WebPDemuxNextFrame(&iter));

	CGContextRelease(canvas), canvas = NULL;
	CGColorSpaceRelease(colorspace), colorspace = NULL;

	WebPDemuxReleaseIterator(&iter), iter = (WebPIterator){ };
	WebPDemuxDelete(demux), demux = NULL;

	if (images.count == 1) {
		return [[STWebPImage alloc] initWithCGImages:images durations:@[ @1 ]];
	}

	NSMutableArray *durations = [[NSMutableArray alloc] initWithCapacity:images.count];
	for (NSUInteger i = 0; i < frameCount; ++i) {
		[durations addObject:@(frameDurations[i])];
	}

	return [[STWebPImage alloc] initWithCGImages:images durations:durations];
}

@end
