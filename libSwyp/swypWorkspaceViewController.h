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
#import "swypWorkspaceView.h"

/** This class is the UIViewController displayed to the user. 
 
 Set a datasource using [swypWorkspace setContentDataSource:(NSObject<swypContentDataSourceProtocol, swypConnectionSessionDataDelegate>*) contentDataSource], then display this swyp workspace as a modal view!
 
 */
@interface swypWorkspaceViewController : UIViewController <swypConnectionManagerDelegate, UIGestureRecognizerDelegate, swypSwypableContentSuperviewWorkspaceDelegate> {
	swypContentInteractionManager *		_contentManager;
	swypConnectionManager *				_connectionManager;
		
	NSString *							_workspaceID;

	BOOL								_showContentWithoutConnection;
	
	
	//workspace UI Items
	UIInterfaceOrientation				_openingOrientation; //allow rotation to same of current kind
	
	UITapGestureRecognizer *			_leaveWorkspaceTapRecog;
	UISwipeGestureRecognizer *			_swipeDownRecognizer;

	swypWorkspaceView *					_mainWorkspaceView;
	NSMutableSet *						_allWorkspaceViews;
	
}
@property (nonatomic, readonly)	swypConnectionManager*			connectionManager;
@property (nonatomic, readonly)	swypContentInteractionManager*	contentManager;

///Sets the swypContentInteractionManager's contentDataSource
@property (nonatomic, retain) NSObject<swypContentDataSourceProtocol, swypConnectionSessionDataDelegate>* contentDataSource;


///The primary init function
-(id) init;

/**
 Self retaining singleton swyp workspace for apps that use swyp everywhere.
 */
+(swypWorkspaceViewController*)	sharedSwypWorkspace;

///Dispays workspace with nice texture, with scroll up from bottom
-(void)presentContentWorkspaceAtopViewController:(UIViewController*)controller;

///displays the workspace with content in background, with fade from background, with content under finger
-(void)	presentContentSwypWorkspaceAtopViewController:(UIViewController*)controller withContentView:(swypSwypableContentSuperview*)contentView forContentOfID:(NSString*)contentID atRect:(CGRect)contentRect;

-(swypWorkspaceView*)	workspaceViewForEmbeddedSwypInWithFrame:(CGRect)frame;

//
//private
-(void) _setupUIForCurrentOrientation;
-(void) _animateArrows:(id)sender;
-(void) _stopArrows:(id)sender;

@end
