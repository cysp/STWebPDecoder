//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2013-2014 Scott Talbot.

#if __has_include(<UIKit/UIKit.h>)
# import <UIKit/UIKit.h>
# define STWEBP_UIKIT 1
#elif __has_include(<AppKit/AppKit.h>)
# import <AppKit/AppKit.h>
# define STWEBP_APPKIT 1
#else
# error "Unsupported platform"
#endif

#import <QuartzCore/QuartzCore.h>


typedef NS_ENUM(NSUInteger, STWebPStreamingDecoderState) {
	STWebPStreamingDecoderStateIncomplete = 0,
	STWebPStreamingDecoderStateComplete,
	STWebPStreamingDecoderStateError,
};

@interface STWebPStreamingDecoder : NSObject

+ (instancetype)decoderWithData:(NSData *)data;
- (id)initWithData:(NSData *)data;

- (STWebPStreamingDecoderState)updateWithData:(NSData *)data;

@property (nonatomic,assign,readonly) STWebPStreamingDecoderState state;

#if defined(STWEBP_UIKIT) && STWEBP_UIKIT
- (UIImage *)imageWithScale:(CGFloat)scale;
- (UIImage *)imageWithScale:(CGFloat)scale error:(NSError * __autoreleasing *)error;
#endif

#if defined(STWEBP_APPKIT) && STWEBP_APPKIT
- (NSImage *)imageWithScale:(CGFloat)scale;
- (NSImage *)imageWithScale:(CGFloat)scale error:(NSError * __autoreleasing *)error;
#endif

@end
