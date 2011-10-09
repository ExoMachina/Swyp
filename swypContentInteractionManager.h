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

-(UIImage*)		imageForContentAtIndex:	(NSUInteger)index	inController:(UIViewController*)contentDisplayController;
-(NSInteger)	totalContentCountInController:(UIViewController*)contentDisplayController;

//if you wish to support content-swyp-out -- that is, swyping of content before a conneciton is made
//especially relevant if showContentBeforeConnection is TRUE
-(void)	contentSwypOutOccuredForContentAtIndex:	(NSUInteger)index	inController:(UIViewController*)contentDisplayController;
//we should either do this, or we should see what view the swipe gesture detected a swypOutOn, and see if that was on our content!  -- DO THIS!
@end

@protocol swypContentDisplayViewController <NSObject>
-(void)	removeContentFromDisplayAtIndex:	(NSUInteger)removeIndex animated:(BOOL)animate;
-(void)	insertContentToDisplayAtIndex:		(NSUInteger)insertIndex animated:(BOOL)animate;

-(void)	setContentDisplayControllerDelegate: (id<swypContentDisplayViewControllerDelegate>)contentDisplayControllerDelegate;
-(id<swypContentDisplayViewControllerDelegate>)	contentDisplayControllerDelegate;

-(void)	reloadAllData;

@optional
//-1 means all content
-(void)	returnContentAtIndexToNormalLocation:	(NSInteger)index	animated:(BOOL)animate;
@end


@interface swypContentInteractionManager : NSObject <swypConnectionSessionDataDelegate, swypConnectionSessionInfoDelegate,	swypContentDisplayViewControllerDelegate, swypContentDataSourceDelegate> {
	NSMutableDictionary *									_sessionViewControllersBySession;
	
	NSObject<swypContentDataSourceProtocol, swypConnectionSessionDataDelegate>*				_contentDataSource;
	
	UIViewController<swypContentDisplayViewController>*		_contentDisplayController;
	
	UIImageView *											_swypPromptImageView;
	
	UIView*													_mainWorkspaceView;
	
	BOOL													_showContentBeforeConnection;
}	
@property(nonatomic, retain)	NSObject<swypContentDataSourceProtocol, swypConnectionSessionDataDelegate>*				contentDataSource;

//if set to TRUE, then content is displayed before swyp connection is made, and if content is swyped, then connection + content transfer is made
//this value is assigned at init by workspace manager
@property (nonatomic, readonly)	BOOL														showContentBeforeConnection;

//if not set, the standard will be assigned
@property(nonatomic, retain)	UIViewController<swypContentDisplayViewController>*			contentDisplayController;

-(id)	initWithMainWorkspaceView: (UIView*)workspaceView showingContentBeforeConnection:(BOOL)showContent;

//in order of preference where index 0=most preferant 
+(NSArray*)	supportedFileTypes;

-(void)		maintainSwypSessionViewController:(swypSessionViewController*)sessionViewController;

-(void)		stopMaintainingViewControllerForSwypSession:(swypConnectionSession*)session;
-(swypSessionViewController*)	maintainedSwypSessionViewControllerForSession:(swypConnectionSession*)session;

-(void)		stopMaintainingAllSessionViewControllers;

//this method sets-up the workspace for user prompts, and etc. Called when workspaceViewController's viewDidLoad
-(void)		initializeInteractionWorkspace;

-(void)	temporarilyExagerateContentAtIndex:	(NSUInteger)index;

//
//private
-(swypSessionViewController*)		_sessionViewControllerInMainViewOverlappingRect:(CGRect) testRect;
//-(void)							_contentRepresentationViewWasReleased:;
-(void)		_setupForAllSessionsRemoved;
-(void)		_setupForFirstSessionAdded;

-(void)		_displayContentDisplayController:(BOOL)display;

@end
