//
//  swypContentScrollTrayController.m
//  exoNotes
//
//  Created by Alexander List on 4/16/11.
//  Copyright 2011 exoMachina. All rights reserved.
//

#import "swypContentScrollTrayController.h"
#import <QuartzCore/QuartzCore.h>

@implementation trayContentObjectSet
@synthesize  contentPreviewImage = _contentPreviewImage, contentPreviewImageView= _contentPreviewImageView;
-(void)	dealloc{
	SRELS(_contentPreviewImage);
	SRELS(_contentPreviewImageView);
	[super dealloc];
} 
@end


@implementation swypContentScrollTrayController
@synthesize currentSelectedContentIndex =_currentSelectedContentIndex;
@synthesize contentImageSize = _contentImageSize, contentSpacingWidth = _contentSpacingWidth;
@synthesize fadeoutOrigin = _fadeoutOrigin, displayOrigin = _displayOrigin;
@synthesize trayScrollView = _trayScrollView;


#pragma mark -
#pragma mark contentDisplayViewController
-(void)	removeContentFromDisplayAtIndex:	(NSUInteger)removeIndex animated:(BOOL)animate{
	[self removeScrollPageContentFromDisplayAtIndex:removeIndex animated:animate];
}
-(void)	insertContentToDisplayAtIndex:		(NSUInteger)insertIndex animated:(BOOL)animate  fromStartLocation:(CGPoint)startLocation{ 
	[self insertScrollPageContentToDisplayAtIndex:insertIndex animated:animate];
}

-(void)	setContentDisplayControllerDelegate: (id<swypContentDisplayViewControllerDelegate>)contentDisplayControllerDelegate{
	_contentDisplayControllerDelegate = contentDisplayControllerDelegate;
}
-(id<swypContentDisplayViewControllerDelegate>)	contentDisplayControllerDelegate{
	return _contentDisplayControllerDelegate;
}

-(void)		reloadAllData{
	
	NSArray * trayContents = [_cachedContentObjectSetsForTray allValues];
	for (trayContentObjectSet* objectSet in trayContents){
		[[objectSet contentPreviewImageView] removeFromSuperview];
		[objectSet setContentPreviewImageView:nil];
		[objectSet setContentPreviewImage:nil];
	}
	
	[_cachedContentObjectSetsForTray removeAllObjects];
	
	CGRect displayedFrame		=	_trayScrollView.frame;
	displayedFrame.origin		=	_trayScrollView.contentOffset;
	[self setupContentSelectionViewWidthWithContentCount:[_contentDisplayControllerDelegate totalContentCountInController:self]];
	[self setupLayoutForImagesInContentFrame:displayedFrame];	
	
}


-(void)	temporarilyExagerateContentAtIndex:	(NSUInteger)index{
	[self giggleContentAtIndex:index];
}
-(void)	returnContentAtIndexToNormalLocation:	(NSInteger)index	animated:(BOOL)animate{
	if (animate){
		[UIView animateWithDuration:.75 delay:0 options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction animations:^{
			if (index == -1){
				for (int i = 0; i < [_contentDisplayControllerDelegate totalContentCountInController:self]; i++){
					[[[self trayContentObjectSetForIndex:i] contentPreviewImageView] setFrame:[self frameForContentImageAtIndex:i]];	
				}
				
			}else{
				[[[self trayContentObjectSetForIndex:index] contentPreviewImageView] setFrame:[self frameForContentImageAtIndex:index]];	
			}
		}
						 completion:nil];
		
	}else{
		if (index == -1){
			for (int i = 0; i < [_contentDisplayControllerDelegate totalContentCountInController:self]; i++){
				[[[self trayContentObjectSetForIndex:i] contentPreviewImageView] setFrame:[self frameForContentImageAtIndex:i]];	
			}
		}else{
			[[[self trayContentObjectSetForIndex:index] contentPreviewImageView] setFrame:[self frameForContentImageAtIndex:index]];			
		}
	}
}


