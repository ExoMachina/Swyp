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
	
	CGPoint lastPoint			= [[self swypGestureInfo] endPoint];
	CGRect	viewRect			= self.view.frame;
	CGRect	validSwypOutRect	= CGRectInset(viewRect, 30, 30);
	if (CGRectContainsPoint(validSwypOutRect, lastPoint) == YES){
		[[self swypGestureInfo] setEndDate:[NSDate date]];
		[[self swypGestureInfo] setEndPoint:lastPoint];
		[[self swypGestureInfo] setVelocity: euclideanDistance([self velocityInView:self.view], CGPointZero)]; //pythag		
		self.state = UIGestureRecognizerStateRecognized;
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
	}else if (euclidDelta > 10){
		if (self.state == UIGestureRecognizerStateBegan){
			self.state = UIGestureRecognizerStateChanged;
		}else if (self.state == UIGestureRecognizerStateChanged) {
			self.state = UIGestureRecognizerStateChanged;
		}else if (self.state == UIGestureRecognizerStatePossible) {
			self.state = UIGestureRecognizerStateBegan;			
		}
	}else{
		self.state = UIGestureRecognizerStatePossible;
	}
	
}
@end
