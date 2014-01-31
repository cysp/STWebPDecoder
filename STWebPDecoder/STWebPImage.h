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


@interface STWebPImage : NSObject

@property (nonatomic,assign,readonly) NSUInteger numberOfFrames;
@property (nonatomic,strong,readonly) CAKeyframeAnimation *CAKeyframeAnimation;

#if defined(STWEBP_UIKIT) && STWEBP_UIKIT
@property (nonatomic,strong,readonly) UIImage *UIImage;
- (UIImage *)UIImageWithScale:(CGFloat)scale;
- (UIImage *)UIImageForFrameAtIndex:(NSUInteger)frame;
- (UIImage *)UIImageForFrameAtIndex:(NSUInteger)frame scale:(CGFloat)scale;
@property (nonatomic,strong,readonly) UIImage *animatedUIImage;
- (UIImage *)animatedUIImageWithScale:(CGFloat)scale;
#endif

#if defined(STWEBP_APPKIT) && STWEBP_APPKIT
@property (nonatomic,strong,readonly) NSImage *NSImage;
- (NSImage *)NSImageWithScale:(CGFloat)scale;
- (NSImage *)NSImageForFrameAtIndex:(NSUInteger)frame;
- (NSImage *)NSImageForFrameAtIndex:(NSUInteger)frame scale:(CGFloat)scale;
#endif

@end
