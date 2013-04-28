//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2013 Scott Talbot.

#if __has_include(<UIKit/UIKit.h>)
# import <UIKit/UIKit.h>
# define STWEBP_UIKIT 1
#elif __has_include(<AppKit/AppKit.h>)
# import <AppKit/AppKit.h>
# define STWEBP_APPKIT 1
#else
# error "Unsupported platform"
#endif


extern NSString * const STWebPErrorDomain;
enum STWebPErrorCode {
	STWebPDecodeFailure = 1,
};


@interface STWebPDecoder : NSObject

#if defined(STWEBP_UIKIT) && STWEBP_UIKIT
+ (UIImage *)imageWithData:(NSData *)data error:(NSError * __autoreleasing *)error;
+ (UIImage *)imageWithData:(NSData *)data scale:(CGFloat)scale error:(NSError * __autoreleasing *)error;
#endif

#if defined(STWEBP_APPKIT) && STWEBP_APPKIT
+ (NSImage *)imageWithData:(NSData *)data error:(NSError * __autoreleasing *)error;
+ (NSImage *)imageWithData:(NSData *)data scale:(CGFloat)scale error:(NSError * __autoreleasing *)error;
#endif

@end
