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
#import "swypPromptImageView.h"
#import "swypWorkspaceBackgroundView.h"
#import "swypSwypableContentSuperview.h"

@class swypWorkspaceViewController;
///@warning Depreciated! The workspace now dismisses itself. 
@protocol swypWorkspaceDelegate <NSObject>
@end

/** This class is the UIViewController displayed to the user. 
 
 Set a datasource using [swypWorkspace setContentDataSource:(NSObject<swypContentDataSourceProtocol, swypConnectionSessionDataDelegate>*) contentDataSource], then display this swyp workspace as a modal view!
 
 */
@interface swypWorkspaceViewController : UIViewController <swypConnectionManagerDelegate, UIGestureRecognizerDelegate, swypSwypableContentSuperviewWorkspaceDelegate> {
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

///Sets the swypWorkspaceDelegate which alerts when the view wishes to dismiss
@property (nonatomic, assign)	id<swypWorkspaceDelegate>		worspaceDelegate;

///Sets the swypContentInteractionManager's contentDataSource
@property (nonatomic, retain) NSObject<swypContentDataSourceProtocol, swypConnectionSessionDataDelegate>* contentDataSource;

/** Old init function.
 @warning DEPRECATED; the workspace now dismisses itself. 
 Use regular init, instead.
 */
-(id)   initWithWorkspaceDelegate:(id<swypWorkspaceDelegate>)	worspaceDelegate;

///The primary init function
-(id) init;

/**
 Self retaining singleton swyp workspace for apps that use swyp everywhere.
 */
+(swypWorkspaceViewController*)	sharedSwypWorkspace;

//
//private
-(void) _setupUIForCurrentOrientation;
-(void) _setupWorkspacePromptUI;
-(void) _animateArrows:(id)sender;
-(void) _stopArrows:(id)sender;

@end
