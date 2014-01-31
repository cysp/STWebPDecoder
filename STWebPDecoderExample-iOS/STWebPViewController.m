//  Copyright (c) 2013 Scott Talbot. All rights reserved.

#import "STWebPViewController.h"

#import "STWebPImage.h"
#import "STWebPDecoder.h"

#include <mach/mach_time.h>


static CGFloat const XIncrementR = FLT_EPSILON * 20000;
static CGFloat const XIncrementG = FLT_EPSILON * 30000;
static CGFloat const XIncrementB = FLT_EPSILON * 70000;


@interface STWebPViewController ()
@property (nonatomic,weak) UIImageView *imageView;
@end

@implementation STWebPViewController {
@private
	CADisplayLink *_displayLink;
	CGFloat _backgroundR;
	CGFloat _backgroundG;
	CGFloat _backgroundB;
}

+ (instancetype)viewController {
	return [[self alloc] initWithNibName:nil bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkFired)];
		_displayLink.paused = YES;
		[_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
	}
	return self;
}

- (void)dealloc {
	[_displayLink invalidate];
}

- (void)displayLinkFired {
	double x;
	_backgroundR = (CGFloat)modf(_backgroundR + XIncrementR, &x);
	_backgroundG = (CGFloat)modf(_backgroundG + XIncrementG, &x);
	_backgroundB = (CGFloat)modf(_backgroundB + XIncrementB, &x);

	UIColor * const backgroundColor = [UIColor colorWithRed:_backgroundR green:_backgroundG blue:_backgroundB alpha:1];
	self.view.backgroundColor = backgroundColor;
}


- (void)loadView {
	self.view = [[UIView alloc] initWithFrame:(CGRect){ .size = { .width = 768, .height = 968 } }];
	UIView * const view = self.view;
	view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	view.backgroundColor = [UIColor whiteColor];

	UIImageView * const imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
	imageView.contentMode = UIViewContentModeCenter;
	[view addSubview:imageView];
	self.imageView = imageView;
}


