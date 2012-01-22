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
            EXOLog(@"Dragged to top!");
            float fraction = powf(0.98, (60-centerY));
            recognizer.view.transform = CGAffineTransformMakeScale(fraction, fraction);
            recognizer.view.alpha = fraction;
        } else {
            recognizer.view.transform = CGAffineTransformMakeScale(1, 1);
        }
				
	} else if ([recognizer state] == UIGestureRecognizerStateEnded || [recognizer state] == UIGestureRecognizerStateFailed || [recognizer state] == UIGestureRecognizerStateCancelled){
        
        if (centerY > 60) {
            CGRect newTranslationFrame	= CGRectApplyAffineTransform([[recognizer view] frame],CGAffineTransformMakeTranslation([recognizer velocityInView:recognizer.view].x * .125, [recognizer velocityInView:recognizer.view].y * .125));
            newTranslationFrame			= [self rectToKeepInPlaygroundWithIntendedRect:newTranslationFrame];
            
            double tossDistance	=	euclideanDistance(newTranslationFrame.origin, [[recognizer view] frame].origin);
            BOOL recognizeToss	= FALSE;
            if (tossDistance > 100 && [_swypOutRecognizer state] == UIGestureRecognizerStateCancelled){
                recognizeToss = TRUE;
                EXOLog(@"TOSSER! %f",tossDistance);
            }
            
            NSString * swypOutContentID	= [_contentViewTilesByID keyForObject:[recognizer view]];

            [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseOut animations:^{
                [[recognizer view] setFrame:newTranslationFrame];
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
                    [_tiledContentViewController removeTile:recognizer.view animated:NO];
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
	UIView * tileView	=	[_contentDisplayControllerDelegate viewForContentWithID:removeID ofMaxSize:_photoSize inController:self];
	[_tiledContentViewController removeTile:tileView animated:animate];
}

-(void)	addContentToDisplayWithID: (NSString*)insertID animated:(BOOL)animate{
	
	UIView * tileView	=	[self _setupTileWithID:insertID];
	[_contentViewTilesByID setObject:tileView forKey:insertID];
	
	[_tiledContentViewController addTile:tileView animated:animate];
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

-(void)	returnContentWithIDToNormalLocation:(NSString*)contentID	animated:(BOOL)animate{
	
#pragma mark TODO:
	EXOLog(@"returnContentWithIDToNormalLocation is marked TODO! CID%@",contentID);
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
