//  Copyright (c) 2013 Scott Talbot. All rights reserved.

#import <UIKit/UIKit.h>


extern NSString * const STWebPErrorDomain;
enum STWebPErrorCode {
	STWebPDecodeFailure = 1,
};


@interface STWebPDecoder : NSObject

+ (UIImage *)imageWithData:(NSData *)data error:(NSError * __autoreleasing *)error;
+ (UIImage *)imageWithData:(NSData *)data scale:(CGFloat)scale error:(NSError * __autoreleasing *)error;

@end
