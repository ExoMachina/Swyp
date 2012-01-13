//
//  swypGestureRecognizer.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import <Foundation/Foundation.h>
#import "swypInfoRef.h"


/** This class and its subclasses handle the actual detection of swyp gestures on UIViews.
	
	This class acts as a typical touch recognizer, and as such is not a permenent representation of a gesture-- see swypInfoRef for that. 
 */
@interface swypGestureRecognizer : UIGestureRecognizer {
	swypInfoRef *	_recognizedGestureInfoRef;
	
	UITouch *		_trackedTouch;
}
/** The permenent representation of the current gesture.
 
  @warning This value is reset with gesture recognizer.
 
 */
-(swypInfoRef*)	swypGestureInfo; 

/** This is the velocity of a finger of the screen in mm/sec */
-(double)	velocity;
-(double)	absoluteTravel;
+(double)	currentDevicePixelsPerLinearMillimeter;

@end
