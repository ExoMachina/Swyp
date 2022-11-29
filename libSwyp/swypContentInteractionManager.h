//
//  swypContentInteractionManager.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import <Foundation/Foundation.h>
#import "swypSessionViewController.h"
#import "swypConnectionSession.h"
#import "swypContentDataSourceProtocol.h"
#import "swypContentDisplayViewControllerProtocol.h"
#import "swypBidirectionalMutableDictionary.h"
#import "swypWorkspaceView.h"

/** This class is responsible for unifying modal and controller, and displaying them upon the workspace. 
 
	This class also caches UIImageViews for display by swypContentDisplayViewController, with image content from the contentDataSource.
 */
@interface swypContentInteractionManager : NSObject <swypConnectionSessionDataDelegate, swypConnectionSessionInfoDelegate, swypDiscernedInputStreamStatusDelegate,	swypContentDisplayViewControllerDelegate, swypContentDataSourceDelegate> {
	NSMutableDictionary *									_sessionViewControllersBySession; //swypSessionViewControllers
	
	swypBidirectionalMutableDictionary*	_contentViewsByContentID;
	swypBidirectionalMutableDictionary*	_thumbnailLoadingViewsByContentID;
		
	NSObject<swypContentDataSourceProtocol>*					_contentDataSource;

	NSMutableArray *											_dataDelegates;
	
	NSMutableDictionary *										_contentDisplayControllerByWorkspaceView;

	swypWorkspaceView*											_mainWorkspaceView;
		
}
@property (nonatomic, readonly) swypBidirectionalMutableDictionary * contentViewsByContentID;

/** This property is the datasource that the content in contentDisplayController is sourced from per the swypContentDataSourceProtocol protocol. 

 The datasource is retained. There is only one datasource at a time, the previous one is released when setting another. 
 
 @warning there is no default datasource.
 */
@property(nonatomic, retain)	NSObject<swypContentDataSourceProtocol>*				contentDataSource;

/**
	Adds a data delegate for future notification on session data events; does not retain, be sure to release. Simply adds to existing sessions, and stores w/o retention for adding to future sessions.
	Any delegate added will be queried for supported file types for receipt. 

	This delegate does retain your delegate. You must remove your data delegate when it become invalid, otherwise your app will crash.

 Data delegates' supportedFileTypesForReceipt property works from this method in a LIFO basis. Re-adding an existing object adds it to the end. 
 */
-(void) addDataDelegate: (id <swypConnectionSessionDataDelegate>)		dataDelegate;
///Removes delegate from existing sessions; removes from local storage.
-(void) removeDataDelegate: (id <swypConnectionSessionDataDelegate>)	dataDelegate;

/** The main init function. 

 Automatically populates contentDisplayControllerByWorkspaceView with primary swyp workspace view, and creates a new swyp photo playground for manipulation therein. 
 
 @param workspaceView relevant because it's the default 'active' view

 */
-(id)	initWithMainWorkspaceView: (swypWorkspaceView*)workspaceView;


/** Supported swyp receipt file types; in order of greatest preference, where index 0=most preferant 
 @warning	This value is only non-nil after setting a dataSource
 */
+(NSArray*)	supportedReceiptFileTypes;

///Updates the supportedReceiptFileTypes singleton-backed class method with each dataDelegate
-(void)		updateSupportedReceiptTypes;

///Causes a sessionViewController to be displayed on workspace, and for it to be tracked locally
-(void)		maintainSwypSessionViewController:(swypSessionViewController*)sessionViewController;

///Removes from display, releases
-(void)		stopMaintainingViewControllerForSwypSession:(swypConnectionSession*)session;

///Gets the viewController for an associated session
-(swypSessionViewController*)	maintainedSwypSessionViewControllerForSession:(swypConnectionSession*)session;

///Removes all, typically for app exit
-(void)		stopMaintainingAllSessionViewControllers;

/** 
 Returns the contentDisplayController showing the content id, or nil if none.
 */
-(UIViewController<swypContentDisplayViewController>*)	displayControllerForContentID:(NSString*)contentID;

/** 
 Returns the viewController whos view is displayed currently, or the _mainWorkspaceView's contentDisplayController
 */
-(UIViewController<swypContentDisplayViewController>*)	currentActiveContentDisplayController;


///	associates a content display view with a workspaceView
-(void)	addSwypWorkspaceViewToInteractionLoop:(swypWorkspaceView*)worksapceView;

/// removes the association of a workspace view with its content display controller
-(void)	removeSwypWorkspaceViewFromInteractionLoop:(swypWorkspaceView*)worksapceView;

///simply attempts to post conent to a session, as used during "contentSwyps"
-(void)		sendContentWithID: (NSString*)contentID	throughConnectionSession: (swypConnectionSession*)	session;

/** Used by swypWorkspaceManager to indicate swypSwypableContentSuperview content addition. 
 
 Adds to cached tiles, and sets to display in contentDisplayViewController, then moves content to frame 'destination.'
 */
-(void)		handleContentSwypOfContentWithID:(NSString*)contentID withContentImage:(UIImage*)contentImage toRect:(CGRect)destination;
//
//private
-(UIImageView*)	_gloirifiedFramedImageViewWithUIImage:(UIImage*)image;

-(swypSessionViewController*)		_sessionViewControllerInMainViewOverlappingRect:(CGRect) testRect;

-(void)	_addContentDisplayControllerToWorkspaceView:(swypWorkspaceView*)view;
@end