#pragma mark - 
#pragma mark gestures
-(void)		contentPanOccuredWithRecognizer: (UIPanGestureRecognizer*) recognizer{

	if ([recognizer state] == UIGestureRecognizerStateBegan){

	}else if ([recognizer state] == UIGestureRecognizerStateChanged){
		[[recognizer view] setFrame:CGRectApplyAffineTransform([[recognizer view] frame], CGAffineTransformMakeTranslation([recognizer translationInView:self.view].x, [recognizer translationInView:self.view].y))];
		[recognizer setTranslation:CGPointZero inView:self.view];
		
		NSInteger pannedIndex	= [self indexOfTrayObjectWithAssociatedPreviewImageView:(UIImageView*)recognizer.view];
		if (pannedIndex != -1){
			[_contentDisplayControllerDelegate contentAtIndex:pannedIndex wasDraggedToFrame:CGRectApplyAffineTransform([recognizer.view frame],CGAffineTransformMakeTranslation(-1 * _trayScrollView.contentOffset.x, -1 * _trayScrollView.contentOffset.y)) inController:self];
		}
		
	}else if ([recognizer state] == UIGestureRecognizerStateEnded || [recognizer state] == UIGestureRecognizerStateFailed || [recognizer state] == UIGestureRecognizerStateCancelled){
		
		NSInteger pannedIndex	= [self indexOfTrayObjectWithAssociatedPreviewImageView:(UIImageView*)recognizer.view];
		if (pannedIndex != -1){
			[_contentDisplayControllerDelegate contentAtIndex:pannedIndex wasReleasedWithFrame:CGRectApplyAffineTransform([recognizer.view frame],CGAffineTransformMakeTranslation(-1 * _trayScrollView.contentOffset.x, -1 * _trayScrollView.contentOffset.y)) inController:self];
		}
	}
}

-(void)		imagePreviewViewPressedWithTapController:(UITapGestureRecognizer*)recognizer{
	
	NSInteger selectedSet	=	[self contentObjectIndexOnTrayAtTapPoint:[recognizer locationInView:self.view]];
	
	[self temporarilyExagerateContentAtIndex:selectedSet];	
	
}

#pragma mark -
#pragma mark content insertions/deletions

//1) delete from datasource 2) call removeContentFromDisplayAtIndex
-(void)	removeScrollPageContentFromDisplayAtIndex:(NSInteger)displayedContent animated:(BOOL)animate{
	NSNumber* displayedContentKey = [NSNumber numberWithInt:displayedContent]; 
	
	trayContentObjectSet* objectSetToRemove	= [_cachedContentObjectSetsForTray objectForKey:displayedContentKey];
	
	if ([[objectSetToRemove contentPreviewImageView] superview] == nil)
		return;

	UIView*	removedView			= [objectSetToRemove contentPreviewImageView];
	
	[UIView animateWithDuration:.3 delay:0 options:UIViewAnimationCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
		[removedView setAlpha:0];
	} completion:^(BOOL finnished){
		if (finnished){ 
			[removedView removeFromSuperview];
		}
	}];	
	
	[_cachedContentObjectSetsForTray removeObjectForKey:displayedContentKey];
	
	
 	NSSet * moveViewKeys = [_cachedContentObjectSetsForTray keysOfEntriesPassingTest:^
							  (id key, id obj, BOOL *stop) { 
								  if ([key intValue] > displayedContent)
									  return YES;
								  return NO;
							  }];
	
	//because otherwise you'll move the same contents multiple times -- there is no ordering guarantee with dictionaries 
	NSMutableDictionary * newIndexesAndKeys	=	[NSMutableDictionary dictionaryWithDictionary:_cachedContentObjectSetsForTray];
	[newIndexesAndKeys removeObjectsForKeys:[moveViewKeys allObjects]];
	
	for (NSNumber *moveViewIndexKey in moveViewKeys){
		trayContentObjectSet* nextContentObjectSet = [_cachedContentObjectSetsForTray objectForKey:moveViewIndexKey];
	
//		[newIndexesAndKeys removeObjectForKey:moveViewIndexKey];
		
		int nextContentIndex = [moveViewIndexKey intValue]; 
		[newIndexesAndKeys setObject:nextContentObjectSet forKey:[NSNumber numberWithInt:nextContentIndex -1]];
		
		UIView *moveView	= [nextContentObjectSet contentPreviewImageView];
		if (moveView != nil ){				
				CGRect	newMoveViewFrame = moveView.frame;
				newMoveViewFrame.origin.x -= (_contentImageSize.width + _contentSpacingWidth);
				
				[UIView animateWithDuration:.5 delay:.4 options:UIViewAnimationCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
					[moveView setFrame:newMoveViewFrame];
				} completion:nil];	
		}
		
	}
	
	SRELS(_cachedContentObjectSetsForTray);
	_cachedContentObjectSetsForTray = [newIndexesAndKeys retain];
	
	[self setupContentSelectionViewWidthWithContentCount:[_contentDisplayControllerDelegate totalContentCountInController:self]];
}

