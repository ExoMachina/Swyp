//
//  swypInGestureRecognizer.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import "swypInGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation swypInGestureRecognizer

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{	
	[super touchesBegan:touches withEvent:event];
	
	CGPoint firstPoint			= [[self swypGestureInfo] startPoint];
	CGRect	viewRect			= self.view.frame;
	CGRect	invalidSwypInRect	= CGRectInset(viewRect, 40, 40);
	if (CGRectContainsPoint(invalidSwypInRect, firstPoint) == YES){
		self.state = UIGestureRecognizerStateFailed;
	}else {
		self.state = UIGestureRecognizerStatePossible;
	}

}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
	[super touchesMoved:touches withEvent:event];
	
	CGPoint firstPoint			= [[self swypGestureInfo] startPoint];
		
	CGPoint viewCenterPoint	= self.view.center;
	CGPoint currentPoint	= CGPointApplyAffineTransform(firstPoint, CGAffineTransformMakeTranslation([self translationInView:self.view].x, [self translationInView:self.view].x));
	
	double firstEuclid, currentEuclid, euclidDelta;
	firstEuclid		= euclideanDistance(viewCenterPoint, firstPoint);
	currentEuclid	= euclideanDistance(viewCenterPoint, currentPoint);
	euclidDelta		= currentEuclid - firstEuclid; //positive values move away from the center point
	
	if (euclidDelta > 10){
		self.state = UIGestureRecognizerStateFailed;
	}else if (euclidDelta < -40){
		[[self swypGestureInfo] setEndDate:[NSDate date]];
		[[self swypGestureInfo] setEndPoint:currentPoint];
		[[self swypGestureInfo] setVelocity: euclideanDistance([self velocityInView:self.view], CGPointZero)]; //pythag
		self.state = UIGestureRecognizerStateRecognized;
		
		EXOLog(@"SwypIN: velocity:%f startPt:%f,%f endPt:%f,%f startDt:%f endDt:%f", [[self swypGestureInfo] velocity],[[self swypGestureInfo] startPoint].x,[[self swypGestureInfo] startPoint].y, [[self swypGestureInfo] endPoint].x,[[self swypGestureInfo] endPoint].y,[[[self swypGestureInfo] startDate] timeIntervalSinceReferenceDate],[[[self swypGestureInfo] endDate] timeIntervalSinceReferenceDate]);
	}else {
		self.state = UIGestureRecognizerStatePossible;
	}

}

@end
