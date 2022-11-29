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

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
	[super touchesBegan:touches withEvent:event];
	
	[[self swypGestureInfo] setSwypType:swypInfoRefTypeSwypOut];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
	[super touchesMoved:touches withEvent:event];
	
	if ([self distanceFromViewCenterWithPoint:[self locationInView:self.view]] < [self distanceFromViewCenterWithPoint:[[self swypGestureInfo]startPoint]]){
		[[self swypGestureInfo] setStartPoint:[self locationInView:self.view]];
	}
	
	if (self.state == UIGestureRecognizerStatePossible){
		if ([self travelAwayFromCenter] > 50){
			self.state = UIGestureRecognizerStateBegan;
		}else{
			self.state = UIGestureRecognizerStatePossible;
		}
	}else if (self.state == UIGestureRecognizerStateBegan){
		self.state = UIGestureRecognizerStateChanged;	
	}else if (self.state == UIGestureRecognizerStateChanged) {
		self.state = UIGestureRecognizerStateChanged;
	}

	
}

-(BOOL) startedOnEdge{
	
	CGPoint firstPoint						= [[self swypGestureInfo] startPoint];
	
	CGRect	viewRect						= self.view.frame;
	CGRect	edgeBeginSwypOutExclusionRect	= CGRectInset(viewRect, 40, 40);
	if (CGRectContainsPoint(edgeBeginSwypOutExclusionRect, firstPoint) == NO){
		
		return YES;
	}
	
	return NO;
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{	
	[super touchesEnded:touches withEvent:event];
	
	
	CGPoint firstPoint						= [[self swypGestureInfo] startPoint];
	
	CGRect	viewRect						= self.view.frame;

	CGPoint lastPoint			= [[self swypGestureInfo] endPoint];
	CGPoint viewCenterPoint	= self.view.center;
	
	double firstEuclid, lastEuclid, euclidDelta;
	firstEuclid		= euclideanDistance(viewCenterPoint, firstPoint);
	lastEuclid		= euclideanDistance(viewCenterPoint, lastPoint);
	euclidDelta		= lastEuclid - firstEuclid; //positive values move away from the center point
	
		
	CGRect	invalidSwypOutRect	= CGRectInset(viewRect, 30, 30);
	if (CGRectContainsPoint(invalidSwypOutRect, lastPoint) == NO && euclidDelta > 20){
		[[self swypGestureInfo] setEndDate:[NSDate date]];
		[[self swypGestureInfo] setEndPoint:lastPoint];
		double velocity	=		[self velocity];
		[[self swypGestureInfo] setVelocity:velocity]; 	
		self.state = UIGestureRecognizerStateRecognized;
		
		EXOLog(@"SwypOut with velocity:%f",[self velocity]);

//		EXOLog(@"SwypOut: velocity:%f travel:%f euclidDelta:%f startPt:%f,%f endPt:%f,%f startDt:%f endDt:%f", [[self swypGestureInfo] velocity], [self absoluteTravel],euclidDelta, [[self swypGestureInfo] startPoint].x,[[self swypGestureInfo] startPoint].y, [[self swypGestureInfo] endPoint].x,[[self swypGestureInfo] endPoint].y,[[[self swypGestureInfo] startDate] timeIntervalSinceReferenceDate],[[[self swypGestureInfo] endDate] timeIntervalSinceReferenceDate]);
	}else {
		//EXOLog(@"Failed SwypOut: velocity:%f travel:%f euclidDelta:%f startPt:%f,%f endPt:%f,%f startDt:%f endDt:%f", [[self swypGestureInfo] velocity], [self absoluteTravel],euclidDelta, [[self swypGestureInfo] startPoint].x,[[self swypGestureInfo] startPoint].y, [[self swypGestureInfo] endPoint].x,[[self swypGestureInfo] endPoint].y,[[[self swypGestureInfo] startDate] timeIntervalSinceReferenceDate],[[[self swypGestureInfo] endDate] timeIntervalSinceReferenceDate]);

		self.state = UIGestureRecognizerStateCancelled;
	}
}

@end
