//
//  swypContentScrollTrayController.h
//  exoNotes
//
//  Created by Alexander List on 4/16/11.
//  Copyright 2011 exoMachina. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "swypContentInteractionManager.h"

@class swypContentScrollTrayController;

@protocol swypContentScrollTrayControllerDelegate <NSObject>

-(UIImage*)		pagePreviewImageForPageIndex:(NSInteger)pageIndex withswypContentScrollTrayController:(swypContentScrollTrayController*)trayController;
-(NSInteger)	numberOfPagesInPageSelectionScrollTrayWithController:(swypContentScrollTrayController*)trayController;


@optional 
-(NSInteger)	currentlySelectedPageForScrollTrayWithController:(swypContentScrollTrayController*)trayController;

-(void)			pageSelectionScrollTrayWantsDeletePageAtPageIndex:(NSInteger)pageIndex withswypContentScrollTrayController:(swypContentScrollTrayController*)trayController; 

-(void)			swypContentScrollTrayControllerWantsHide:(swypContentScrollTrayController*)trayController;

-(void)			controllerDidSelectPageAtIndex:(NSInteger)selectedPage withswypContentScrollTrayController:(swypContentScrollTrayController*)trayController;

-(void)			pageSelectionScrollTrayWantsDuplicatePageAtPageIndex:(NSInteger)pageIndex withswypContentScrollTrayController:(swypContentScrollTrayController*)trayController; 

@end


@interface trayPageObjectSet : NSObject{
	UIImage	*		_pagePreviewImage;
	UIImageView *	_pagePreviewImageView;
}
@property (nonatomic, retain) UIImage	*		pagePreviewImage;
@property (nonatomic, retain) UIImageView *		pagePreviewImageView;
@end




@interface swypContentScrollTrayController : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate, swypContentDisplayViewController> {
	NSMutableDictionary	*	_cachedPageObjectSetsForTray;
	
	NSMutableSet		*	_unusedUIImageViewSet;
	
	UIScrollView *			_trayScrollView;
	CGSize					_pageImageSize;
	float					_pageSpacingWidth;
	
	CGPoint					_fadeoutOrigin;
	CGPoint					_displayOrigin;
	
	
	id<swypContentDisplayViewControllerDelegate>	_contentDisplayControllerDelegate;	
}
@property (nonatomic, assign) CGSize			pageImageSize;
@property (nonatomic, assign) float				pageSpacingWidth;
@property (nonatomic, assign)	NSInteger			currentSelectedPageIndex;
@property (nonatomic, assign)	CGPoint fadeoutOrigin;
@property (nonatomic, assign)	CGPoint displayOrigin;
@property (nonatomic, readonly)	UIScrollView *		trayScrollView;


-(void)displayAtPoint:(CGPoint)point inView:(UIView*)displayView belowView:(UIView*)below animated:(BOOL)animate;
-(void)hideFromDisplayAndAnimated:(BOOL)animate;	
-(BOOL)isDisplayed;



//touch rec
-(void)		handleLongPressGesture:(UILongPressGestureRecognizer*)	recognizer;

//optimization
-(void)releaseImageViewFromUseWithObjectSet:(trayPageObjectSet*)objectSet;
-(UIImageView*)imageViewForObjectSet:(trayPageObjectSet*)pageSet;


-(void)	gigglePageAtIndex:(NSInteger)displayedPage;

//updating displayed data
//1) delete from datasource 2) call removeNotebookFromDisplay
-(void)	removePageFromDisplayAtIndex:(NSInteger)displayedPage animated:(BOOL)animate;
//1) add to datasource 2) call insertNotebookToDisplayAtIndex
-(void)	insertPageToDisplayAtIndex:(NSInteger)insertIndex animated:(BOOL)animate;

-(void)			reloadTrayPageImageData;
//updates page image, refreshes all around it
-(void)			updatePageAtIndex:(NSInteger)pageIndex;
//refreshes currently selected pages
-(void)			refreshPageSelection;
//dumps everything and reloads
-(void)		reloadAllData;


-(void)			scrollToRevealCurrentlySelectedPage;
-(void)			scrollToRevealPageAtIndex:(NSInteger)pageIndex;


-(trayPageObjectSet *)			layoutPageImageAtIndex:(NSInteger)idx;
-(NSRange)		rangeOfPagesForContentFrame:(CGRect)	displayRect;
-(void)			setupLayoutForImagesInContentFrame:(CGRect)	displayRect;
-(void)			setupPageSelectionViewWidthWithPageCount:(NSUInteger)pageCount;
-(CGRect)		frameForPageImageAtIndex:(NSUInteger)pageIndex;
-(trayPageObjectSet*)		trayPageObjectSetForIndex:(NSInteger)pageIndex;
-(NSInteger)		pageObjectIndexOnTrayAtTapPoint:(CGPoint)tapPoint;

//-1	= not visible
//0		= first visible (even partially) notebook
//n		= the notebook on scroll view
//locations contain their immediate margins
-(NSInteger)		visiblePageLocationForPageIndex:(NSInteger)pageIndex;	
-(NSInteger)		insertIndexFromVisiblePageLocation:(NSInteger)visiblePageLocation;

-(id)initWithTrayDelegate:(id<swypContentScrollTrayControllerDelegate>)trayDelegate;


@end
