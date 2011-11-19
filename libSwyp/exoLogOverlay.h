//
//  exoLogOverlay.h
//  swyp
//
//  Created by Alexander List on 8/3/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface exoLogOverlay : NSObject {
	UITextView *	_logTextView;
}

+(exoLogOverlay*)	sharedLogOverlay;

-(void)	log:(NSString*)logText;

@end
