//  Copyright (c) 2013 Scott Talbot. All rights reserved.

#import "STAppDelegate.h"
#import "STWebPDecoder.h"


@implementation STAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification * __unused)aNotification {
	NSString * const webpPath = [[NSBundle mainBundle] pathForResource:@"garden-pruner-transparent" ofType:@"webp"];
	NSData * const webpData = [[NSData alloc] initWithContentsOfFile:webpPath options:NSDataReadingMappedIfSafe error:NULL];
	STWebPImage * const image = [STWebPDecoder imageWithData:webpData error:NULL];
	[self.imageView setWantsLayer:YES];
	self.imageView.image = [image NSImageWithScale:1];
	[self.imageView.layer addAnimation:image.CAKeyframeAnimation forKey:@"contents"];
}

@end
