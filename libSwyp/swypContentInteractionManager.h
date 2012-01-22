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


/** This class is responsible for unifying modal and controller, and displaying them upon the workspace. 
 
	This class also caches UIImageViews for display by swypContentDisplayViewController, with image content from the contentDataSource.
 */
@interface swypContentInteractionManager : NSObject <swypConnectionSessionDataDelegate, swypConnectionSessionInfoDelegate, swypDiscernedInputStreamStatusDelegate,	swypContentDisplayViewControllerDelegate, swypContentDataSourceDelegate> {
	NSMutableDictionary *									_sessionViewControllersBySession; //swypSessionViewControllers
	
	swypBidirectionalMutableDictionary*	_contentViewsByContentID;
	swypBidirectionalMutableDictionary*	_thumbnailLoadingViewsByContentID;
		
	NSObject<swypContentDataSourceProtocol, swypConnectionSessionDataDelegate>*				_contentDataSource;
	
	UIViewController<swypContentDisplayViewController>*		_contentDisplayController;
	
	UIView*													_mainWorkspaceView;
		
}	
@property (nonatomic, readonly) swypBidirectionalMutableDictionary * contentViewsByContentID;

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
-(void)		sendContentWithID: (NSString*)contentID	throughConnectionSession: (swypConnectionSession*)	session;

//
//private
-(swypSessionViewController*)		_sessionViewControllerInMainViewOverlappingRect:(CGRect) testRect;
//-(void)							_contentRepresentationViewWasReleased:;

-(void)		_displayContentDisplayController:(BOOL)display;

@end
