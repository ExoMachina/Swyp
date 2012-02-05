//
//  swypContentDisplayViewControllerProtocol.h
//  libSwyp
//
//  Created by Alexander List on 1/20/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

@protocol swypContentDisplayViewController;

@protocol swypContentDisplayViewControllerDelegate <NSObject>

/** Signals that a view was swyped-out ontop of a certain content with the enclosed contentID.

	If there is no tray in the location swyped-out to, the swypContentInteractionManager should notify the workspace.
 */
-(void)	contentWithIDUnderwentSwypOut:(NSString*)contentID inController:(UIViewController<swypContentDisplayViewController>*)contentDisplayController;

/**
	Indicates that content was swyped-up and off the workspace. The data model will subsequently remove this content, then push the update back to the sending contentDisplayController.
 */
-(void) contentWithIDWasDraggedOffWorkspace:(NSString*)contentID inController:(UIViewController<swypContentDisplayViewController>*)contentDisplayController;

///the returned UIView will be as close as possible to and no larger than maxIconSize, while in proper-perspective and not distorted
-(UIView*)		viewForContentWithID:(NSString*)contentID ofMaxSize:(CGSize)maxIconSize inController:(UIViewController<swypContentDisplayViewController>*)contentDisplayController;

///All ids in NSString that the delegate can provide UIViews for
-(NSArray*)		allIDsForContentInController:(UIViewController<swypContentDisplayViewController>*)contentDisplayController;
@end




@protocol swypContentDisplayViewController <NSObject>
///How model updates propigate removed content through swypContentInteractionManager
-(void)	removeContentFromDisplayWithID:	(NSString*)removeID animated:(BOOL)animate;
///How modal updates propigate added content through swypContentInteractionManager
-(void)	addContentToDisplayWithID: (NSString*)insertID animated:(BOOL)animate;

///Returns everything displayed on the VC
-(NSArray*)	allDisplayedObjectIDs;

-(void)	setContentDisplayControllerDelegate: (id<swypContentDisplayViewControllerDelegate>)contentDisplayControllerDelegate;
-(id<swypContentDisplayViewControllerDelegate>)	contentDisplayControllerDelegate;

///reloads all displayed content through swypContentDisplayViewControllerDelegate
-(void)	reloadAllData;

///	Returns max size of displayed content on workspace
-(CGSize) choiceMaxSizeForContentDisplay;

@optional
///Reposition content to frame location within view
-(void)	moveContentWithID: (NSString*)insertID toFrame:(CGRect)frame animated:(BOOL)animate;

//If a swyp out begins on a content piece, the recognizer knows what view it started on, and especially if showContentBeforeConnection is TRUE, 
//	we can use this to check whether we should commence a "content swyp"
//We'll consider what to do if we already have dropped this thing on to the connection indicator soon	
-(NSString*)	contentIDMatchingSwypOutView:	(UIView*)swypedView;
@end