//1) add to datasource 2) call insertContentToDisplayAtIndex
-(void)	insertScrollPageContentToDisplayAtIndex:(NSInteger)insertIndex animated:(BOOL)animate{
	
	NSSet * moveViewKeys = [_cachedContentObjectSetsForTray keysOfEntriesPassingTest:^
							(id key, id obj, BOOL *stop) { 
								if ([key intValue] >= insertIndex)
									return YES;
								return NO;
							}];
	
	//because otherwise you'll move the same contents multiple times -- there is no ordering guarantee with dictionaries 
	NSMutableDictionary * newIndexesAndKeys	=	[NSMutableDictionary dictionaryWithDictionary:_cachedContentObjectSetsForTray];
	[newIndexesAndKeys removeObjectsForKeys:[moveViewKeys allObjects]];
	
	for (NSNumber *moveViewIndexKey in moveViewKeys){
		trayContentObjectSet* nextContentObjectSet = [_cachedContentObjectSetsForTray objectForKey:moveViewIndexKey];
		
		//		[newIndexesAndKeys removeObjectForKey:moveViewIndexKey];
		
		int nextContentIndex = [moveViewIndexKey intValue]; 
		[newIndexesAndKeys setObject:nextContentObjectSet forKey:[NSNumber numberWithInt:nextContentIndex +1]];
		
		UIView *moveView	= [nextContentObjectSet contentPreviewImageView];
		if (moveView != nil ){				
			CGRect	newMoveViewFrame = moveView.frame;
			newMoveViewFrame.origin.x += (_contentImageSize.width + _contentSpacingWidth);
			
			[UIView animateWithDuration:.3 delay:0 options:UIViewAnimationCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
				[moveView setFrame:newMoveViewFrame];
			} completion:nil];	
		}
		
	}
	
	SRELS(_cachedContentObjectSetsForTray);
	_cachedContentObjectSetsForTray = [newIndexesAndKeys retain];
	
	trayContentObjectSet * insertSet  = [self layoutContentImageAtIndex:insertIndex];
	
	[insertSet.contentPreviewImageView setAlpha:0];
	[UIView animateWithDuration:.5 delay:.4 options:UIViewAnimationCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState animations:^{
		[insertSet.contentPreviewImageView setAlpha:1];
	} completion:^(BOOL finnished){
		if (finnished){ } }];	
		
	[self setupContentSelectionViewWidthWithContentCount:[_contentDisplayControllerDelegate totalContentCountInController:self]];
}

