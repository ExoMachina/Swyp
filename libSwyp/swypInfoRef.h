//
//  swypInfoRef.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import <Foundation/Foundation.h>


@interface swypInfoRef : NSObject {
	double		velocity;
	CGPoint		startPoint;
	CGPoint		endPoint;
	NSDate*		startDate;
	NSDate*		endDate;
	UIView*		swypBeginningContentView;
}
@property (nonatomic, assign)	double		velocity;	//in mm/second
@property (nonatomic, assign)	CGPoint		startPoint;
@property (nonatomic, assign)	CGPoint		endPoint;
@property (nonatomic, retain)	NSDate*		startDate;
@property (nonatomic, retain)	NSDate*		endDate;

//property is filled when swyp out occurs on top of this content, not on workspace
@property (nonatomic, retain)	UIView*		swypBeginningContentView;

@end
