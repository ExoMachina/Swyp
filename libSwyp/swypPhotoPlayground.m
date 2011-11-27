//
//  swypPhotoPlayground.m
//  swypPhotos
//
//  Created by Alexander List on 10/9/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import "swypPhotoPlayground.h"
#import <QuartzCore/QuartzCore.h>
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
	
	_tiledContentViewController = [[swypTiledContentViewController alloc] initWithDisplayFrame:self.view.bounds tileContentControllerDelegate:self withCenteredTilesSized:_photoSize andMargins:CGSizeMake(94, 10)];
	[_tiledContentViewController.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
	[_tiledContentViewController.view setClipsToBounds:FALSE];
	[self.view addSubview:_tiledContentViewController.view];
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

#pragma mark delegation
#pragma mark gestures
-(void)		contentPanOccuredWithRecognizer: (UIPanGestureRecognizer*) recognizer{
	
	if ([recognizer state] == UIGestureRecognizerStateBegan){
		
	}else if ([recognizer state] == UIGestureRecognizerStateChanged){
		[[recognizer view] setFrame:CGRectApplyAffineTransform([[recognizer view] frame], CGAffineTransformMakeTranslation([recognizer translationInView:self.view].x, [recognizer translationInView:self.view].y))];
		[recognizer setTranslation:CGPointZero inView:self.view];
		
		NSInteger pannedIndex	= [self contentIndexMatchingSwypOutView:(UIImageView*)recognizer.view];
		if (pannedIndex != -1){
			[_contentDisplayControllerDelegate contentAtIndex:pannedIndex wasDraggedToFrame:[recognizer.view frame] inController:self];
		}

		
	}else if ([recognizer state] == UIGestureRecognizerStateEnded || [recognizer state] == UIGestureRecognizerStateFailed || [recognizer state] == UIGestureRecognizerStateCancelled){
		CGPoint currentLocation		=	[[recognizer view] origin];
		CGPoint glideLocation	 	= CGPointApplyAffineTransform(currentLocation, CGAffineTransformMakeTranslation([recognizer velocityInView:recognizer.view].x * .125, [recognizer velocityInView:recognizer.view].y * .125));
		[UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut animations:^{
			[[recognizer view] setOrigin:glideLocation];
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
	UIImageView * photoTileView =	(UIImageView*)[self viewForTileIndex:tileIndex];
	if (photoTileView == nil){
		photoTileView	=	[[UIImageView alloc] initWithImage:[_contentDisplayControllerDelegate imageForContentAtIndex:tileIndex ofMaxSize:_photoSize inController:self]];
		[photoTileView setUserInteractionEnabled:TRUE];
		[photoTileView setBackgroundColor:[UIColor blackColor]];
		
		CALayer	*layer	=	photoTileView.layer;
		[layer setBorderColor: [[UIColor whiteColor] CGColor]];
		[layer setBorderWidth:8.0f];
		[layer setShadowColor: [[UIColor blackColor] CGColor]];
		[layer setShadowOpacity:0.9f];
		[layer setShadowOffset: CGSizeMake(1, 3)];
		[layer setShadowRadius:4.0];
		CGMutablePathRef shadowPath		=	CGPathCreateMutable();
		CGPathAddRect(shadowPath, NULL, CGRectMake(0, 0, photoTileView.size.width, photoTileView.size.width));
		[layer setShadowPath:shadowPath];
		[photoTileView setClipsToBounds:NO];
		
		UIPanGestureRecognizer * dragRecognizer		=	[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(contentPanOccuredWithRecognizer:)];
		[photoTileView addGestureRecognizer:dragRecognizer];
		SRELS(dragRecognizer);
		[self setViewTile:photoTileView forTileIndex:tileIndex];
		[photoTileView release];
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
				[[self tileViewAtIndex:idx forTiledContentController:_tiledContentViewController] setFrame:[_tiledContentViewController frameForTileNumber:idx]];
			}];
		}];
	}else{
		[returnIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
			[[self tileViewAtIndex:idx forTiledContentController:_tiledContentViewController] setFrame:[_tiledContentViewController frameForTileNumber:idx]];
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

@end