-(void)	giggleContentAtIndex:(NSInteger)displayedContent{
	NSNumber* displayedContentKey = [NSNumber numberWithInt:displayedContent]; 
	
	trayContentObjectSet* objectSetToGiggle	= [_cachedContentObjectSetsForTray objectForKey:displayedContentKey];
	
	if ([[objectSetToGiggle contentPreviewImageView] superview] == nil)
		return;
	
	UIView*	giggleView			= [objectSetToGiggle contentPreviewImageView];
	
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

#pragma mark content layouts

-(void)			refreshContentSelection{
	CGRect displayedFrame		=	_trayScrollView.frame;
	displayedFrame.origin		=	_trayScrollView.contentOffset;
	[self setupLayoutForImagesInContentFrame:displayedFrame];			
}

-(void)			updateContentAtIndex:(NSInteger)contentIndex{
	trayContentObjectSet* traySet = [self trayContentObjectSetForIndex:contentIndex];
	[traySet setContentPreviewImage:nil];
	
	CGRect displayedFrame		=	_trayScrollView.frame;
	displayedFrame.origin		=	_trayScrollView.contentOffset;
	[self setupLayoutForImagesInContentFrame:displayedFrame];		
}

-(void)		reloadTrayContentImageData{
	CGRect displayedFrame		=	_trayScrollView.frame;
	displayedFrame.origin		=	_trayScrollView.contentOffset;
	[self setupContentSelectionViewWidthWithContentCount:[_contentDisplayControllerDelegate totalContentCountInController:self]];
	[self setupLayoutForImagesInContentFrame:displayedFrame];	
}

-(trayContentObjectSet*)	trayContentObjectSetForIndex:(NSInteger)contentIndex{
	id	key		=	[NSNumber numberWithInt:contentIndex];
	trayContentObjectSet* objectSet	=	[_cachedContentObjectSetsForTray objectForKey:key];

	if (objectSet == nil){
		objectSet	=	[[trayContentObjectSet alloc] init];
		[_cachedContentObjectSetsForTray setObject:objectSet forKey:key];
		[objectSet autorelease];
	}
	
	return objectSet;
}

-(void)			scrollToRevealContentAtIndex:(NSInteger)contentIndex{
	CGRect		selectedRect		=	[self	frameForContentImageAtIndex:contentIndex];
	
	[_trayScrollView	scrollRectToVisible:selectedRect animated:(self.view.superview != nil)];
	
}

-(void)releaseImageViewFromUseWithObjectSet:(trayContentObjectSet*)objectSet{
	UIImageView	* imageView = [objectSet contentPreviewImageView];
	
	if (imageView == nil)
		return;
	
	[_unusedUIImageViewSet addObject:imageView];
	[imageView removeFromSuperview];
	[objectSet setContentPreviewImageView:nil];
}

-(UIImageView*)imageViewForObjectSet:(trayContentObjectSet*)contentSet{
	UIImageView	* imageView = [_unusedUIImageViewSet anyObject];
	if (imageView == nil){
		imageView = [[[UIImageView alloc] initWithFrame:CGRectZero] autorelease]; // memory leak warning, added autorelease
		[imageView setBackgroundColor:[UIColor clearColor]];
		[imageView setUserInteractionEnabled:TRUE];
//		[imageView.layer setMasksToBounds:TRUE];
//		[imageView.layer setCornerRadius:3];
//		[imageView.layer setBorderWidth:2];	
		UIPanGestureRecognizer * panGesture	=	[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(contentPanOccuredWithRecognizer:)];
		[imageView addGestureRecognizer:panGesture];
		SRELS(panGesture);
	}
	
	[contentSet setContentPreviewImageView:imageView];

	[_unusedUIImageViewSet removeObject:imageView];
	
	return imageView;
}

-(trayContentObjectSet *)			layoutContentImageAtIndex:(NSInteger)idx{
	
	trayContentObjectSet *		contentViewSet	=	[self trayContentObjectSetForIndex:idx];
	if ([contentViewSet contentPreviewImageView] == nil){		
		UIImageView *previewImageView =  [self imageViewForObjectSet:contentViewSet];
		CGRect	nextFrame		=	[self frameForContentImageAtIndex:idx];
		[previewImageView setFrame:nextFrame];

		[contentViewSet setContentPreviewImageView:previewImageView]; 
		
		[_trayScrollView addSubview:[contentViewSet contentPreviewImageView]];				
		
	}
	
	if ([contentViewSet contentPreviewImage] == nil){
		UIImage * contentImagePreview	=	[_contentDisplayControllerDelegate imageForContentAtIndex:idx ofMaxSize:_contentImageSize inController:self];
		if (CGSizeEqualToSize([contentImagePreview size], _contentImageSize) == NO){
			_contentImageSize			=	[contentImagePreview size];
			self.view.size				=	CGSizeMake(self.view.frame.size.width, [contentImagePreview size].height + 60);
			_trayScrollView.size		=	self.view.size;
			_trayScrollView.contentSize	=	CGSizeMake(_trayScrollView.contentSize.width, _trayScrollView.frame.size.height);
			[[contentViewSet contentPreviewImageView] setFrame:[self frameForContentImageAtIndex:idx]];

		}
		[contentViewSet setContentPreviewImage:contentImagePreview];
	}		
	
	if (![[contentViewSet contentPreviewImageView] isDescendantOfView:_trayScrollView]){
		[_trayScrollView addSubview:[contentViewSet contentPreviewImageView]];				
		//only setting frame as necessary
		CGRect	nextFrame		=	[self frameForContentImageAtIndex:idx];
		[[contentViewSet contentPreviewImageView] setFrame:nextFrame];
	}
	
	
	[[contentViewSet contentPreviewImageView] setImage:[contentViewSet contentPreviewImage]];
	
	return contentViewSet;
}

-(void)			setupLayoutForImagesInContentFrame:(CGRect)	displayRect{
	NSRange		layoutRange		=	[self rangeOfContentsForContentFrame:displayRect];
	
	double minLoc = (double)layoutRange.location - 2.0;
	NSRange preRelevanceRange = NSMakeRange(MAX(0, minLoc), 2);
	preRelevanceRange = NSIntersectionRange(preRelevanceRange, NSMakeRange(0, [_contentDisplayControllerDelegate totalContentCountInController:self]));

	NSRange postRelevanceRange = NSMakeRange(layoutRange.location + layoutRange.length, 2);
	postRelevanceRange = NSIntersectionRange(postRelevanceRange, NSMakeRange(0, [_contentDisplayControllerDelegate totalContentCountInController:self]));

	
	NSMutableIndexSet* viewRemoveKeys = [NSMutableIndexSet indexSetWithIndexesInRange:preRelevanceRange];
	[viewRemoveKeys addIndexesInRange:postRelevanceRange];
	[viewRemoveKeys removeIndexesInRange:layoutRange];
	
	[viewRemoveKeys enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
		trayContentObjectSet *		removeSet	=	[self trayContentObjectSetForIndex:idx];
		[self releaseImageViewFromUseWithObjectSet:removeSet];		
	}];
	
	
	
	NSIndexSet *layoutIndexSet	=	[NSIndexSet indexSetWithIndexesInRange:layoutRange];
	[layoutIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
		[self layoutContentImageAtIndex:idx];
	}];
	
	
}

