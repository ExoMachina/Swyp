//
//  swypPhotoPlayground.h
//  swypPhotos
//
//  Created by Alexander List on 10/9/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "swypTiledContentViewController.h"
#import "swypBidirectionalMutableDictionary.h"
#import "swypOutGestureRecognizer.h"


@interface swypPhotoPlayground : UIViewController <swypTiledContentViewControllerContentDelegate,swypContentDisplayViewController, UIGestureRecognizerDelegate>{
	swypTiledContentViewController *		_tiledContentViewController;
	
	id<swypContentDisplayViewControllerDelegate>	_contentDisplayControllerDelegate;	
	
	swypBidirectionalMutableDictionary *	_contentViewTilesByID;
	
	swypOutGestureRecognizer *				_swypOutRecognizer;
		
	CGSize									_photoSize;
}
///Init'd with the max image size permissable in the contentDisplayCont
-(id)	initWithPhotoSize:(CGSize)imageSize;


///this just keeps the photo in bounds
-(CGRect)	rectToKeepInPlaygroundWithIntendedRect:	(CGRect)intendedRect;

//
//private 
-(UIView*) _setupTileWithID:(NSString*)tileID;
@end
