//
//  swypContentDisplayViewControllerProtocol.h
//  libSwyp
//
//  Created by Alexander List on 1/20/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

@protocol swypContentDisplayViewController;

@protocol swypContentDisplayViewControllerDelegate <NSObject>
-(void)	contentAtIndex: (NSUInteger)index wasDraggedToFrame: (CGRect)draggedFrame inController:(UIViewController*)contentDisplayController;
-(void)	contentAtIndex: (NSUInteger)index wasReleasedWithFrame: (CGRect)draggedFrame inController:(UIViewController*)contentDisplayController;

//the returned UIImage will be as close as possible to and no larger than maxIconSize, while in proper-perspective and not distorted
-(UIImage*)		imageForContentAtIndex:	(NSUInteger)index ofMaxSize:(CGSize)maxIconSize inController:(UIViewController*)contentDisplayController;
-(NSInteger)	totalContentCountInController:(UIViewController*)contentDisplayController;
@end




@protocol swypContentDisplayViewController <NSObject>
///How model updates propigate removed content through swypContentInteractionManager
-(void)	removeContentFromDisplayAtIndex:	(NSUInteger)removeIndex animated:(BOOL)animate;
///How modal updates propigate added content through swypContentInteractionManager
-(void)	insertContentToDisplayAtIndex:		(NSUInteger)insertIndex animated:(BOOL)animate fromStartLocation:(CGPoint)startLocation;

-(void)	setContentDisplayControllerDelegate: (id<swypContentDisplayViewControllerDelegate>)contentDisplayControllerDelegate;
-(id<swypContentDisplayViewControllerDelegate>)	contentDisplayControllerDelegate;

///reloads all displayed content through swypContentDisplayViewControllerDelegate
-(void)	reloadAllData;

///	Returns max size of displayed content on workspace
-(CGSize) choiceMaxSizeForContentDisplay;

@optional
//-1 means all content
-(void)	returnContentAtIndexToNormalLocation:	(NSInteger)index	animated:(BOOL)animate;

//If a swyp out begins on a content piece, the recognizer knows what view it started on, and especially if showContentBeforeConnection is TRUE, 
//	we can use this to check whether we should commence a "content swyp"
//We'll consider what to do if we already have dropped this thing on to the connection indicator soon	
-(NSInteger)	contentIndexMatchingSwypOutView:	(UIView*)swypedView;
@end
