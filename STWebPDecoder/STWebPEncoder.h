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


extern NSString * const STWebPErrorDomain;
enum STWebPErrorCode {
	STWebPDecodeFailure = 1,
};


@interface STWebPEncoder : NSObject

@end

@interface STAnimatedWebPEncoder : NSObject

#if defined(STWEBP_APPKIT) && STWEBP_APPKIT
//- (BOOL)addFrameWithImage:(NSImage *)image
#endif

@end
