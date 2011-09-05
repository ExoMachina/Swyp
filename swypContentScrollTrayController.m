//
//  swypContentScrollTrayController.m
//  exoNotes
//
//  Created by Alexander List on 4/16/11.
//  Copyright 2011 exoMachina. All rights reserved.
//

#import "swypContentScrollTrayController.h"
#import <QuartzCore/QuartzCore.h>

@implementation trayPageObjectSet
@synthesize  pagePreviewImage = _pagePreviewImage, pagePreviewImageView= _pagePreviewImageView;
-(void)	dealloc{
	SRELS(_pagePreviewImage);
	SRELS(_pagePreviewImageView);
	[super dealloc];
} 
@end


@implementation swypContentScrollTrayController
@synthesize currentSelectedPageIndex =_currentSelectedPageIndex;
@synthesize pageImageSize = _pageImageSize, pageSpacingWidth = _pageSpacingWidth;
@synthesize fadeoutOrigin = _fadeoutOrigin, displayOrigin = _displayOrigin;
@synthesize trayScrollView = _trayScrollView;


#pragma mark -
#pragma mark contentDisplayViewController
-(void)	removeContentFromDisplayAtIndex:	(NSUInteger)removeIndex animated:(BOOL)animate{
	[self removeContentFromDisplayAtIndex:removeIndex animated:animate];
}
-(void)	insertContentToDisplayAtIndex:		(NSUInteger)insertIndex animated:(BOOL)animate{
	[self insertPageToDisplayAtIndex:insertIndex animated:animate];
}

-(void)	setContentDisplayControllerDelegate: (id<swypContentDisplayViewControllerDelegate>)contentDisplayControllerDelegate{
	_contentDisplayControllerDelegate = contentDisplayControllerDelegate;
}
-(id<swypContentDisplayViewControllerDelegate>)	contentDisplayControllerDelegate{
	return _contentDisplayControllerDelegate;
}

-(void)	temporarilyExagerateContentAtIndex:	(NSUInteger)index{
	[self gigglePageAtIndex:index];
}
-(void)	returnContentAtIndexToNormalLocation:	(NSUInteger)index	animated:(BOOL)animate{
	if (animate){
		[UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState animations:^{
			[[[self trayPageObjectSetForIndex:index] pagePreviewImageView] setFrame:[self frameForPageImageAtIndex:index]];
		}
						 completion:nil];
		
	}else{
		[[[self trayPageObjectSetForIndex:index] pagePreviewImageView] setFrame:[self frameForPageImageAtIndex:index]];
	}
}


#pragma mark - 
#pragma mark interactions

