//  Copyright (c) 2013 Scott Talbot. All rights reserved.

#import "STWebPDecoder.h"

#import "lib/libwebp/src/webp/decode.h"


NSString * const STWebPErrorDomain = @"STWebP";


static void STCGDataProviderReleaseDataCallbackFree(void *info, const void *data, size_t size);


@implementation STWebPDecoder

+ (NSImage *)imageWithData:(NSData *)data error:(NSError * __autoreleasing *)error {
	return [self imageWithData:data scale:1 error:error];
}

+ (NSImage *)imageWithData:(NSData *)data scale:(CGFloat)scale error:(NSError * __autoreleasing *)error {
	int w = 0, h = 0;
	uint8_t *bitmapData = WebPDecodeBGRA(data.bytes, data.length, &w, &h);
	if (!bitmapData) {
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
		NSUInteger const stride = (NSUInteger)w * bytesPerPixel;

		CGBitmapInfo const bitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaFirst;

		CGColorSpaceRef drgb = CGColorSpaceCreateDeviceRGB();
		if (drgb) {
			CGDataProviderRef bitmapDataProvider = CGDataProviderCreateWithData(NULL, bitmapData, (size_t)(w * h * bytesPerPixel), STCGDataProviderReleaseDataCallbackFree);

			if (bitmapDataProvider) {
				bitmap = CGImageCreate((size_t)w, (size_t)h, bitsPerComponent, bitsPerPixel, stride, drgb, bitmapInfo, bitmapDataProvider, NULL, YES, kCGRenderingIntentDefault);
				CGDataProviderRelease(bitmapDataProvider);
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

	if (scale == 0) {
		scale = 1;
	}
	NSSize const imageSize = (NSSize){ .width = w / scale, .height = h / scale };

	NSImage *image = [[NSImage alloc] initWithCGImage:bitmap size:imageSize];
	CFRelease(bitmap);

	return image;
}

@end


static void STCGDataProviderReleaseDataCallbackFree(void *info, const void *data, size_t size) {
	free((void *)data);
}
