//
//  swypPhotoPlayground.m
//  swypPhotos
//
//  Created by Alexander List on 10/9/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import "swypPhotoPlayground.h"
#import "swypTiledContentViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "swypThumbView.h"

@implementation swypPhotoPlayground

#pragma mark UIViewController
-(id) initWithPhotoSize:(CGSize)imageSize{
	if (self = [super initWithNibName:nil bundle:nil]){
		_viewTilesByIndex	=	[[NSMutableDictionary alloc] init];
		
		_photoSize			=	imageSize;
	}
	return self;
}
-(void) viewDidLoad{
	[super viewDidLoad];
	[self.view setClipsToBounds:FALSE];
	
	_tiledContentViewController = [[swypTiledContentViewController alloc] initWithDisplayFrame:self.view.bounds tileContentControllerDelegate:(id<swypTiledContentViewControllerContentDelegate>)self withCenteredTilesSized:_photoSize andMargins:CGSizeMake(15, 15)];
	[_tiledContentViewController setPagingDisabled:TRUE];
	[[_tiledContentViewController view] setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
	[[_tiledContentViewController view] setClipsToBounds:FALSE];
	[[self view] addSubview:[_tiledContentViewController view]];
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return TRUE;
}

-(void) dealloc{
	SRELS(_tiledContentViewController);
	SRELS(_viewTilesByIndex);
	
	[super dealloc];
}

-(void)		setViewTile:(UIView*)view forTileIndex: (NSUInteger)tileIndex{
	if (view == nil){
		[_viewTilesByIndex removeObjectForKey:[NSNumber numberWithInt:tileIndex]];
	}else{
		[_viewTilesByIndex setObject:view forKey:[NSNumber numberWithInt:tileIndex]];
	}
}
-(UIView*)	viewForTileIndex:(NSUInteger)tileIndex{
	
	return 	[_viewTilesByIndex objectForKey:[NSNumber numberWithInt:tileIndex]];
}

-(CGRect)	rectToKeepInPlaygroundWithIntendedRect:	(CGRect)intendedRect{
	
	CGRect revisedRect		= intendedRect;
	
	CGSize negativeOverflow = CGSizeMake((intendedRect.origin.x < -1 * intendedRect.size.width/2)?intendedRect.origin.x - (-1 * intendedRect.size.width/2):0, 
										 (intendedRect.origin.y < -1 * intendedRect.size.height/2)?intendedRect.origin.y - (-1 * intendedRect.size.height/2):0);
	
	CGSize positiveOverflow = CGSizeMake(
										 (intendedRect.origin.x + intendedRect.size.width > self.view.size.width + intendedRect.size.width/2)?
										 (self.view.size.width + intendedRect.size.width/2)-(intendedRect.origin.x + intendedRect.size.width):0, 
										 (intendedRect.origin.y + intendedRect.size.height > self.view.size.height + intendedRect.size.height/2 )?
										 (self.view.size.height + intendedRect.size.height/2)-(intendedRect.origin.y + intendedRect.size.height):0);
	
	if (CGSizeEqualToSize(CGSizeZero, positiveOverflow) == NO){
		revisedRect.origin.x	+= positiveOverflow.width;
		revisedRect.origin.y	+= positiveOverflow.height;
	}
	
	if (CGSizeEqualToSize(CGSizeZero, negativeOverflow) == NO){
		revisedRect.origin.x	-= negativeOverflow.width;
		revisedRect.origin.y	-= negativeOverflow.height;
	}
	
	return revisedRect;
}

#pragma mark delegation
#pragma mark gestures
-(void)		contentPanOccuredWithRecognizer: (UIPanGestureRecognizer*) recognizer{
	
	if ([recognizer state] == UIGestureRecognizerStateBegan){
        // change z index to top here
        [_tiledContentViewController.view bringSubviewToFront:[recognizer view]];
		
	}else if ([recognizer state] == UIGestureRecognizerStateChanged){
		CGRect newTranslationFrame	= CGRectApplyAffineTransform([[recognizer view] frame], CGAffineTransformMakeTranslation([recognizer translationInView:self.view].x, [recognizer translationInView:self.view].y));
		newTranslationFrame	=	[self rectToKeepInPlaygroundWithIntendedRect:newTranslationFrame];
		
		
		[[recognizer view] setFrame:newTranslationFrame];
		[recognizer setTranslation:CGPointZero inView:self.view];
		
		NSInteger pannedIndex	= [self contentIndexMatchingSwypOutView:(UIImageView*)recognizer.view];
		if (pannedIndex != -1){
			[_contentDisplayControllerDelegate contentAtIndex:pannedIndex wasDraggedToFrame:[recognizer.view frame] inController:self];
		}

		
	}else if ([recognizer state] == UIGestureRecognizerStateEnded || [recognizer state] == UIGestureRecognizerStateFailed || [recognizer state] == UIGestureRecognizerStateCancelled){
		CGRect newTranslationFrame	= CGRectApplyAffineTransform([[recognizer view] frame],CGAffineTransformMakeTranslation([recognizer velocityInView:recognizer.view].x * .125, [recognizer velocityInView:recognizer.view].y * .125));
		newTranslationFrame			= [self rectToKeepInPlaygroundWithIntendedRect:newTranslationFrame];
		[UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut animations:^{
			[[recognizer view] setFrame:newTranslationFrame];
		}completion:nil];
		
		
		NSInteger pannedIndex	= [self contentIndexMatchingSwypOutView:(UIImageView*)recognizer.view];
		if (pannedIndex != -1){
			[_contentDisplayControllerDelegate contentAtIndex:pannedIndex wasReleasedWithFrame:[recognizer.view frame] inController:self];
		}
	}
}

#pragma mark swypTiledContentViewControllerContentDelegate
-(NSInteger)tileCountForTiledContentController:(swypTiledContentViewController*)tileContentController{
	return [_contentDisplayControllerDelegate totalContentCountInController:self];
}
-(UIView*)tileViewAtIndex:(NSInteger)tileIndex forTiledContentController:(swypTiledContentViewController*)tileContentController{
    /*
	UIImageView * photoTileView =	(UIImageView*)[self viewForTileIndex:tileIndex];
     */
    swypThumbView *photoTileView = (swypThumbView *)[self viewForTileIndex:tileIndex];
    
	if (photoTileView == nil){
        UIImage *contentImage = [_contentDisplayControllerDelegate imageForContentAtIndex:tileIndex 
                                                                                ofMaxSize:_photoSize 
                                                                             inController:self];
        photoTileView = [swypThumbView thumbViewWithImage:contentImage];
		
		UIPanGestureRecognizer * dragRecognizer		=	[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(contentPanOccuredWithRecognizer:)];
		[photoTileView addGestureRecognizer:dragRecognizer];
		SRELS(dragRecognizer);
        
		[self setViewTile:photoTileView forTileIndex:tileIndex];
	}
	
	return photoTileView;
}
										

#pragma mark swypContentDisplayViewController <NSObject>
-(void)	removeContentFromDisplayAtIndex:	(NSUInteger)removeIndex animated:(BOOL)animate{
	[_viewTilesByIndex removeAllObjects];
	[_tiledContentViewController reloadTileObjectData];
}
-(void)	insertContentToDisplayAtIndex:		(NSUInteger)insertIndex animated:(BOOL)animate fromStartLocation:(CGPoint)startLocation{
	[_viewTilesByIndex removeAllObjects];
	[_tiledContentViewController reloadTileObjectData];

	if (CGPointEqualToPoint(startLocation, CGPointZero) == NO){
		UIView * viewAtIndex	=	[self viewForTileIndex:insertIndex];
		[viewAtIndex setOrigin:startLocation];
		[self returnContentAtIndexToNormalLocation:insertIndex animated:TRUE];
	}
}

-(void)	setContentDisplayControllerDelegate: (id<swypContentDisplayViewControllerDelegate>)contentDisplayControllerDelegate{
	_contentDisplayControllerDelegate = contentDisplayControllerDelegate;
}
-(id<swypContentDisplayViewControllerDelegate>)	contentDisplayControllerDelegate{
	return _contentDisplayControllerDelegate;
}

-(void)	reloadAllData{
	[_viewTilesByIndex removeAllObjects];
	[_tiledContentViewController reloadTileObjectData];
}

-(void)	returnContentAtIndexToNormalLocation:	(NSInteger)index	animated:(BOOL)animate{
	
	NSIndexSet * returnIndexes	=	[NSIndexSet indexSetWithIndex:index];
	
	if (index == -1){
		returnIndexes	=	[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [_contentDisplayControllerDelegate totalContentCountInController:self])];
	}
	
	if (animate){
		[UIView animateWithDuration:.5 animations:^{
			[returnIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
				[[self tileViewAtIndex:idx forTiledContentController:_tiledContentViewController] setOrigin:[_tiledContentViewController frameForTileNumber:idx].origin];
			}];
		}];
	}else{
		[returnIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
			[[self tileViewAtIndex:idx forTiledContentController:_tiledContentViewController] setOrigin:[_tiledContentViewController frameForTileNumber:idx].origin];
		}];
	}		
}

-(NSInteger)	contentIndexMatchingSwypOutView:	(UIView*)swypedView{
	NSUInteger contentCount = [_contentDisplayControllerDelegate totalContentCountInController:self];
	NSInteger	returnContentIndex	=	-1;
	for (int i = 0; i < contentCount; i++){
		if ([self viewForTileIndex:i] == swypedView){
			returnContentIndex = i;
			break;
		}
	}
	return returnContentIndex;
}

-(CGSize) choiceMaxSizeForContentDisplay{
	return _photoSize;
}

@end
