//
//  swypInfoRef.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import <Foundation/Foundation.h>
typedef enum{
	swypInfoRefTypeUnknown= 0,
	swypInfoRefTypeSwypIn,
	swypInfoRefTypeSwypOut
}swypInfoRefType;

typedef enum{
	swypScreenEdgeTypeBottom= 0,
	swypScreenEdgeTypeTop,
	swypScreenEdgeTypeLeft,
    swypScreenEdgeTypeRight
}swypScreenEdgeType;

/** This class encapsulates the logical components of the gestures found in swypGestureRecognizer.
	The swypInfoRef is the tracking method for all connections based on gestures. 
 */
@interface swypInfoRef : NSObject {
	double		velocity;
	CGPoint		startPoint;
	CGPoint		endPoint;
	NSDate*		startDate;
	NSDate*		endDate;
	UIView*		swypBeginningContentView;

	swypInfoRefType	swypType;
}
/// in mm/second
@property (nonatomic, assign)	double		velocity;	
@property (nonatomic, assign)	CGPoint		startPoint;
@property (nonatomic, assign)	CGPoint		endPoint;
@property (nonatomic, retain)	NSDate*		startDate;
@property (nonatomic, retain)	NSDate*		endDate;
@property (nonatomic, assign)	swypInfoRefType	swypType;

/// Get the general screen position of a swipe (bottom, top, left, right)
-(swypScreenEdgeType)screenEdgeOfSwyp;

/** property is filled when swyp out occurs on top of displayed content, not filled when swyp begins on workspace */
@property (nonatomic, retain)	UIView*		swypBeginningContentView;



@end