-(void)		handleLongPressGesture:(UILongPressGestureRecognizer*)	recognizer{
	
	if ([recognizer state] == UIGestureRecognizerStateBegan){
		
		NSInteger selectedSet	=	[self pageObjectIndexOnTrayAtTapPoint:[recognizer locationInView:self.view]];
		if (selectedSet < 0)
			return;
		
		UIMenuController * selectionMenu = [UIMenuController sharedMenuController];
		
		//		[self setViewIsSelected:TRUE];
		[self becomeFirstResponder];
	
		UIMenuItem *deleteItem = [[[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(deletePromptPressed:)] autorelease];
		UIMenuItem *duplicateItem = [[[UIMenuItem alloc] initWithTitle:@"Duplicate" action:@selector(duplicatePressed:)] autorelease];
		// memory leak warning, added autorelease
		
		//		UIMenuItem *exportItem = [[UIMenuItem alloc] initWithTitle:@"Export" action:@selector(exportPressed:)];
		//		UIMenuItem *shareItem = [[UIMenuItem alloc] initWithTitle:@"Email" action:@selector(sharePressed:)];
		
		
		[selectionMenu setMenuItems:[NSArray arrayWithObjects:deleteItem,duplicateItem,nil]];
		[selectionMenu setArrowDirection:UIMenuControllerArrowDown];
		
		
		CGRect targetRect = CGRectMake(10, 15, 25, 15);
		targetRect.origin = [recognizer locationInView:self.view];
		[selectionMenu setTargetRect:targetRect inView:self.view];
		[selectionMenu setMenuVisible:TRUE animated:TRUE];		
	}
}


-(void)		imagePreviewViewPressedWithTapController:(UITapGestureRecognizer*)recognizer{
	
	NSInteger selectedSet	=	[self pageObjectIndexOnTrayAtTapPoint:[recognizer locationInView:self.view]];
	
	[self temporarilyExagerateContentAtIndex:selectedSet];	
	
}

#pragma mark -
#pragma mark page insertions/deletions

//1) delete from datasource 2) call removePageFromDisplayAtIndex
-(void)	removePageFromDisplayAtIndex:(NSInteger)displayedPage animated:(BOOL)animate{
	NSNumber* displayedPageKey = [NSNumber numberWithInt:displayedPage]; 
	
	trayPageObjectSet* objectSetToRemove	= [_cachedPageObjectSetsForTray objectForKey:displayedPageKey];
	
	if ([[objectSetToRemove pagePreviewImageView] superview] == nil)
		return;

	UIView*	removedView			= [objectSetToRemove pagePreviewImageView];
	
	[UIView animateWithDuration:.3 delay:0 options:UIViewAnimationCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
		[removedView setAlpha:0];
	} completion:^(BOOL finnished){
		if (finnished){ 
			[removedView removeFromSuperview];
		}
	}];	
	
	[_cachedPageObjectSetsForTray removeObjectForKey:displayedPageKey];
	
	
 	NSSet * moveViewKeys = [_cachedPageObjectSetsForTray keysOfEntriesPassingTest:^
							  (id key, id obj, BOOL *stop) { 
								  if ([key intValue] > displayedPage)
									  return YES;
								  return NO;
							  }];
	
	//because otherwise you'll move the same pages multiple times -- there is no ordering guarantee with dictionaries 
	NSMutableDictionary * newIndexesAndKeys	=	[NSMutableDictionary dictionaryWithDictionary:_cachedPageObjectSetsForTray];
	[newIndexesAndKeys removeObjectsForKeys:[moveViewKeys allObjects]];
	
	for (NSNumber *moveViewIndexKey in moveViewKeys){
		trayPageObjectSet* nextPageObjectSet = [_cachedPageObjectSetsForTray objectForKey:moveViewIndexKey];
	
//		[newIndexesAndKeys removeObjectForKey:moveViewIndexKey];
		
		int nextPageIndex = [moveViewIndexKey intValue]; 
		[newIndexesAndKeys setObject:nextPageObjectSet forKey:[NSNumber numberWithInt:nextPageIndex -1]];
		
		UIView *moveView	= [nextPageObjectSet pagePreviewImageView];
		if (moveView != nil ){				
				CGRect	newMoveViewFrame = moveView.frame;
				newMoveViewFrame.origin.x -= (_pageImageSize.width + _pageSpacingWidth);
				
				[UIView animateWithDuration:.5 delay:.4 options:UIViewAnimationCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
					[moveView setFrame:newMoveViewFrame];
				} completion:nil];	
		}
		
	}
	
	SRELS(_cachedPageObjectSetsForTray);
	_cachedPageObjectSetsForTray = [newIndexesAndKeys retain];
	
	[self setupPageSelectionViewWidthWithPageCount:[_contentDisplayControllerDelegate totalContentCountInController:self]];
}

//1) add to datasource 2) call insertPageToDisplayAtIndex
-(void)	insertPageToDisplayAtIndex:(NSInteger)insertIndex animated:(BOOL)animate{
	
	NSSet * moveViewKeys = [_cachedPageObjectSetsForTray keysOfEntriesPassingTest:^
							(id key, id obj, BOOL *stop) { 
								if ([key intValue] >= insertIndex)
									return YES;
								return NO;
							}];
	
	//because otherwise you'll move the same pages multiple times -- there is no ordering guarantee with dictionaries 
	NSMutableDictionary * newIndexesAndKeys	=	[NSMutableDictionary dictionaryWithDictionary:_cachedPageObjectSetsForTray];
	[newIndexesAndKeys removeObjectsForKeys:[moveViewKeys allObjects]];
	
	for (NSNumber *moveViewIndexKey in moveViewKeys){
		trayPageObjectSet* nextPageObjectSet = [_cachedPageObjectSetsForTray objectForKey:moveViewIndexKey];
		
		//		[newIndexesAndKeys removeObjectForKey:moveViewIndexKey];
		
		int nextPageIndex = [moveViewIndexKey intValue]; 
		[newIndexesAndKeys setObject:nextPageObjectSet forKey:[NSNumber numberWithInt:nextPageIndex +1]];
		
		UIView *moveView	= [nextPageObjectSet pagePreviewImageView];
		if (moveView != nil ){				
			CGRect	newMoveViewFrame = moveView.frame;
			newMoveViewFrame.origin.x += (_pageImageSize.width + _pageSpacingWidth);
			
			[UIView animateWithDuration:.3 delay:0 options:UIViewAnimationCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
				[moveView setFrame:newMoveViewFrame];
			} completion:nil];	
		}
		
	}
	
	SRELS(_cachedPageObjectSetsForTray);
	_cachedPageObjectSetsForTray = [newIndexesAndKeys retain];
	
	trayPageObjectSet * insertSet  = [self layoutPageImageAtIndex:insertIndex];
	
	[insertSet.pagePreviewImageView setAlpha:0];
	[UIView animateWithDuration:.5 delay:.4 options:UIViewAnimationCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
		[insertSet.pagePreviewImageView setAlpha:1];
	} completion:^(BOOL finnished){
		if (finnished){ } }];	
		
	[self setupPageSelectionViewWidthWithPageCount:[_contentDisplayControllerDelegate totalContentCountInController:self]];
}

