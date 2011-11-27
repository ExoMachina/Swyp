//
//  swypPhotoPlayground.h
//  swypPhotos
//
//  Created by Alexander List on 10/9/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "swypTiledContentViewController.h"

//this is an example of a content display view under the 
// swypContentDisplayViewController protocol used to display content for swyping accross devices...
//this view controller is given a swypContentDisplayViewControllerDelegate which it can use to pull data from and alert about events

//swypPhotoPlayground encapsulates a tiledVieController which is used to actually display images

@interface swypPhotoPlayground : UIViewController <swypTiledContentViewControllerContentDelegate,swypContentDisplayViewController>{
	swypTiledContentViewController *					_tiledContentViewController;
	
	id<swypContentDisplayViewControllerDelegate>	_contentDisplayControllerDelegate;	
	
	NSMutableDictionary *							_viewTilesByIndex;
	
	CGSize											_photoSize;
}
-(id)		initWithPhotoSize:(CGSize)imageSize;

-(UIView*)	viewForTileIndex:(NSUInteger)tileIndex;
-(void)		setViewTile:(UIView*)view forTileIndex: (NSUInteger)tileIndex;
@end
