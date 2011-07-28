//
//  swypGestureRecognizer.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import <Foundation/Foundation.h>
#import "swypInfoRef.h"

@interface swypGestureRecognizer : UIPanGestureRecognizer {
	swypInfoRef *	_recognizedGestureInfoRef;
}
-(swypInfoRef)	swypGestureInfo; //reset with gesture recognizer

@end