- (void)viewDidLoad {
	[super viewDidLoad];

	mach_timebase_info_data_t timebaseInfo = { };
	(void)mach_timebase_info(&timebaseInfo);

//	@autoreleasepool {
//		uint64_t const start = mach_absolute_time();
//
//		for (int i = 0; i < 100; ++i) @autoreleasepool {
//			NSString * const webpPath = [[NSBundle mainBundle] pathForResource:@"4" ofType:@"webp"];
//			NSData * const webpData = [NSData dataWithContentsOfFile:webpPath options:NSDataReadingMappedIfSafe error:NULL];
//
//			int bitmapWidth = 0, bitmapHeight = 0;
//			uint8_t *bitmapData = WebPDecodeBGRA(webpData.bytes, webpData.length, &bitmapWidth, &bitmapHeight);
//			if (!bitmapData) {
//				return;
//			}
//
//			CGDataProviderRef bitmapDataProvider = CGDataProviderCreateWithData(NULL, bitmapData, bitmapWidth * bitmapHeight, CGDataProviderReleaseDataCallbackFree);
//
//			CGColorSpaceRef drgb = CGColorSpaceCreateDeviceRGB();
//			CGBitmapInfo const bitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaFirst;
//			CGImageRef bitmap = CGImageCreate(bitmapWidth, bitmapHeight, 8, 32, bitmapWidth*4, drgb, bitmapInfo, bitmapDataProvider, NULL, YES, kCGRenderingIntentDefault);
//			CFRelease(drgb);
//
//			UIImage *image = [[UIImage alloc] initWithCGImage:bitmap scale:1 orientation:UIImageOrientationUp];
//			CFRelease(bitmap);
//			(void)image;
//		}
//		uint64_t const end = mach_absolute_time();
//		NSLog(@"webp elapsed:  %lluns", ((end - start) * timebaseInfo.numer / timebaseInfo.denom) / 100);
//	}

//	@autoreleasepool {
//		uint64_t const start = mach_absolute_time();
//
//		NSString * const webpPath = [[NSBundle mainBundle] pathForResource:@"4" ofType:@"webp"];
//		NSData * const webpData = [[NSData alloc] initWithContentsOfFile:webpPath options:NSDataReadingMappedIfSafe error:NULL];
//
//		for (int i = 0; i < 100; ++i) @autoreleasepool {
//
//			UIImage * const image = [STWebPDecoder imageWithData:webpData scale:1 error:NULL];
//			(void)image;
//		}
//		uint64_t const end = mach_absolute_time();
//		NSLog(@"webp elapsed:  %lluns", ((end - start) * timebaseInfo.numer / timebaseInfo.denom) / 100);
//	}
//
//
//	@autoreleasepool {
//		uint64_t const start = mach_absolute_time();
//		for (int i = 0; i < 100; ++i) @autoreleasepool {
//			NSString * const inputPath = [[NSBundle mainBundle] pathForResource:@"4" ofType:@"jpg"];
//			NSData * const inputData = [NSData dataWithContentsOfFile:inputPath options:NSDataReadingMappedIfSafe error:NULL];
//
//			CGDataProviderRef bitmapDataProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef)inputData);
//
//			CGImageRef bitmap = CGImageCreateWithJPEGDataProvider(bitmapDataProvider, NULL, YES, kCGRenderingIntentDefault);
//
//			UIImage *image = [[UIImage alloc] initWithCGImage:bitmap scale:1 orientation:UIImageOrientationUp];
//			CFRelease(bitmap);
//			CGDataProviderRelease(bitmapDataProvider);
//			(void)image;
//		}
//		uint64_t const end = mach_absolute_time();
//		NSLog(@"jpeg elapsed:  %lluns", ((end - start) * timebaseInfo.numer / timebaseInfo.denom) / 100);
//	}
//
//	@autoreleasepool {
//		uint64_t const start = mach_absolute_time();
//		for (int i = 0; i < 100; ++i) @autoreleasepool {
//			NSString * const webpPath = [[NSBundle mainBundle] pathForResource:@"4" ofType:@"jpg"];
//			UIImage *image = [[UIImage alloc] initWithContentsOfFile:webpPath];
//			(void)image;
//		}
//		uint64_t const end = mach_absolute_time();
//		NSLog(@"jpegi elapsed: %lluns", ((end - start) * timebaseInfo.numer / timebaseInfo.denom) / 100);
//	}

	NSString * const webpPath = [[NSBundle mainBundle] pathForResource:@"garden-pruner-transparent" ofType:@"webp"];
	NSError *error = nil;
	NSData * const webpData = [[NSData alloc] initWithContentsOfFile:webpPath options:NSDataReadingMappedIfSafe error:&error];
	STWebPImage * const image = [STWebPDecoder imageWithData:webpData error:&error];
	UIImageView * const imageView = self.imageView;
	if (1) {
		[imageView.layer addAnimation:image.CAKeyframeAnimation forKey:@"contents"];
	} else {
		imageView.image = [image animatedUIImage];
	}
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	_displayLink.paused = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	_displayLink.paused = YES;
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];

	UIView * const view = self.view;
	CGRect const bounds = view.bounds;
	CGSize const boundsSize = bounds.size;

	UIImageView * const imageView = self.imageView;
	UIImage * const imageViewImage = imageView.image;
	CGSize const imageViewImageSize = imageViewImage ? imageViewImage.size : (CGSize){ 0, 0 };

	CGRect const imageViewFrame = (CGRect){
		.origin = {
			.x = (boundsSize.width - imageViewImageSize.width) / 2,
			.y = (boundsSize.height - imageViewImageSize.height) / 2,
		},
		.size = imageViewImageSize,
	};

	imageView.frame = imageViewFrame;
}

@end
