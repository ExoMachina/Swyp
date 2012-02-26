//
//  swypPhotoPlayground.m
//  swypPhotos
//
//  Created by Alexander List on 10/9/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import "swypPhotoPlayground.h"
#import "swypTiledContentViewController.h"
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
	
	[self.view setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
	
	_tiledContentViewController = [[swypTiledContentViewController alloc] initWithDisplayFrame:self.view.bounds tileContentControllerDelegate:(id<swypTiledContentViewControllerContentDelegate>)self withCenteredTilesSized:_photoSize andMargins:CGSizeMake(15, 15)];

	[[_tiledContentViewController view] setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
	[[_tiledContentViewController view] setClipsToBounds:FALSE];
	[[self view] addSubview:[_tiledContentViewController view]];
	
	_swypOutRecognizer	=	[[swypOutGestureRecognizer alloc] initWithTarget:self action:@selector(swypOutGestureChanged:)];
	[_swypOutRecognizer setDelegate:self];
	[_swypOutRecognizer setDelaysTouchesBegan:FALSE];
	[_swypOutRecognizer setDelaysTouchesEnded:TRUE];
	[_swypOutRecognizer setCancelsTouchesInView:FALSE];
	[[self view] addGestureRecognizer:_swypOutRecognizer];
	
}
												
														 
-(void)viewDidUnload {
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return TRUE;
}

-(void) dealloc{
	SRELS(_tiledContentViewController);
	SRELS(_swypOutRecognizer);
	
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
-(void)		contentPanOccurredWithRecognizer: (UIPanGestureRecognizer*) recognizer{
    
    float centerY = recognizer.view.center.y;
	
	if ([recognizer state] == UIGestureRecognizerStateBegan){
        // change z index to top here
        [_tiledContentViewController.view bringSubviewToFront:[recognizer view]];
		
	} else if ([recognizer state] == UIGestureRecognizerStateChanged){
		CGRect newTranslationFrame	= CGRectApplyAffineTransform([[recognizer view] frame], CGAffineTransformMakeTranslation([recognizer translationInView:self.view].x, [recognizer translationInView:self.view].y));
		newTranslationFrame	=	[self rectToKeepInPlaygroundWithIntendedRect:newTranslationFrame];
		
		[[recognizer view] setFrame:newTranslationFrame];
		[recognizer setTranslation:CGPointZero inView:self.view];
        
        if (centerY < 60) {
            float fraction = powf(0.98, (60-centerY));
            recognizer.view.transform = CGAffineTransformMakeScale(fraction, fraction);
            recognizer.view.alpha = fraction;
        } else {
            recognizer.view.transform = CGAffineTransformMakeScale(1, 1);
        }
				
	} else if ([recognizer state] == UIGestureRecognizerStateEnded || [recognizer state] == UIGestureRecognizerStateFailed || [recognizer state] == UIGestureRecognizerStateCancelled){
        
        NSString * swypOutContentID	= [_contentViewTilesByID keyForObject:[recognizer view]];
        
        if (centerY > 60) {
            CGRect keneticTranslationFrame	= CGRectApplyAffineTransform([[recognizer view] frame],CGAffineTransformMakeTranslation([recognizer velocityInView:recognizer.view].x * .125, [recognizer velocityInView:recognizer.view].y * .125));
                                    
            double tossDistance	=	euclideanDistance(keneticTranslationFrame.origin, [[recognizer view] frame].origin);
            BOOL recognizeToss	= FALSE;
            if (tossDistance > 100 && [_swypOutRecognizer state] != UIGestureRecognizerStateRecognized){
				EXOLog(@"TOSSER! %f",tossDistance);
                recognizeToss = TRUE;
            }
            
			CGRect revisedKeneticTranslationFrame			= [self rectToKeepInPlaygroundWithIntendedRect:keneticTranslationFrame];
			
			//Toss mode should have different upper bound
			if (revisedKeneticTranslationFrame.origin.y < 50) {
				revisedKeneticTranslationFrame.origin.y = 50;
			}
			
            [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut animations:^{
                [[recognizer view] setFrame:revisedKeneticTranslationFrame];
            }completion:^(BOOL completed){
                if (recognizeToss){
                    if (StringHasText(swypOutContentID)){
                        [_contentDisplayControllerDelegate contentWithIDUnderwentSwypOut:swypOutContentID inController:self];
                    }
                }
            }];
        } else {
            [UIView animateWithDuration:0.25 animations:^{
                recognizer.view.alpha = 0;
                recognizer.view.transform = CGAffineTransformMakeScale(0.01, 0.01);
            }completion:^(BOOL completed){
                if (completed) {
					[_contentDisplayControllerDelegate contentWithIDWasDraggedOffWorkspace:swypOutContentID inController:self];
                }
            }];
        }		
	}
}

-(void)	swypOutGestureChanged:(swypOutGestureRecognizer*)recognizer{
	if (recognizer.state == UIGestureRecognizerStateRecognized){
		UIView * gestureView	=	[[recognizer swypGestureInfo] swypBeginningContentView];
		NSString * swypOutContentID	= [_contentViewTilesByID keyForObject:gestureView];
		if (StringHasText(swypOutContentID)){
			EXOLog(@"swypOutGestureChanged recogn in contentDisplayViewController on: %@",swypOutContentID);
			[_contentDisplayControllerDelegate contentWithIDUnderwentSwypOut:swypOutContentID inController:self];
			
			//now we make a beatiful dissapear animation
			CGRect originalFrame	=	[gestureView frame];
			CGRect disappearFrame	=	originalFrame;
			if ([[recognizer swypGestureInfo] screenEdgeOfSwyp] == swypScreenEdgeTypeRight){
				disappearFrame.origin.x	=	self.view.width;
			}else if ([[recognizer swypGestureInfo] screenEdgeOfSwyp] == swypScreenEdgeTypeLeft){
				disappearFrame.origin.x	=	0 - originalFrame.size.width;
			} else if ([[recognizer swypGestureInfo] screenEdgeOfSwyp] == swypScreenEdgeTypeBottom){
				disappearFrame.origin.y	=	self.view.height;
			}else if ([[recognizer swypGestureInfo] screenEdgeOfSwyp] == swypScreenEdgeTypeTop){
				disappearFrame.origin.y	=	0 - originalFrame.size.height;
			}
			double distance		=	euclideanDistance(originalFrame.origin,disappearFrame.origin);
			double animateTime	=	distance/ ([recognizer velocity] * [swypGestureRecognizer currentDevicePixelsPerLinearMillimeter]);
			[UIView animateWithDuration:animateTime delay:0 options:UIViewAnimationCurveEaseOut|UIViewAnimationOptionAllowUserInteraction animations:^{
				[gestureView setFrame:disappearFrame];
			}completion:^(BOOL complete){
				[UIView animateWithDuration:animateTime delay:1 options:UIViewAnimationCurveEaseOut|UIViewAnimationOptionAllowUserInteraction animations:^{ [gestureView setFrame:originalFrame];} completion:nil];

			}];
			
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
		
		UIView * tileView	=	[self _setupTileWithID:tileID];
		[_contentViewTilesByID setObject:tileView forKey:tileID];
				
		[allTilesArray addObject:tileView];
	}
	return allTilesArray;
}
										
#pragma mark swypContentDisplayViewController <NSObject>
-(void)	removeContentFromDisplayWithID:	(NSString*)removeID animated:(BOOL)animate{
	UIView * tileView	=	[_contentViewTilesByID objectForKey:removeID];
	[_tiledContentViewController removeTile:tileView animated:animate];
	[_contentViewTilesByID removeObjectForKey:removeID];
}

-(void)	addContentToDisplayWithID: (NSString*)insertID animated:(BOOL)animate{
	//this view refuses duplicate tiles of identicalID
	assert ([_contentViewTilesByID objectForKey:insertID] == nil);
	
	UIView * tileView	=	[self _setupTileWithID:insertID];
	[_contentViewTilesByID setObject:tileView forKey:insertID];
	
	[_tiledContentViewController addTile:tileView animated:animate];
}

-(NSArray*)	allDisplayedObjectIDs{
	return [_contentViewTilesByID allKeys];
}

-(void)	setContentDisplayControllerDelegate: (id<swypContentDisplayViewControllerDelegate>)contentDisplayControllerDelegate{
	_contentDisplayControllerDelegate = contentDisplayControllerDelegate;
}
-(id<swypContentDisplayViewControllerDelegate>)	contentDisplayControllerDelegate{
	return _contentDisplayControllerDelegate;
}

-(void)	reloadAllData{
	[_contentViewTilesByID removeAllObjects];
	[_tiledContentViewController reloadTileObjectData];
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

-(void)	moveContentWithID: (NSString*)objectID toFrame:(CGRect)frame animated:(BOOL)animate{
	UIView * view = [_contentViewTilesByID objectForKey:objectID];
	if (animate){
		[UIView animateWithDuration:.4 animations:^{[view setFrame:frame];} completion:nil];
	}else{
		[view setFrame:frame];
	}
}

#pragma mark - private
-(UIView*) _setupTileWithID:(NSString*)tileID{
	UIView * tileView	=	[_contentDisplayControllerDelegate viewForContentWithID:tileID ofMaxSize:_photoSize inController:self];
	
	BOOL needAddPanRecognizer = TRUE;
	for (UIGestureRecognizer * recognizer in [tileView gestureRecognizers]){
		if ([recognizer isKindOfClass:[UIPanGestureRecognizer class]]){
			needAddPanRecognizer = FALSE;
			break;
		}
	}
	if (needAddPanRecognizer){
		UIPanGestureRecognizer * dragRecognizer		=	[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(contentPanOccurredWithRecognizer:)];
		[tileView addGestureRecognizer:dragRecognizer];
		SRELS(dragRecognizer);
	}
	
	return tileView;
}
@end
