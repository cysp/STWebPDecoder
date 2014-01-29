//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2013 Scott Talbot.

#import "STWebPDecoder.h"

#import "lib/libwebp/src/webp/decode.h"
#import "lib/libwebp/src/webp/demux.h"


NSString * const STWebPErrorDomain = @"STWebP";


static void STCGDataProviderReleaseDataCallbackFree(void * __unused info, const void *data, size_t __unused size) {
	free((void *)data);
}


@implementation STWebPDecoder

+ (UIImage *)imageWithData:(NSData *)data error:(NSError * __autoreleasing *)error {
	return [self imageWithData:data scale:1 error:error];
}

+ (UIImage *)imageWithData:(NSData *)data scale:(CGFloat)scale error:(NSError * __autoreleasing *)error {
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

	NSTimeInterval duration = 0;

	WebPIterator iter;
	if (!WebPDemuxGetFrame(demux, 1, &iter)) {
		WebPDemuxDelete(demux);
		if (error) {
			*error = [NSError errorWithDomain:STWebPErrorDomain code:STWebPDecodeFailure userInfo:nil];
		}
		return nil;
	}

	NSTimeInterval frameDurations[frameCount];
	WebPDemuxGetFrame(demux, 1, &iter);
	do {
		frameDurations[iter.frame_num] = iter.duration / 1000.;
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

		CGImageRef canvasBitmap = CGBitmapContextCreateImage(canvas);
		UIImage *image = [[UIImage alloc] initWithCGImage:canvasBitmap scale:scale orientation:UIImageOrientationUp];
		CFRelease(canvasBitmap), canvasBitmap = NULL;

		switch (iter.dispose_method) {
			case WEBP_MUX_DISPOSE_NONE:
				break;
			case WEBP_MUX_DISPOSE_BACKGROUND:
				CGContextClearRect(canvas, frameRect);
				break;
		}

		[images addObject:image];
		duration += iter.duration / 1000.;
	} while (WebPDemuxNextFrame(&iter));

	CGContextRelease(canvas), canvas = NULL;
	CGColorSpaceRelease(colorspace), colorspace = NULL;

	WebPDemuxReleaseIterator(&iter), iter = (WebPIterator){ };

	// ... (Extract metadata).
//	WebPChunkIterator chunk_iter;
//	if (flags & ICCP_FLAG) WebPDemuxGetChunk(demux, "ICCP", 1, &chunk_iter);
//	// ... (Consume the ICC profile in 'chunk_iter.chunk').
//	WebPDemuxReleaseChunkIterator(&chunk_iter);
//	if (flags & EXIF_FLAG) WebPDemuxGetChunk(demux, "EXIF", 1, &chunk_iter);
//	// ... (Consume the EXIF metadata in 'chunk_iter.chunk').
//	WebPDemuxReleaseChunkIterator(&chunk_iter);
//	if (flags & XMP_FLAG) WebPDemuxGetChunk(demux, "XMP ", 1, &chunk_iter);
//	// ... (Consume the XMP metadata in 'chunk_iter.chunk').
//	WebPDemuxReleaseChunkIterator(&chunk_iter);


	WebPDemuxDelete(demux), demux = NULL;

	if (images.count == 1) {
		return images.lastObject;
	}

	UIImage * const image = [UIImage animatedImageWithImages:images duration:duration];
	return image;
}

@end


@implementation STWebPStreamingDecoder {
@private
	WebPIDecoder *_decoder;
}

+ (instancetype)decoderWithData:(NSData *)data {
	return [[self alloc] initWithData:data];
}

- (id)init {
	return [self initWithData:nil];
}

- (id)initWithData:(NSData *)data {
	if ((self = [super init])) {
		_decoder = WebPINewRGB(MODE_BGRA, NULL, 0, 0);
		_state = STWebPStreamingDecoderStateIncomplete;

		if (data) {
			[self updateWithData:data];
		}
	}
	return self;
}

- (void)dealloc {
	WebPIDelete(_decoder), _decoder = NULL;
}


- (STWebPStreamingDecoderState)updateWithData:(NSData *)data {
	{
		switch (_state) {
			case STWebPStreamingDecoderStateComplete:
			case STWebPStreamingDecoderStateError:
				return _state;
			case STWebPStreamingDecoderStateIncomplete:
				break;
		}
	}

	if ([data length]) {
		VP8StatusCode status = WebPIAppend(_decoder, data.bytes, data.length);
		switch (status) {
			case VP8_STATUS_OK:
				_state = STWebPStreamingDecoderStateComplete;
				break;
			case VP8_STATUS_SUSPENDED:
				_state = STWebPStreamingDecoderStateIncomplete;
				break;
			case VP8_STATUS_BITSTREAM_ERROR:
			case VP8_STATUS_INVALID_PARAM:
			case VP8_STATUS_NOT_ENOUGH_DATA:
			case VP8_STATUS_OUT_OF_MEMORY:
			case VP8_STATUS_UNSUPPORTED_FEATURE:
			case VP8_STATUS_USER_ABORT:
				_state = STWebPStreamingDecoderStateError;
				break;
		}
	}

	return _state;
}

- (UIImage *)imageWithScale:(CGFloat)scale {
	return [self imageWithScale:scale error:nil];
}
- (UIImage *)imageWithScale:(CGFloat)scale error:(NSError * __autoreleasing *)error {
	switch (_state) {
		case STWebPStreamingDecoderStateError: {
			if (error) {
				*error = [NSError errorWithDomain:STWebPErrorDomain code:STWebPDecodeFailure userInfo:nil];
			}
			return nil;
		}
		case STWebPStreamingDecoderStateIncomplete:
		case STWebPStreamingDecoderStateComplete:
			break;
	}

	int w = 0, h = 0, last_y = 0, stride = 0;
	uint8_t *bitmapDataInternal = WebPIDecGetRGB(_decoder, &last_y, &w, &h, &stride);

	if (!bitmapDataInternal) {
		if (error) {
			*error = [NSError errorWithDomain:STWebPErrorDomain code:STWebPDecodeFailure userInfo:nil];
		}
		return nil;
	}

	CGImageRef bitmap = NULL;
	{
		NSUInteger const bitsPerComponent = 8;
		NSUInteger const bytesPerPixel = 4;
		NSUInteger const bitsPerPixel = bitsPerComponent * bytesPerPixel;

		CGBitmapInfo const bitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaFirst;

		CGColorSpaceRef drgb = CGColorSpaceCreateDeviceRGB();
		if (drgb) {
			uint8_t *bitmapData = calloc(stride, h);
			memcpy(bitmapData, bitmapDataInternal, stride * last_y);

			CGDataProviderRef bitmapDataProvider = CGDataProviderCreateWithData(NULL, bitmapData, (size_t)(stride * h), STCGDataProviderReleaseDataCallbackFree);

			if (bitmapDataProvider) {
				bitmap = CGImageCreate((size_t)w, (size_t)h, bitsPerComponent, bitsPerPixel, stride, drgb, bitmapInfo, bitmapDataProvider, NULL, YES, kCGRenderingIntentDefault);
				CGDataProviderRelease(bitmapDataProvider);
			} else {
				free(bitmapData);
			}

			CGColorSpaceRelease(drgb);
		}
	}
	if (!bitmap) {
		if (error) {
			*error = [NSError errorWithDomain:STWebPErrorDomain code:STWebPDecodeFailure userInfo:nil];
		}
		return nil;
	}

	UIImage *image = [[UIImage alloc] initWithCGImage:bitmap scale:scale orientation:UIImageOrientationUp];
	CFRelease(bitmap);

	return image;
}

@end
