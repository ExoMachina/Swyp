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
}
@property (nonatomic, assign)	double		velocity;	//in mm/second
@property (nonatomic, assign)	CGPoint		startPoint;
@property (nonatomic, assign)	CGPoint		endPoint;
@property (nonatomic, retain)	NSDate*		startDate;
@property (nonatomic, retain)	NSDate*		endDate;

@end
