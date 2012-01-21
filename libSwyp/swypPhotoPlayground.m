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
#import "swypOutGestureRecognizer.h"
@implementation swypPhotoPlayground


#pragma mark UIViewController
-(id) initWithPhotoSize:(CGSize)imageSize{
	if (self = [super initWithNibName:nil bundle:nil]){
		
		_photoSize			=	imageSize;
		
		_contentViewTilesByID	=	[[swypBidirectionalMutableDictionary alloc] init];
	}
	return self;
}
-(void) viewDidLoad{
	[super viewDidLoad];
	[self.view setClipsToBounds:FALSE];
	
	_tiledContentViewController = [[swypTiledContentViewController alloc] initWithDisplayFrame:self.view.bounds tileContentControllerDelegate:(id<swypTiledContentViewControllerContentDelegate>)self withCenteredTilesSized:_photoSize andMargins:CGSizeMake(15, 15)];

	[[_tiledContentViewController view] setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
	[[_tiledContentViewController view] setClipsToBounds:FALSE];
	[[self view] addSubview:[_tiledContentViewController view]];
	
	swypOutGestureRecognizer * swypOutRecognizer	=	[[swypOutGestureRecognizer alloc] initWithTarget:self action:@selector(swypOutGestureChanged:)];
	[swypOutRecognizer setDelegate:self];
	
}
														 
												
														 
														 
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return TRUE;
}

-(void) dealloc{
	SRELS(_tiledContentViewController);

	[super dealloc];
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
				
	}else if ([recognizer state] == UIGestureRecognizerStateEnded || [recognizer state] == UIGestureRecognizerStateFailed || [recognizer state] == UIGestureRecognizerStateCancelled){
		CGRect newTranslationFrame	= CGRectApplyAffineTransform([[recognizer view] frame],CGAffineTransformMakeTranslation([recognizer velocityInView:recognizer.view].x * .125, [recognizer velocityInView:recognizer.view].y * .125));
		newTranslationFrame			= [self rectToKeepInPlaygroundWithIntendedRect:newTranslationFrame];
		[UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut animations:^{
			[[recognizer view] setFrame:newTranslationFrame];
		}completion:nil];
		
	}
}

-(void)	swypOutGestureChanged:(swypOutGestureRecognizer*)recognizer{
	if (recognizer.state == UIGestureRecognizerStateRecognized){
		UIView * gestureView	=	[[recognizer swypGestureInfo] swypBeginningContentView];
		if ([_contentViewTilesByID keyForObject:gestureView] != nil){
			[_contentDisplayControllerDelegate contentWithID:[_contentViewTilesByID keyForObject:gestureView] underwentSwypOutWithInfoRef:[recognizer swypGestureInfo] inController:self];
		}
	}
}


-(BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
	
	if ([gestureRecognizer isKindOfClass:[swypGestureRecognizer class]])
		return TRUE;
	
	return FALSE;
}



#pragma mark swypTiledContentViewControllerContentDelegate
-(NSArray*) allTileViewsForTiledContentController:(swypTiledContentViewController*)tileContentController{

	NSMutableArray * allTilesArray = [NSMutableArray array];
	for (NSString * tileID  in [_contentDisplayControllerDelegate allIDsForContentInController:self]){
		
		UIView * tileView	=	[_contentDisplayControllerDelegate viewForContentWithID:tileID ofMaxSize:_photoSize inController:self];
		
		BOOL needAddPanRecognizer = TRUE;
		for (UIGestureRecognizer * recognizer in [tileView gestureRecognizers]){
			if ([recognizer isKindOfClass:[UIPanGestureRecognizer class]]){
				needAddPanRecognizer = FALSE;
				break;
			}
		}
		if (needAddPanRecognizer){
			UIPanGestureRecognizer * dragRecognizer		=	[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(contentPanOccuredWithRecognizer:)];
			[tileView addGestureRecognizer:dragRecognizer];
			SRELS(dragRecognizer);
		}
		
		#pragma mark TODO: add swypOutGesture recognition here
		EXOLog(@"Need swyp-out recognition!! %@",@"here!");
		
		[allTilesArray addObject:tileView];
	}
	return allTilesArray;
}										

#pragma mark swypContentDisplayViewController <NSObject>
-(void)	removeContentFromDisplayWithID:	(NSString*)removeID animated:(BOOL)animate{
	UIView * tileView	=	[_contentDisplayControllerDelegate viewForContentWithID:removeID ofMaxSize:_photoSize inController:self];
	[_tiledContentViewController removeTile:tileView];
}

-(void)	addContentToDisplayWithID: (NSString*)insertID animated:(BOOL)animate{
	
	UIView * tileView	=	[_contentDisplayControllerDelegate viewForContentWithID:insertID ofMaxSize:_photoSize inController:self];
	[_tiledContentViewController addTile:tileView];
}


-(void)	setContentDisplayControllerDelegate: (id<swypContentDisplayViewControllerDelegate>)contentDisplayControllerDelegate{
	_contentDisplayControllerDelegate = contentDisplayControllerDelegate;
}
-(id<swypContentDisplayViewControllerDelegate>)	contentDisplayControllerDelegate{
	return _contentDisplayControllerDelegate;
}

-(void)	reloadAllData{
	[_tiledContentViewController reloadTileObjectData];
}

-(void)	returnContentWithIDToNormalLocation:(NSString*)contentID	animated:(BOOL)animate{
	
#pragma mark TODO:
	EXOLog(@"returnContentWithIDToNormalLocation is marked TODO!");
	/**
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
	 */
}
  

-(NSString*)	contentIDMatchingSwypOutView:	(UIView*)swypedView{
	
	for (UIView * swypView in [_contentViewTilesByID allValues]){
		if (swypView == swypedView){
			return [_contentViewTilesByID keyForValue:swypedView];
		}
	}
	return nil;
}
 
-(CGSize) choiceMaxSizeForContentDisplay{
	return _photoSize;
}

@end
