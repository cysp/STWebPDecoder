//  Copyright (c) 2014 Scott Talbot. All rights reserved.

#import <XCTest/XCTest.h>

#import <UIKit/UIKit.h>

#import "STWebPDecoder.h"


@interface STWebPDecoderTests : XCTestCase
@end

@implementation STWebPDecoderTests {
@private
    NSData *_gridImageData;
    NSData *_peakImageData;
}

- (NSData *)st_bitmapDataForImage:(UIImage *)image {
    CGSize const imageSize = image.size;
    CGFloat const imageScale = image.scale;
    CGSize const ctxSize = (CGSize){ .width = imageSize.width * imageScale, .height = imageSize.height * imageScale };
    NSUInteger const bitsPerComponent = 8;
    NSUInteger const bytesPerPixel = 4;
    NSUInteger const stride = (NSUInteger)ctxSize.width * bytesPerPixel;

    CGBitmapInfo const bitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst;

    CGColorSpaceRef const drgb = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(NULL, (size_t)ctxSize.width, (size_t)ctxSize.height, bitsPerComponent, stride, drgb, bitmapInfo);
    CGColorSpaceRelease(drgb);
    CGContextDrawImage(ctx, (CGRect){ .size = ctxSize }, image.CGImage);
    NSData * const imageData = [[NSData alloc] initWithBytes:CGBitmapContextGetData(ctx) length:(NSUInteger)(stride*ctxSize.height)];

    CGContextRelease(ctx);

    return imageData;
}

- (void)setUp {
    [super setUp];

    NSBundle * const bundle = [NSBundle bundleForClass:self.class];
    {
        NSURL * const gridPNGURL = [bundle URLForResource:@"grid" withExtension:@"png" subdirectory:@"libwebp-test-data"];
        UIImage * const gridImage = [[UIImage alloc] initWithContentsOfFile:gridPNGURL.path];
        _gridImageData = [self st_bitmapDataForImage:gridImage];
    }
    {
        NSURL * const peakPNGURL = [bundle URLForResource:@"peak" withExtension:@"png" subdirectory:@"libwebp-test-data"];
        UIImage * const peakImage = [[UIImage alloc] initWithContentsOfFile:peakPNGURL.path];
        _peakImageData = [self st_bitmapDataForImage:peakImage];
    }
}

- (BOOL)st_checkLosslessVec1Image:(UIImage *)image {
    NSData * const imageBitmapData = [self st_bitmapDataForImage:image];
    return [_gridImageData isEqualToData:imageBitmapData];
}

- (BOOL)st_testLosslessVec1:(NSUInteger)number {
    NSString * const filename = [NSString stringWithFormat:@"lossless_vec_1_%lu", (unsigned long)number];
    NSBundle * const bundle = [NSBundle bundleForClass:self.class];
    NSURL * const url = [bundle URLForResource:filename withExtension:@"webp" subdirectory:@"libwebp-test-data"];
    NSData * const data = [[NSData alloc] initWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:NULL];
    UIImage * const image = [STWebPDecoder imageWithData:data error:NULL];
    return [self st_checkLosslessVec1Image:image];
}

- (void)testLosslessVec1 {
    XCTAssert([self st_testLosslessVec1:0], @"");
    XCTAssert([self st_testLosslessVec1:1], @"");
    XCTAssert([self st_testLosslessVec1:2], @"");
    XCTAssert([self st_testLosslessVec1:3], @"");
    XCTAssert([self st_testLosslessVec1:4], @"");
    XCTAssert([self st_testLosslessVec1:5], @"");
    XCTAssert([self st_testLosslessVec1:6], @"");
    XCTAssert([self st_testLosslessVec1:7], @"");
    XCTAssert([self st_testLosslessVec1:8], @"");
    XCTAssert([self st_testLosslessVec1:9], @"");
    XCTAssert([self st_testLosslessVec1:10], @"");
    XCTAssert([self st_testLosslessVec1:11], @"");
    XCTAssert([self st_testLosslessVec1:12], @"");
    XCTAssert([self st_testLosslessVec1:13], @"");
    XCTAssert([self st_testLosslessVec1:14], @"");
    XCTAssert([self st_testLosslessVec1:15], @"");
}
//
//- (BOOL)st_checkLosslessVec2Image:(NSImage *)image {
//    NSBitmapImageRep *imageBitmapRep = nil;
//    for (NSImageRep *rep in image.representations) {
//        if ([rep isKindOfClass:[NSBitmapImageRep class]]) {
//            imageBitmapRep = (NSBitmapImageRep *)rep;
//            break;
//        }
//    }
//    if (!imageBitmapRep) {
//        imageBitmapRep = [NSBitmapImageRep imageRepWithData:image.TIFFRepresentation];
//    }
//    NSData * const imageBitmapData = [[NSData alloc] initWithBytesNoCopy:imageBitmapRep.bitmapData length:imageBitmapRep.bytesPerPlane freeWhenDone:NO];
//    return [_peakImageData isEqualToData:imageBitmapData];
//}
//
//- (BOOL)st_testLosslessVec2:(NSUInteger)number {
//    NSString * const filename = [NSString stringWithFormat:@"lossless_vec_2_%lu", (unsigned long)number];
//    NSBundle * const bundle = [NSBundle bundleForClass:self.class];
//    NSURL * const url = [bundle URLForResource:filename withExtension:@"webp" subdirectory:@"libwebp-test-data"];
//    NSData * const data = [[NSData alloc] initWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:NULL];
//    NSImage * const image = [STWebPDecoder imageWithData:data error:NULL];
//    return [self st_checkLosslessVec2Image:image];
//}
//
//- (void)testLosslessVec2 {
//    XCTAssert([self st_testLosslessVec2:0], @"");
//    XCTAssert([self st_testLosslessVec2:1], @"");
//    XCTAssert([self st_testLosslessVec2:2], @"");
//    XCTAssert([self st_testLosslessVec2:3], @"");
//    XCTAssert([self st_testLosslessVec2:4], @"");
//    XCTAssert([self st_testLosslessVec2:5], @"");
//    XCTAssert([self st_testLosslessVec2:6], @"");
//    XCTAssert([self st_testLosslessVec2:7], @"");
//    XCTAssert([self st_testLosslessVec2:8], @"");
//    XCTAssert([self st_testLosslessVec2:9], @"");
//    XCTAssert([self st_testLosslessVec2:10], @"");
//    XCTAssert([self st_testLosslessVec2:11], @"");
//    XCTAssert([self st_testLosslessVec2:12], @"");
//    XCTAssert([self st_testLosslessVec2:13], @"");
//    XCTAssert([self st_testLosslessVec2:14], @"");
//    XCTAssert([self st_testLosslessVec2:15], @"");
//}

@end
