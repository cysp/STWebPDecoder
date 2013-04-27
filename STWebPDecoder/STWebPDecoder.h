//  Copyright (c) 2013 Scott Talbot. All rights reserved.

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
