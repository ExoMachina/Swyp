//
//  swypWorkspaceViewController.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import <Foundation/Foundation.h>
#import "swypContentInteractionManager.h"
#import "swypConnectionManager.h"
#import "swypSessionViewController.h"

@interface swypWorkspaceViewController : UIViewController <swypConnectionManagerDelegate, UIGestureRecognizerDelegate> {
	swypContentInteractionManager *		_contentManager;
	swypConnectionManager *				_connectionManager;
	
	NSString *							_workspaceID;
}
@property (nonatomic, readonly)	NSString *						workspaceID;
@property (nonatomic, readonly)	swypConnectionManager*			connectionManager;
@property (nonatomic, readonly)	swypContentInteractionManager*	contentManager;

-(id)	initWithContentWorkspaceID:(NSString*)workspaceID;

@end