//-1	= not visible
//0		= first visible (even partially) notebook
//n		= the notebook on scroll view
//locations contain their immediate margins
-(NSInteger)		visibleContentLocationForContentIndex:(NSInteger)contentIndex{
	CGRect displayedFrame			=	_trayScrollView.frame;
	displayedFrame.origin			=	_trayScrollView.contentOffset;
	
	CGRect	indexDisplayedRect		=	[self frameForContentImageAtIndex:contentIndex];

	double	notebookFrameXInset		=	(indexDisplayedRect.origin.x ) - displayedFrame.origin.x;

	
	double	containedLocation		=	(notebookFrameXInset )/ (_contentImageSize.width + _contentSpacingWidth); 
	
	int		location				=	(int) ceil( containedLocation);
	if (location <= -1)
		return -1;
	
	return location;
}

-(NSInteger)		insertIndexFromVisibleContentLocation:(NSInteger)visibleContentLocation{
	double		xContentOffset		=	_trayScrollView.contentOffset.x + (_contentImageSize.width + _contentSpacingWidth) * visibleContentLocation;
	
	double		contentIndex			=	(xContentOffset - _contentSpacingWidth)/ (_contentImageSize.width + _contentSpacingWidth);
	
	NSInteger	insertLocation		= MIN((int) ceil( contentIndex), [_contentDisplayControllerDelegate totalContentCountInController:self]);
	
	return insertLocation;
 }

