//
//  swypGestureRecognizer.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import "swypGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>



@implementation swypGestureRecognizer

+(double)currentDevicePixelsPerLinearMillimeter{
	if (deviceIsPad){
		return 5.1975;
	}else if (deviceIsPhone_ish) {
		return 6.299; //iPhone 4 pretends to have same resolution as others
	}

	return 0;
}

-(swypInfoRef*)	swypGestureInfo{
	return _recognizedGestureInfoRef;
}

- (void)reset{
	SRELS(_trackedTouch);
	
	SRELS(_recognizedGestureInfoRef);

	[super reset];
}

- (double)velocity{
	double velocity		= [self absoluteTravel] / [[NSDate date] timeIntervalSinceDate:[[self swypGestureInfo] startDate]] / [swypGestureRecognizer currentDevicePixelsPerLinearMillimeter];
	return velocity;
}

- (double)absoluteTravel{
	CGPoint firstPoint			= [[self swypGestureInfo] startPoint];
	CGPoint currentPoint		= [self locationInView:self.view];
	return	euclideanDistance(currentPoint, firstPoint);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{	
	[super touchesBegan:touches withEvent:event];
	NSMutableSet * relevantTouches = [NSMutableSet set];
	for (UITouch * touch in touches){
		//we'll try allowing all touches for the case of supporting content swyps
//		if ([touch view] != [self view]){
//			[self ignoreTouch:touch forEvent:event];
//		}else{
			[relevantTouches addObject:touch];
//		}
	}
	
	if ([[NSDate date] timeIntervalSinceDate:[[self swypGestureInfo] startDate]] > 3){
		SRELS(_trackedTouch); //sometimes touches get caught somewhere (ask Steve)
	}
	
	if (_trackedTouch == nil){
		_trackedTouch = [[relevantTouches anyObject] retain];
	
		self.state = UIGestureRecognizerStatePossible;
		
		if (_recognizedGestureInfoRef == nil){
			_recognizedGestureInfoRef = [[swypInfoRef alloc] init];
		}
		[_recognizedGestureInfoRef setStartDate:[NSDate date]];
		[_recognizedGestureInfoRef setStartPoint:[self locationInView:self.view]];		
	}
	
	for (UITouch * touch in relevantTouches){
		if (touch != _trackedTouch){
			[self ignoreTouch:touch forEvent:event];
		}
	}
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
	[super touchesMoved:touches withEvent:event];
	
	self.state = UIGestureRecognizerStatePossible; //don't let it set recognized until you're ready
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{	
	
	[_recognizedGestureInfoRef setEndDate:[NSDate date]];
	[_recognizedGestureInfoRef setEndPoint:[self locationInView:self.view]];
	
	[super touchesEnded:touches withEvent:event];
}

-(void) dealloc{
	SRELS(_recognizedGestureInfoRef);
	
	[super dealloc];
}

@end

