//
//  swypContentScrollTrayController.h
//  exoNotes
//
//  Created by Alexander List on 4/16/11.
//  Copyright 2011 exoMachina. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "swypContentInteractionManager.h"




@interface trayContentObjectSet : NSObject{
	UIImage	*		_contentPreviewImage;
	UIImageView *	_contentPreviewImageView;
}
@property (nonatomic, retain) UIImage	*		contentPreviewImage;
@property (nonatomic, retain) UIImageView *		contentPreviewImageView;
@end




@interface swypContentScrollTrayController : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate, swypContentDisplayViewController> {
	NSMutableDictionary	*	_cachedContentObjectSetsForTray;
	
	NSMutableSet		*	_unusedUIImageViewSet;
	
	UIScrollView *			_trayScrollView;
	CGSize					_contentImageSize;
	float					_contentSpacingWidth;
	
	CGPoint					_fadeoutOrigin;
	CGPoint					_displayOrigin;
	
	
	id<swypContentDisplayViewControllerDelegate>	_contentDisplayControllerDelegate;	
}
@property (nonatomic, assign) CGSize			contentImageSize;
@property (nonatomic, assign) float				contentSpacingWidth;
@property (nonatomic, assign)	NSInteger			currentSelectedContentIndex;
@property (nonatomic, assign)	CGPoint fadeoutOrigin;
@property (nonatomic, assign)	CGPoint displayOrigin;
@property (nonatomic, readonly)	UIScrollView *		trayScrollView;


-(void)displayAtPoint:(CGPoint)point inView:(UIView*)displayView belowView:(UIView*)below animated:(BOOL)animate;
-(void)hideFromDisplayAndAnimated:(BOOL)animate;	
-(BOOL)isDisplayed;



-(void)			releaseImageViewFromUseWithObjectSet:(trayContentObjectSet*)objectSet;
-(UIImageView*)	imageViewForObjectSet:(trayContentObjectSet*)contentSet;


-(void)	giggleContentAtIndex:(NSInteger)displayedContent;

//updating displayed data
//1) delete from datasource 2) call removeNotebookFromDisplay
-(void)	removeScrollPageContentFromDisplayAtIndex:(NSInteger)displayedContent animated:(BOOL)animate;
//1) add to datasource 2) call insertNotebookToDisplayAtIndex
-(void)	insertScrollPageContentToDisplayAtIndex:(NSInteger)insertIndex animated:(BOOL)animate;

-(void)			reloadTrayContentImageData;
//updates content image, refreshes all around it
-(void)			updateContentAtIndex:(NSInteger)contentIndex;
//refreshes currently selected contents
-(void)			refreshContentSelection;
//dumps everything and reloads
-(void)			reloadAllData;



-(trayContentObjectSet *)	layoutContentImageAtIndex:(NSInteger)idx;
-(NSRange)					rangeOfContentsForContentFrame:(CGRect)	displayRect;
-(void)						setupLayoutForImagesInContentFrame:(CGRect)	displayRect;
-(void)						setupContentSelectionViewWidthWithContentCount:(NSUInteger)contentCount;
-(CGRect)					frameForContentImageAtIndex:(NSUInteger)contentIndex;
-(trayContentObjectSet*)	trayContentObjectSetForIndex:(NSInteger)contentIndex;
-(NSInteger)				contentObjectIndexOnTrayAtTapPoint:(CGPoint)tapPoint;

-(NSInteger)	indexOfTrayObjectWithAssociatedPreviewImageView: (UIImageView*) previewImageView;

//-1	= not visible
//0		= first visible (even partially) notebook
//n		= the notebook on scroll view
//locations contain their immediate margins
-(NSInteger)		visibleContentLocationForContentIndex:(NSInteger)contentIndex;	
-(NSInteger)		insertIndexFromVisibleContentLocation:(NSInteger)visibleContentLocation;


@end