-(NSInteger)	indexOfTrayObjectWithAssociatedPreviewImageView: (UIImageView*) previewImageView{
	CGRect displayedFrame			=	_trayScrollView.frame;
	displayedFrame.origin			=	_trayScrollView.contentOffset;
	NSRange		primarySearchRange	=	[self rangeOfContentsForContentFrame:displayedFrame];
	for (int i = primarySearchRange.location; i <= primarySearchRange.location + primarySearchRange.length; i ++){
		trayContentObjectSet *	testSet	=	[self trayContentObjectSetForIndex:i];
		if ([testSet contentPreviewImageView] == previewImageView)
			return i;
	}
	
	//otherwise search the rest
	NSMutableIndexSet * otherContents	=	[NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [_contentDisplayControllerDelegate totalContentCountInController:self])];
	[otherContents removeIndexesInRange:primarySearchRange];
	
	__block NSInteger blockedSetIndex	=	-1;
	
	[otherContents enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
		trayContentObjectSet *	testSet	=	[self trayContentObjectSetForIndex:idx];
		if ([testSet contentPreviewImageView] == previewImageView){
			blockedSetIndex = idx;
			*stop = TRUE;
		}
	}];
	
	return blockedSetIndex;
}

-(NSInteger)		contentObjectIndexOnTrayAtTapPoint:(CGPoint)tapPoint{
	CGRect displayedFrame			=	_trayScrollView.frame;
	displayedFrame.origin			=	_trayScrollView.contentOffset;
	NSRange		touchSearchRange	=	[self rangeOfContentsForContentFrame:displayedFrame];
	CGPoint 	testPoint 			= 	tapPoint;
	testPoint.x += displayedFrame.origin.x;
	
	NSInteger	returnPIdx	=	-1;
	
	
	for (int i = touchSearchRange.location; i <= touchSearchRange.location +touchSearchRange.length; i ++){
		trayContentObjectSet *			testSet	=	[self trayContentObjectSetForIndex:i];
		CGRect					testSetFrame= [testSet contentPreviewImageView].frame;
		if (CGRectContainsPoint(testSetFrame, testPoint)){
			returnPIdx	= i; //starts at loc
			break;	
		}
	}
	
	return returnPIdx;
}

-(CGRect)		frameForContentImageAtIndex:(NSUInteger)contentIndex{
	CGRect	returnFrameRect		=	CGRectZero;
	returnFrameRect.origin.y	=	(_trayScrollView.frame.size.height-_contentImageSize.height)/2;
	returnFrameRect.origin.x	=	contentIndex * (_contentImageSize.width + _contentSpacingWidth) + _contentSpacingWidth;
	returnFrameRect.size		=	_contentImageSize;
	
	return returnFrameRect;
}