-(void)	gigglePageAtIndex:(NSInteger)displayedPage{
	NSNumber* displayedPageKey = [NSNumber numberWithInt:displayedPage]; 
	
	trayPageObjectSet* objectSetToGiggle	= [_cachedPageObjectSetsForTray objectForKey:displayedPageKey];
	
	if ([[objectSetToGiggle pagePreviewImageView] superview] == nil)
		return;
	
	UIView*	giggleView			= [objectSetToGiggle pagePreviewImageView];
	
	BOOL originMode = FALSE;
	
	if (originMode){
		CGPoint preGiggleOrigin					= [giggleView origin];
		[UIView animateWithDuration:.1 delay:0 options:UIViewAnimationCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
			CGPoint giggleRightPoint		=	preGiggleOrigin;
			giggleRightPoint.x  += 20;
			[giggleView setOrigin:giggleRightPoint];
						
		} completion:^(BOOL finnished){
			[UIView animateWithDuration:.1 delay:0 options:UIViewAnimationCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
				CGPoint giggleLeftPoint		=	preGiggleOrigin;
				giggleLeftPoint.x  -= 20;
				[giggleView setOrigin:giggleLeftPoint];
				
			} completion:^(BOOL finnished){
				[UIView animateWithDuration:.1 delay:0 options:UIViewAnimationCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
					[giggleView setOrigin:preGiggleOrigin];
				} completion:^(BOOL finnished){}];				
			}];	
		}];	
		
	}else {
		CGAffineTransform preGiggleTransform	= [giggleView.layer affineTransform];
		[UIView animateWithDuration:.1 delay:0 options:UIViewAnimationCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
			
			CGAffineTransform giggleRightTransform	= CGAffineTransformRotate(preGiggleTransform, 3.1415/16);
			[giggleView.layer setAffineTransform:giggleRightTransform];
			
		} completion:^(BOOL finnished){
			[UIView animateWithDuration:.1 delay:0 options:UIViewAnimationCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
				CGAffineTransform giggleLeftTransform	= CGAffineTransformRotate(preGiggleTransform, -3.1415/16);
				[giggleView.layer setAffineTransform:giggleLeftTransform];
				
			} completion:^(BOOL finnished){
				[UIView animateWithDuration:.1 delay:0 options:UIViewAnimationCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
					[giggleView.layer setAffineTransform:preGiggleTransform];
				} completion:^(BOOL finnished){}];				
			}];	
		}];			
	}
		
}

#pragma mark page layouts

-(void)		reloadAllData{
	
	NSArray * trayPages = [_cachedPageObjectSetsForTray allValues];
	for (trayPageObjectSet* objectSet in trayPages){
		[[objectSet pagePreviewImageView] removeFromSuperview];
		[objectSet setPagePreviewImageView:nil];
		[objectSet setPagePreviewImage:nil];
	}
	
	[_cachedPageObjectSetsForTray removeAllObjects];
	
	CGRect displayedFrame		=	_trayScrollView.frame;
	displayedFrame.origin		=	_trayScrollView.contentOffset;
	[self setupPageSelectionViewWidthWithPageCount:[_contentDisplayControllerDelegate totalContentCountInController:self]];
	[self setupLayoutForImagesInContentFrame:displayedFrame];	
	
}

