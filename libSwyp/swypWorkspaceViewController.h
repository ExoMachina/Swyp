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
#import "swypPromptImageView.h"
#import "swypWorkspaceBackgroundView.h"

@class swypWorkspaceViewController;
@protocol swypWorkspaceDelegate <NSObject>
-(void)	delegateShouldDismissSwypWorkspace: (swypWorkspaceViewController*)workspace;
@end

/** This class is the UIViewController displayed to the user. 
 
 Set a datasource, display it to the user, and you're off!
 See swypContentInteractionManager for methods for setting display view controller and data model.
 */
@interface swypWorkspaceViewController : UIViewController <swypConnectionManagerDelegate, UIGestureRecognizerDelegate> {
	swypContentInteractionManager *		_contentManager;
	swypConnectionManager *				_connectionManager;
		
	NSString *							_workspaceID;

	BOOL								_showContentWithoutConnection;
	id<swypWorkspaceDelegate>			_worspaceDelegate;
	
	
	//workspace UI Items	
	SwypPromptImageView *				_swypPromptImageView;
	UIButton *							_swypNetworkInterfaceClassButton;
    UIView *                            _downArrowView;
}

@property (nonatomic, readonly)	swypConnectionManager*			connectionManager;
@property (nonatomic, readonly)	swypContentInteractionManager*	contentManager;
@property (nonatomic, retain) swypWorkspaceBackgroundView*      backgroundView;

@property (nonatomic, assign)	id<swypWorkspaceDelegate>		worspaceDelegate;

/** the main workspace init method 

 You'll need to set the workpace delegate to be told when workspace wants to be dismissed.
 
 */
-(id)   initWithWorkspaceDelegate:(id<swypWorkspaceDelegate>)	worspaceDelegate;
-(void) setBluetoothReady:(NSNumber *)isReady;

//
//private
-(void) _setupUIForCurrentOrientation;
-(void) _setupWorkspacePromptUI;

@end