-(void)			setupContentSelectionViewWidthWithContentCount:(NSUInteger)contentCount{
	
	CGSize		resizedScrollViewSize					=	_trayScrollView.contentSize;
	
	resizedScrollViewSize.width		=	contentCount* (_contentImageSize.width + _contentSpacingWidth) + _contentSpacingWidth;
	
	_trayScrollView.contentSize	= resizedScrollViewSize;
}

-(NSRange)		rangeOfContentsForContentFrame:(CGRect)	displayRect{
	NSInteger startingIndex = MAX(0, floor(displayRect.origin.x / (_contentImageSize.width + _contentSpacingWidth)));
	NSInteger displayCount = ceil((displayRect.size.width + (_contentImageSize.width + _contentSpacingWidth))/ (_contentImageSize.width + _contentSpacingWidth));
	
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
		
		_cachedContentObjectSetsForTray	= [[NSMutableDictionary alloc] init];
		_unusedUIImageViewSet			= [[NSMutableSet	alloc]	init];
		
		_trayScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, 1024.0, 175.0)];
		[_trayScrollView setDelegate:self];
		
		_contentImageSize		=	CGSizeMake(212, 137);
		_contentSpacingWidth	=	35;
		
		_fadeoutOrigin		=	CGPointMake(0, 728);
		_displayOrigin		=	CGPointMake(0, _fadeoutOrigin.y - _trayScrollView.size.height);
		
	}
	return self;
}

- (void)dealloc {
	_contentDisplayControllerDelegate = nil;
	
	SRELS(_unusedUIImageViewSet);
	SRELS(_trayScrollView);
	SRELS(_cachedContentObjectSetsForTray);
	
	[super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	UIView *mainView = self.view;
	float windowWidth	=	[[UIApplication sharedApplication] keyWindow].frame.size.width;
	mainView.frame = CGRectMake(0.0, 0.0, windowWidth, 175.0);
	mainView.alpha = 1.000;
	mainView.autoresizesSubviews = YES;
	mainView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
	mainView.backgroundColor = [UIColor colorWithWhite:0.318 alpha:1.000];
	[mainView setBackgroundColor:[UIColor clearColor]];//scrollViewTexturedBackgroundColor 
	mainView.clearsContextBeforeDrawing = YES;
	mainView.clipsToBounds = NO;
	mainView.contentMode = UIViewContentModeScaleToFill;
	mainView.contentStretch = CGRectFromString(@"{{0, 0}, {1, 1}}");
	mainView.hidden = NO;
	mainView.multipleTouchEnabled = NO;
	mainView.opaque = YES;
	mainView.tag = 0;
	mainView.userInteractionEnabled = YES;
	
	
	
	
	_trayScrollView.frame = CGRectMake(0.0, 0.0, windowWidth, 175.0);
	[_trayScrollView setContentInset:UIEdgeInsetsMake(0, windowWidth, 0, windowWidth)];
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
	_trayScrollView.clipsToBounds = NO;
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
	[_trayScrollView setContentSize:CGSizeMake(windowWidth*2, 175)];
	[_trayScrollView setDecelerationRate:UIScrollViewDecelerationRateFast];
	[_trayScrollView	setShowsHorizontalScrollIndicator:TRUE];
	[_trayScrollView	setIndicatorStyle:UIScrollViewIndicatorStyleWhite];
	
	
	[mainView addSubview:_trayScrollView];
    

	
	UITapGestureRecognizer *tapGesture = [[ UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imagePreviewViewPressedWithTapController:)];
	[mainView addGestureRecognizer:tapGesture];
	SRELS(tapGesture);
	
	
	
	CGRect displayedFrame		=	_trayScrollView.frame;
	displayedFrame.origin		=	_trayScrollView.contentOffset;
	[self setupContentSelectionViewWidthWithContentCount:[_contentDisplayControllerDelegate totalContentCountInController:self]];
	[self setupLayoutForImagesInContentFrame:displayedFrame];
	
	
	
	[self.view setOrigin:_fadeoutOrigin];
	
}
//
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
	return TRUE;
}


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
