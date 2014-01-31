//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2014 Scott Talbot.

#import "STWebPImage.h"


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

- (UIImage *)UIImage {
	return [self UIImageForFrameAtIndex:0 scale:1];
}
- (UIImage *)UIImageWithScale:(CGFloat)scale {
	return [self UIImageForFrameAtIndex:0 scale:scale];
}
- (UIImage *)UIImageForFrameAtIndex:(NSUInteger)frame {
	return [self UIImageForFrameAtIndex:frame scale:1];
}
- (UIImage *)UIImageForFrameAtIndex:(NSUInteger)frame scale:(CGFloat)scale {
	if (frame >= _images.count) {
		return nil;
	}

	CGImageRef const cgimage = (__bridge CGImageRef)(_images[frame]);
	return [[UIImage alloc] initWithCGImage:cgimage scale:scale orientation:UIImageOrientationUp];
}

- (UIImage *)animatedUIImage {
	return [self animatedUIImageWithScale:1];
}
- (UIImage *)animatedUIImageWithScale:(CGFloat)scale {
	NSTimeInterval duration = 0;
	for (NSNumber *frameDuration in _durations) {
		duration += frameDuration.doubleValue;
	}
	NSMutableArray * const images = [[NSMutableArray alloc] initWithCapacity:_images.count];
	for (NSUInteger i = 0; i < _images.count; ++i) {
		CGImageRef const cgimage = (__bridge CGImageRef)(_images[i]);
		UIImage * const image = [[UIImage alloc] initWithCGImage:cgimage scale:scale orientation:UIImageOrientationUp];
		[images addObject:image];
	}

	return [UIImage animatedImageWithImages:images duration:duration];
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
