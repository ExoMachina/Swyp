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

/// Proxy method that sets the swypContentInteractionManager's contentDataSource.
@property (nonatomic, retain) NSObject<swypContentDataSourceProtocol>* contentDataSource;

/** Adds a delegate for notification when data received w/o retention. 

 A proxy method for [[self contentManager] addDataDelegate:]... See the documentation on swypContentInteractionManager.
 */
-(void) addDataDelegate: (id <swypConnectionSessionDataDelegate> )		delegate;
///Removes the dataDelegate
-(void) removeDataDelegate: (id <swypConnectionSessionDataDelegate>)	delegate;


///The primary init function
-(id) init;

/**
 Self retaining singleton swyp workspace for apps that use swyp everywhere.
 */
+(swypWorkspaceViewController*)	sharedSwypWorkspace;

///Dispays workspace with nice texture, with scroll up from bottom
-(void)presentContentWorkspaceAtopViewController:(UIViewController*)controller;

///displays the workspace with content in background, with fade from background, with content under finger
-(void)	presentContentSwypWorkspaceAtopViewController:(UIViewController*)controller withContentView:(swypSwypableContentSuperview*)contentView swypableContentImage:(UIImage*)contentImage forContentOfID:(NSString*)contentID atRect:(CGRect)contentRect;

/** Use this method to grab a UIView that can be used as a "swyp-in zone" on your existing view hierarchy.
 
 returns a swypWorkspaceView that has a contentDisplayController that can show received thumbnails from swyp-ins, and will delegate to swypWorkspaceViewController on swyp-gestures.
 
 This object is retained within the swyp framework, so you must call discardEmbeddableSwypWorkspaceView: after use.
 */
-(swypWorkspaceView*)	embeddableSwypWorkspaceViewForWithFrame:(CGRect)frame;

/**
 After calling this method, the swyp framwork will no longer be retaining the swypWorkspaceView, nor will it update it for connectivity or contentReceipt.
 */
-(void)					removeEmbeddableSwypWorkspaceView:(swypWorkspaceView*)workspaceView;

//
//private
-(void) _setupUIForCurrentOrientation;

@end
