#pragma mark IMPORTANT USAGE NOTICE
//	#IMPORTANT
//	This is a pre-release build that WILL NOT COOPERATE with the final release of SWYP
//	AS SUCH, you may NOT EVER use this code under the moniker "swyp" nor "swipe;" see the 'LICENSE' file. kthx have fun!
/*
 *  swyp.h
 *  swyp
 *
 *  Created by Alexander List on 7/28/11.
 *	Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
 *
 */


//see libSwyp.h for how-to


#define DEBUG_MODE_ENABLED 1

//	Developer conviniences
#define SRELS RELEASE_SAFELY
#define RELEASE_SAFELY(__POINTER) { [__POINTER release]; __POINTER = nil; }

#define deviceIsPad ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
#define deviceIsPhone_ish ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
#define ArrayHasItems(array) (array != nil && [array count] > 0)
#define StringHasText(string) (string != nil && [string length] > 0)
#define SetHasItems(set) (set != nil && [set count] > 0)

#define def_bonjourHostName [[UIDevice currentDevice] name]

#define euclideanDistance(pointOne, pointTwo) sqrt(pow((pointOne.x - pointTwo.x),2) + pow((pointOne.y - pointTwo.y),2))

#define rectDescriptionString(rect) [NSString stringWithFormat:@"w:%f h:%f x:%f y:%f",rect.size.width,rect.size.height, rect.origin.x,rect.origin.y] 

#if DEBUG_MODE_ENABLED == 1
#if CONFIGURATION == Debug
	#define EXOLog NSLog
	#else
		#error verbose outputs of EXOLog -- DEBUG_MODE_ENABLED = 1 for non-debug build
	#endif
#elif DEBUG_MODE_ENABLED == 2
#import "exoLogOverlay.h"
#define EXOLog(args...) [[exoLogOverlay sharedLogOverlay] log:[NSString stringWithFormat:args]]; NSLog(args);
#else
	#define EXOLog(format, ...)
#endif

#pragma mark includes
#import "swypWorkspaceViewController.h"
#import "swypTiledContentViewController.h"
#import "swypFileTypeString.h"
#import "swypContentDataSourceProtocol.h"
#import "NSDictionary+BSJSONAdditions.h"
#import "UIColorAdditions.h"
#import "UIViewAdditions+swypAdditions.h"