//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2014 Scott Talbot.

#import "STWebPDecoder.h"


@implementation STWebPImage {
@private
	NSArray *_images;
	NSArray *_durations;
}

- (id)initWithCGImages:(NSArray *)images durations:(NSArray *)durations {
	if ((self = [super init])) {
		_images = [[NSArray alloc] initWithArray:images];
		_durations = [[NSArray alloc] initWithArray:durations];
	}
	return self;
}

- (NSImage *)NSImage {
	return [self NSImageForFrameAtIndex:0 scale:1];
}
- (NSImage *)NSImageWithScale:(CGFloat)scale {
	return [self NSImageForFrameAtIndex:0 scale:scale];
}
- (NSImage *)NSImageForFrameAtIndex:(NSUInteger)frame {
	return [self NSImageForFrameAtIndex:frame scale:1];
}
- (NSImage *)NSImageForFrameAtIndex:(NSUInteger)frame scale:(CGFloat)scale {
	if (frame >= _images.count) {
		return nil;
	}

	CGImageRef const cgimage = (__bridge CGImageRef)(_images[frame]);
	if (scale == 0) {
		scale = 1;
	}
	CGFloat const w = CGImageGetWidth(cgimage);
	CGFloat const h = CGImageGetHeight(cgimage);
	NSSize const imageSize = (NSSize){ .width = w / scale, .height = h / scale };

	return [[NSImage alloc] initWithCGImage:cgimage size:imageSize];
}

- (CAKeyframeAnimation *)CAKeyframeAnimation {
	NSTimeInterval duration = 0;
	for (NSNumber *frameDuration in _durations) {
		duration += frameDuration.doubleValue;
	}
	NSMutableArray * const keyTimes = [[NSMutableArray alloc] initWithCapacity:_images.count];
	NSTimeInterval durationAccumulator = 0;
	for (NSNumber *frameDuration in _durations) {
		NSTimeInterval const frameDurationFraction = frameDuration.doubleValue / duration;
		[keyTimes addObject:@(durationAccumulator)];
		durationAccumulator += frameDurationFraction;
	}

	CAKeyframeAnimation * const animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
	animation.calculationMode = kCAAnimationDiscrete;
	animation.removedOnCompletion = NO;
	animation.repeatCount = HUGE_VALF;
	animation.duration = duration;
	animation.keyTimes = keyTimes;
	animation.values = _images;
	return animation;
}

@end
