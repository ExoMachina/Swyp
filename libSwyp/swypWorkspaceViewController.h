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


@class swypWorkspaceViewController;
@protocol swypWorkspaceDelegate <NSObject>
-(void)	delegateShouldDismissSwypWorkspace: (swypWorkspaceViewController*)workspace;
@end

@interface swypWorkspaceViewController : UIViewController <swypConnectionManagerDelegate, swypContentInteractionManagerDelegate, UIGestureRecognizerDelegate> {
	swypContentInteractionManager *		_contentManager;
	swypConnectionManager *				_connectionManager;
		
	NSString *							_workspaceID;

	BOOL								_showContentWithoutConnection;
	id<swypWorkspaceDelegate>			_worspaceDelegate;
	
	
	//workspace UI Items	
	UIImageView *						_swypPromptImageView;
	UIButton *							_swypWifiAvailableButton;
	UIButton *							_swypCloudAvailableButton;
	UIButton *							_swypBluetoothAvailableButton;
    UIView *                            _downArrowView;
}

//if set to TRUE, then content is displayed before swyp connection is made, and if content is swyped, then connection + content transfer is made
@property (nonatomic, assign)	BOOL							showContentWithoutConnection;

@property (nonatomic, readonly)	swypConnectionManager*			connectionManager;
@property (nonatomic, readonly)	swypContentInteractionManager*	contentManager;

@property (nonatomic, assign)	id<swypWorkspaceDelegate>		worspaceDelegate;

-(id)	initWithWorkspaceDelegate:(id<swypWorkspaceDelegate>)	worspaceDelegate;

@end