-(void)			refreshPageSelection{
	CGRect displayedFrame		=	_trayScrollView.frame;
	displayedFrame.origin		=	_trayScrollView.contentOffset;
	[self setupLayoutForImagesInContentFrame:displayedFrame];			
}

-(void)			updatePageAtIndex:(NSInteger)pageIndex{
	trayPageObjectSet* traySet = [self trayPageObjectSetForIndex:pageIndex];
	[traySet setPagePreviewImage:nil];
	
	CGRect displayedFrame		=	_trayScrollView.frame;
	displayedFrame.origin		=	_trayScrollView.contentOffset;
	[self setupLayoutForImagesInContentFrame:displayedFrame];		
}

-(void)		reloadTrayPageImageData{
	CGRect displayedFrame		=	_trayScrollView.frame;
	displayedFrame.origin		=	_trayScrollView.contentOffset;
	[self setupPageSelectionViewWidthWithPageCount:[_contentDisplayControllerDelegate totalContentCountInController:self]];
	[self setupLayoutForImagesInContentFrame:displayedFrame];	
}

-(trayPageObjectSet*)	trayPageObjectSetForIndex:(NSInteger)pageIndex{
	id	key		=	[NSNumber numberWithInt:pageIndex];
	trayPageObjectSet* objectSet	=	[_cachedPageObjectSetsForTray objectForKey:key];
	
	if (objectSet == nil){
		objectSet	=	[[trayPageObjectSet alloc] init];
		[_cachedPageObjectSetsForTray setObject:objectSet forKey:key];
		[objectSet autorelease];
	}
	
	return objectSet;
}

-(void)			scrollToRevealPageAtIndex:(NSInteger)pageIndex{
	CGRect		selectedRect		=	[self	frameForPageImageAtIndex:pageIndex];
	
	[_trayScrollView	scrollRectToVisible:selectedRect animated:(self.view.superview != nil)];
	
}

-(void)releaseImageViewFromUseWithObjectSet:(trayPageObjectSet*)objectSet{
	UIImageView	* imageView = [objectSet pagePreviewImageView];
	
	if (imageView == nil)
		return;
	
	[_unusedUIImageViewSet addObject:imageView];
	[imageView removeFromSuperview];
	[objectSet setPagePreviewImageView:nil];
}

-(UIImageView*)imageViewForObjectSet:(trayPageObjectSet*)pageSet{
	UIImageView	* imageView = [_unusedUIImageViewSet anyObject];
	if (imageView == nil){
		imageView = [[[UIImageView alloc] initWithFrame:CGRectZero] autorelease]; // memory leak warning, added autorelease
		[imageView setBackgroundColor:[UIColor blackColor]];
		[imageView setUserInteractionEnabled:TRUE];
		[imageView.layer setMasksToBounds:TRUE];
		[imageView.layer setCornerRadius:3];
		[imageView.layer setBorderWidth:2];	
	}
	
	[pageSet setPagePreviewImageView:imageView];

	[_unusedUIImageViewSet removeObject:imageView];
	
	return imageView;
}

-(trayPageObjectSet *)			layoutPageImageAtIndex:(NSInteger)idx{
	
	trayPageObjectSet *		pageViewSet	=	[self trayPageObjectSetForIndex:idx];
	if ([pageViewSet pagePreviewImageView] == nil){		
		UIImageView *previewImageView =  [self imageViewForObjectSet:pageViewSet];
		CGRect	nextFrame		=	[self frameForPageImageAtIndex:idx];
		[previewImageView setFrame:nextFrame];

		[pageViewSet setPagePreviewImageView:previewImageView]; 
		
		[_trayScrollView addSubview:[pageViewSet pagePreviewImageView]];				
		
	}
	
	if (![[pageViewSet pagePreviewImageView] isDescendantOfView:_trayScrollView]){
		[_trayScrollView addSubview:[pageViewSet pagePreviewImageView]];				
		//only setting frame as necessary
		CGRect	nextFrame		=	[self frameForPageImageAtIndex:idx];
		[[pageViewSet pagePreviewImageView] setFrame:nextFrame];
	}
	
	
	if ([pageViewSet pagePreviewImage] == nil){
		UIImage * pageImagePreview	=	[_contentDisplayControllerDelegate imageForContentAtIndex:idx inController:self];
		[pageViewSet setPagePreviewImage:pageImagePreview];
	}		
	[[pageViewSet pagePreviewImageView] setImage:[pageViewSet pagePreviewImage]];
	
	return pageViewSet;
}

