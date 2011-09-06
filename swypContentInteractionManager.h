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
@end

@protocol swypContentDisplayViewController <NSObject>
-(void)	removeContentFromDisplayAtIndex:	(NSUInteger)removeIndex animated:(BOOL)animate;
-(void)	insertContentToDisplayAtIndex:		(NSUInteger)insertIndex animated:(BOOL)animate;

-(void)	setContentDisplayControllerDelegate: (id<swypContentDisplayViewControllerDelegate>)contentDisplayControllerDelegate;
-(id<swypContentDisplayViewControllerDelegate>)	contentDisplayControllerDelegate;

-(void)	reloadAllData;

@optional
-(void)	temporarilyExagerateContentAtIndex:	(NSUInteger)index;
//-1 means all content
-(void)	returnContentAtIndexToNormalLocation:	(NSInteger)index	animated:(BOOL)animate;
@end


@interface swypContentInteractionManager : NSObject <swypConnectionSessionDataDelegate, swypConnectionSessionInfoDelegate,	swypContentDisplayViewControllerDelegate, swypContentDataSourceDelegate> {
	NSMutableDictionary *									_sessionViewControllersBySession;
	
	NSObject<swypContentDataSourceProtocol, swypConnectionSessionDataDelegate>*				_contentDataSource;
	
	UIViewController<swypContentDisplayViewController>*		_contentDisplayController;
	
	UIView*													_mainWorkspaceView;
}
@property(nonatomic, retain)	NSObject<swypContentDataSourceProtocol, swypConnectionSessionDataDelegate>*				contentDataSource;

//if not set, the standard will be assigned
@property(nonatomic, retain)	UIViewController<swypContentDisplayViewController>*		contentDisplayController;

-(id)	initWithMainWorkspaceView: (UIView*)	workspaceView;

//in order of preference where 0=most preferant 
+(NSArray*)	supportedFileTypes;

-(void)		maintainSwypSessionViewController:(swypSessionViewController*)sessionViewController;

-(void)		stopMaintainingViewControllerForSwypSession:(swypConnectionSession*)session;
-(swypSessionViewController*)	maintainedSwypSessionViewControllerForSession:(swypConnectionSession*)session;

-(void)		stopMaintainingAllSessionViewControllers;

//
//private
-(swypSessionViewController*)	_sessionViewControllerInMainViewOverlappingRect:(CGRect) testRect;
//-(void)							_contentRepresentationViewWasReleased:;
-(void)		_setupForAllSessionsRemoved;
-(void)		_setupForFirstSessionAdded;

@end
