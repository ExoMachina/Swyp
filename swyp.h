/*
 *  swyp.h
 *  swyp
 *
 *  Created by Alexander List on 7/28/11.
 *	Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
 *
 */


#define DEBUG_MODE_ENABLED 1

//	Developer conviniences
#define SRELS RELEASE_SAFELY
#define RELEASE_SAFELY(__POINTER) { [__POINTER release]; __POINTER = nil; }

#define deviceIsPad ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
#define ArrayHasItems(array) (array != nil && [array count] > 0)
#define StringHasText(string) (string != nil && [string length] > 0)
#define SetHasItems(set) (set != nil && [set count] > 0)

#define euclideanDistance(pointOne, pointTwo) sqrt(pow((pointOne.x - pointTwo.x),2) + pow((pointOne.y - pointTwo.y),2))

#if DEBUG_MODE_ENABLED == 1
#if CONFIGURATION == Debug
	#define EXOLog NSLog
	#else
		#error verbose outputs of EXOLog -- DEBUG_MODE_ENABLED = 1 for non-debug build
	#endif
#else
	#define EXOLog(format, ...)
#endif


#pragma mark includes
#import "NSDictionary+BSJSONAdditions.h"