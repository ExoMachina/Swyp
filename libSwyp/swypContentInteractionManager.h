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


@class swypContentInteractionManager;
@protocol swypContentDisplayViewControllerDelegate <NSObject>
-(void)	contentAtIndex: (NSUInteger)index wasDraggedToFrame: (CGRect)draggedFrame inController:(UIViewController*)contentDisplayController;
-(void)	contentAtIndex: (NSUInteger)index wasReleasedWithFrame: (CGRect)draggedFrame inController:(UIViewController*)contentDisplayController;

//the returned UIImage will be as close as possible to and no larger than maxIconSize, while in proper-perspective and not distorted
-(UIImage*)		imageForContentAtIndex:	(NSUInteger)index ofMaxSize:(CGSize)maxIconSize inController:(UIViewController*)contentDisplayController;
-(NSInteger)	totalContentCountInController:(UIViewController*)contentDisplayController;
@end

#pragma mark TODO
//bring me into seperate .h!
@protocol swypContentDisplayViewController <NSObject>
-(void)	removeContentFromDisplayAtIndex:	(NSUInteger)removeIndex animated:(BOOL)animate;
-(void)	insertContentToDisplayAtIndex:		(NSUInteger)insertIndex animated:(BOOL)animate fromStartLocation:(CGPoint)startLocation;

-(void)	setContentDisplayControllerDelegate: (id<swypContentDisplayViewControllerDelegate>)contentDisplayControllerDelegate;
-(id<swypContentDisplayViewControllerDelegate>)	contentDisplayControllerDelegate;

-(void)	reloadAllData;

@optional
//-1 means all content
-(void)	returnContentAtIndexToNormalLocation:	(NSInteger)index	animated:(BOOL)animate;

//If a swyp out begins on a content piece, the recognizer knows what view it started on, and especially if showContentBeforeConnection is TRUE, 
//	we can use this to check whether we should commence a "content swyp"
//We'll consider what to do if we already have dropped this thing on to the connection indicator soon	
-(NSInteger)	contentIndexMatchingSwypOutView:	(UIView*)swypedView;
@end

/** This class is responsible for unifying modal and controller, and displaying them upon the workspace. */
@interface swypContentInteractionManager : NSObject <swypConnectionSessionDataDelegate, swypConnectionSessionInfoDelegate,	swypContentDisplayViewControllerDelegate, swypContentDataSourceDelegate> {
	NSMutableDictionary *									_sessionViewControllersBySession;
	
	NSObject<swypContentDataSourceProtocol, swypConnectionSessionDataDelegate>*				_contentDataSource;
	
	UIViewController<swypContentDisplayViewController>*		_contentDisplayController;
	
	UIView*													_mainWorkspaceView;
		
}	

/** This property is the datasource that the content in contentDisplayController is sourced from per the swypContentDataSourceProtocol protocol. 
 
 By default, this is also the default swypConnectionSessionDataDelegate delegate for received data.
 
 @warning there is no default datasource.
 */
@property(nonatomic, retain)	NSObject<swypContentDataSourceProtocol, swypConnectionSessionDataDelegate>*				contentDataSource;


/** This property is the view controller that contentDataSource content is displayed from. 
 
 @warning if not set, the standard will be assigned. That is swypPhotoPlayground currently.
 @warning this class must obey the swypContentDisplayViewController protocol. 
 */
@property(nonatomic, retain)	UIViewController<swypContentDisplayViewController>*			contentDisplayController;


/** The main init function. 
 */
-(id)	initWithMainWorkspaceView: (UIView*)workspaceView;


#pragma mark TODO: update file types to set custom
/** Supported swyp receipt file types; in order of greatest preference, where index 0=most preferant 
 @warning	This value is only non-nil after setting a dataSource
 */
+(NSArray*)	supportedReceiptFileTypes;

-(void)		maintainSwypSessionViewController:(swypSessionViewController*)sessionViewController;

-(void)		stopMaintainingViewControllerForSwypSession:(swypConnectionSession*)session;
-(swypSessionViewController*)	maintainedSwypSessionViewControllerForSession:(swypConnectionSession*)session;

-(void)		stopMaintainingAllSessionViewControllers;

//this method sets-up the workspace for user prompts, and etc. Called when workspaceViewController's viewDidLoad
-(void)		initializeInteractionWorkspace;

//simply attempts to post conent to a session, as used during "contentSwyps"
-(void)		sendContentAtIndex: (NSUInteger)index	throughConnectionSession: (swypConnectionSession*)	session;

//	sometimes one wants to jiggle some content in some manner-- here's how
-(void)		temporarilyExagerateContentAtIndex:	(NSUInteger)index;

//
//private
-(swypSessionViewController*)		_sessionViewControllerInMainViewOverlappingRect:(CGRect) testRect;
//-(void)							_contentRepresentationViewWasReleased:;

-(void)		_displayContentDisplayController:(BOOL)display;

@end