-(void)			setupLayoutForImagesInContentFrame:(CGRect)	displayRect{
	NSRange		layoutRange		=	[self rangeOfPagesForContentFrame:displayRect];
	
	double minLoc = (double)layoutRange.location - 2.0;
	NSRange preRelevanceRange = NSMakeRange(MAX(0, minLoc), 2);
	preRelevanceRange = NSIntersectionRange(preRelevanceRange, NSMakeRange(0, [_contentDisplayControllerDelegate totalContentCountInController:self]));

	NSRange postRelevanceRange = NSMakeRange(layoutRange.location + layoutRange.length, 2);
	postRelevanceRange = NSIntersectionRange(postRelevanceRange, NSMakeRange(0, [_contentDisplayControllerDelegate totalContentCountInController:self]));

	
	NSMutableIndexSet* viewRemoveKeys = [NSMutableIndexSet indexSetWithIndexesInRange:preRelevanceRange];
	[viewRemoveKeys addIndexesInRange:postRelevanceRange];
	[viewRemoveKeys removeIndexesInRange:layoutRange];
	
	[viewRemoveKeys enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
		trayPageObjectSet *		removeSet	=	[self trayPageObjectSetForIndex:idx];
		[self releaseImageViewFromUseWithObjectSet:removeSet];		
	}];
	
	
	
	NSIndexSet *layoutIndexSet	=	[NSIndexSet indexSetWithIndexesInRange:layoutRange];
	[layoutIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
		[self layoutPageImageAtIndex:idx];
	}];
	
	
}

//-1	= not visible
//0		= first visible (even partially) notebook
//n		= the notebook on scroll view
//locations contain their immediate margins
-(NSInteger)		visiblePageLocationForPageIndex:(NSInteger)pageIndex{
	CGRect displayedFrame			=	_trayScrollView.frame;
	displayedFrame.origin			=	_trayScrollView.contentOffset;
	
	CGRect	indexDisplayedRect		=	[self frameForPageImageAtIndex:pageIndex];

	double	notebookFrameXInset		=	(indexDisplayedRect.origin.x ) - displayedFrame.origin.x;

	
	double	containedLocation		=	(notebookFrameXInset )/ (_pageImageSize.width + _pageSpacingWidth); 
	
	int		location				=	(int) ceil( containedLocation);
	if (location <= -1)
		return -1;
	
	return location;
}

-(NSInteger)		insertIndexFromVisiblePageLocation:(NSInteger)visiblePageLocation{
	double		xPageOffset		=	_trayScrollView.contentOffset.x + (_pageImageSize.width + _pageSpacingWidth) * visiblePageLocation;
	
	double		pageIndex			=	(xPageOffset - _pageSpacingWidth)/ (_pageImageSize.width + _pageSpacingWidth);
	
	NSInteger	insertLocation		= MIN((int) ceil( pageIndex), [_contentDisplayControllerDelegate totalContentCountInController:self]);
	
	return insertLocation;
 }

-(NSInteger)		pageObjectIndexOnTrayAtTapPoint:(CGPoint)tapPoint{
	CGRect displayedFrame			=	_trayScrollView.frame;
	displayedFrame.origin			=	_trayScrollView.contentOffset;
	NSRange		touchSearchRange	=	[self rangeOfPagesForContentFrame:displayedFrame];
	CGPoint 	testPoint 			= 	tapPoint;
	testPoint.x += displayedFrame.origin.x;
	
	NSInteger	returnPIdx	=	-1;
	
	
	for (int i = touchSearchRange.location; i <= touchSearchRange.location +touchSearchRange.length; i ++){
		trayPageObjectSet *			testSet	=	[self trayPageObjectSetForIndex:i];
		CGRect					testSetFrame= [testSet pagePreviewImageView].frame;
		if (CGRectContainsPoint(testSetFrame, testPoint)){
			returnPIdx	= i; //starts at loc
			break;	
		}
	}
	
	return returnPIdx;
}

