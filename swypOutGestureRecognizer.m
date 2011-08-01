//
//  swypOutGestureRecognizer.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import "swypOutGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation swypOutGestureRecognizer

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{	
	[super touchesEnded:touches withEvent:event];
	
	
	CGPoint firstPoint			= [[self swypGestureInfo] startPoint];
	CGPoint lastPoint			= [[self swypGestureInfo] endPoint];
	CGPoint viewCenterPoint	= self.view.center;
	
	double firstEuclid, lastEuclid, euclidDelta;
	firstEuclid		= euclideanDistance(viewCenterPoint, firstPoint);
	lastEuclid		= euclideanDistance(viewCenterPoint, lastPoint);
	euclidDelta		= lastEuclid - firstEuclid; //positive values move away from the center point
	
	
	CGRect	viewRect			= self.view.frame;
	CGRect	invalidSwypOutRect	= CGRectInset(viewRect, 30, 30);
	if (CGRectContainsPoint(invalidSwypOutRect, lastPoint) == NO && euclidDelta > 20){
		[[self swypGestureInfo] setEndDate:[NSDate date]];
		[[self swypGestureInfo] setEndPoint:lastPoint];
		double velocity	=	 euclideanDistance([self velocityInView:self.view], CGPointZero)/[swypGestureRecognizer currentDevicePixelsPerLinearMillimeter];
		[[self swypGestureInfo] setVelocity:velocity]; 	
		self.state = UIGestureRecognizerStateRecognized;
		
		EXOLog(@"SwypOut: velocity:%f euclidDelta:%f startPt:%f,%f endPt:%f,%f startDt:%f endDt:%f", [[self swypGestureInfo] velocity],euclidDelta, [[self swypGestureInfo] startPoint].x,[[self swypGestureInfo] startPoint].y, [[self swypGestureInfo] endPoint].x,[[self swypGestureInfo] endPoint].y,[[[self swypGestureInfo] startDate] timeIntervalSinceReferenceDate],[[[self swypGestureInfo] endDate] timeIntervalSinceReferenceDate]);
	}else {
		self.state = UIGestureRecognizerStateFailed;
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
	
	if (euclidDelta < -10){
		self.state = UIGestureRecognizerStateFailed;
	}else{
		self.state = UIGestureRecognizerStatePossible;
	}
	
}
@end