-(CGRect)		frameForPageImageAtIndex:(NSUInteger)pageIndex{
	CGRect	returnFrameRect		=	CGRectZero;
	returnFrameRect.origin.y	=	(_trayScrollView.frame.size.height-_pageImageSize.height)/2;
	returnFrameRect.origin.x	=	pageIndex * (_pageImageSize.width + _pageSpacingWidth) + _pageSpacingWidth;
	returnFrameRect.size		=	_pageImageSize;
	
	return returnFrameRect;
}

-(void)			setupPageSelectionViewWidthWithPageCount:(NSUInteger)pageCount{
	
	CGSize		resizedScrollViewSize					=	_trayScrollView.contentSize;
	
	resizedScrollViewSize.width		=	pageCount* (_pageImageSize.width + _pageSpacingWidth) + _pageSpacingWidth;
	
	_trayScrollView.contentSize	= resizedScrollViewSize;
}

-(NSRange)		rangeOfPagesForContentFrame:(CGRect)	displayRect{
	NSInteger startingIndex = MAX(0, floor(displayRect.origin.x / (_pageImageSize.width + _pageSpacingWidth)));
	NSInteger displayCount = ceil((displayRect.size.width + (_pageImageSize.width + _pageSpacingWidth))/ (_pageImageSize.width + _pageSpacingWidth));
	
	if (startingIndex >= [_contentDisplayControllerDelegate totalContentCountInController:self])
		return NSMakeRange(NSNotFound, 0);
	if (startingIndex + displayCount >= [_contentDisplayControllerDelegate totalContentCountInController:self])
		displayCount = [_contentDisplayControllerDelegate totalContentCountInController:self] - startingIndex;
	
	return NSMakeRange(startingIndex, displayCount);
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
	CGRect displayedFrame		=	_trayScrollView.frame;
	displayedFrame.origin		=	_trayScrollView.contentOffset;
	[self setupLayoutForImagesInContentFrame:displayedFrame];		
}


#pragma mark -
#pragma mark NSObject
-(id)init{
	if ((self = [super initWithNibName:nil bundle:nil])){
		
		_cachedPageObjectSetsForTray	= [[NSMutableDictionary alloc] init];
		_unusedUIImageViewSet			= [[NSMutableSet	alloc]	init];
		
		_trayScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, 1024.0, 175.0)];
		[_trayScrollView setDelegate:self];
		
		_pageImageSize		=	CGSizeMake(212, 137);
		_pageSpacingWidth	=	35;
		
		_fadeoutOrigin		=	CGPointMake(0, 728);
		_displayOrigin		=	CGPointMake(0, _fadeoutOrigin.y - _trayScrollView.size.height);
		
	}
	return self;
}

- (void)dealloc {
	_contentDisplayControllerDelegate = nil;
	
	SRELS(_unusedUIImageViewSet);
	SRELS(_trayScrollView);
	SRELS(_cachedPageObjectSetsForTray);
	
	[super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	UIView *mainView = self.view;
	mainView.frame = CGRectMake(0.0, 0.0, 1024.0, 175.0);
	mainView.alpha = 1.000;
	mainView.autoresizesSubviews = YES;
	mainView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
	mainView.backgroundColor = [UIColor colorWithWhite:0.318 alpha:1.000];
	[mainView setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]]; 
	mainView.clearsContextBeforeDrawing = YES;
	mainView.clipsToBounds = NO;
	mainView.contentMode = UIViewContentModeScaleToFill;
	mainView.contentStretch = CGRectFromString(@"{{0, 0}, {1, 1}}");
	mainView.hidden = NO;
	mainView.multipleTouchEnabled = NO;
	mainView.opaque = YES;
	mainView.tag = 0;
	mainView.userInteractionEnabled = YES;
	
	
	
	
	_trayScrollView.frame = CGRectMake(0.0, 0.0, 1024.0, 175.0);
	_trayScrollView.alpha = 1.000;
	_trayScrollView.alwaysBounceHorizontal = YES;
	_trayScrollView.alwaysBounceVertical = NO;
	_trayScrollView.autoresizesSubviews = YES;
	_trayScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_trayScrollView.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.000];
	_trayScrollView.bounces = YES;
	_trayScrollView.bouncesZoom = NO;
	_trayScrollView.canCancelContentTouches = YES;
	_trayScrollView.clearsContextBeforeDrawing = YES;
	_trayScrollView.clipsToBounds = YES;
	_trayScrollView.contentMode = UIViewContentModeScaleToFill;
	_trayScrollView.contentStretch = CGRectFromString(@"{{0, 0}, {1, 1}}");
	_trayScrollView.delaysContentTouches = YES;
	_trayScrollView.directionalLockEnabled = NO;
	_trayScrollView.hidden = NO;
	_trayScrollView.indicatorStyle = UIScrollViewIndicatorStyleDefault;
	_trayScrollView.maximumZoomScale = 1.000;
	_trayScrollView.minimumZoomScale = 1.000;
	_trayScrollView.multipleTouchEnabled = YES;
	_trayScrollView.opaque = YES;
	_trayScrollView.pagingEnabled = FALSE;
	_trayScrollView.scrollEnabled = YES;
	_trayScrollView.showsHorizontalScrollIndicator = NO;
	_trayScrollView.showsVerticalScrollIndicator = NO;
	_trayScrollView.tag = 0;
	_trayScrollView.userInteractionEnabled = YES;
	[_trayScrollView setContentSize:CGSizeMake(2048, 175)];
	[_trayScrollView setDecelerationRate:UIScrollViewDecelerationRateFast];
	[_trayScrollView	setShowsHorizontalScrollIndicator:TRUE];
	[_trayScrollView	setIndicatorStyle:UIScrollViewIndicatorStyleWhite];
	
	
	[mainView addSubview:_trayScrollView];
    
	
	UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
	[mainView addGestureRecognizer:longPressGesture];
	SRELS(longPressGesture);

	
	//handle in subclassing 
	/*
	// detects swipe up to activate clipboard
	UISwipeGestureRecognizer *upGesture = [[ UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(imagePreviewViewSwipedUpController:)];
	[upGesture setDirection:UISwipeGestureRecognizerDirectionUp];
	[mainView addGestureRecognizer:upGesture];
	SRELS(upGesture);
	
	UISwipeGestureRecognizer *downGesture = [[ UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(imagePreviewViewSwipedDownController:)];
	[downGesture setDirection:UISwipeGestureRecognizerDirectionDown];
	[mainView addGestureRecognizer:downGesture];
	SRELS(downGesture);
	*/
	
	UITapGestureRecognizer *tapGesture = [[ UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imagePreviewViewPressedWithTapController:)];
	[mainView addGestureRecognizer:tapGesture];
	SRELS(tapGesture);
	
	
	
	CGRect displayedFrame		=	_trayScrollView.frame;
	displayedFrame.origin		=	_trayScrollView.contentOffset;
	[self setupPageSelectionViewWidthWithPageCount:[_contentDisplayControllerDelegate totalContentCountInController:self]];
	[self setupLayoutForImagesInContentFrame:displayedFrame];
	
	
	
	[self.view setOrigin:_fadeoutOrigin];
	
}
//
//- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
//    // Return YES for supported orientations.
//    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
//}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}



#pragma mark display

-(BOOL)isDisplayed{
	return (self.view.superview != nil && CGPointEqualToPoint(_displayOrigin, self.view.frame.origin));
}

-(void)displayAtPoint:(CGPoint)point inView:(UIView*)displayView belowView:(UIView*)below animated:(BOOL)animate{

	if ([self isDisplayed])
		return;
	
	[displayView insertSubview:self.view belowSubview:below];

	if (animate){
		[self.view.layer setShouldRasterize:TRUE];
		[UIView animateWithDuration:.5 delay:0 options:UIViewAnimationCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction animations:^{
			[self.view setOrigin:_displayOrigin];
		} completion:^(BOOL finnished){
			[self.view.layer setShouldRasterize:FALSE];

		}];
	}else {
		[self.view setOrigin:_displayOrigin];
	}	
}
-(void)hideFromDisplayAndAnimated:(BOOL)animate{
	
	[self resignFirstResponder];
	
	if (animate){
		[self.view.layer setShouldRasterize:TRUE];		
		[UIView animateWithDuration:.5 delay:0 options:UIViewAnimationCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
			[self.view setOrigin:_fadeoutOrigin];
		} completion:^(BOOL finnished){
			if (finnished){ //how to get this to actuall work? Who knows-- not most important thing now though, I guess. 
				[self.view removeFromSuperview];
				[self.view.layer setShouldRasterize:FALSE];
			}
		}];	
		
	}else {
		[self.view setOrigin:_fadeoutOrigin];
		[self.view removeFromSuperview];
	}		
	
}
@end
