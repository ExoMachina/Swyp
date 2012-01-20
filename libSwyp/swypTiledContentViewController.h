//
//  swypTiledContentViewController.h
//  Fibromyalgia
//
//  Created by Alexander List on 7/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//


//On it's own the swypTiledContentViewController does very little; it relies on swypPhotoPlayground to be it's contentDisplayController 


#import <Foundation/Foundation.h>

@class swypTiledContentViewController;

@protocol swypTiledContentViewControllerContentDelegate<NSObject>

-(NSArray*) allTileViewsForTiledContentController:(swypTiledContentViewController*)tileContentController;
@end


@interface swypTiledContentViewController : UIViewController {

	id<swypTiledContentViewControllerContentDelegate> _delegate;
	
	CGSize	_tileSize;
	CGSize	_tileMarginSize;
	double	_maxTileRows;
	double	_maxTileColumns;
	CGPoint	_layoutStartPoint;
	CGRect	_tileDisplayFrame; 
	
	NSMutableSet*	_displayedTileViews;
	
}
@property (nonatomic, assign) id<swypTiledContentViewControllerContentDelegate>	delegate;

@property (nonatomic, assign) CGSize	tileSize;
@property (nonatomic, assign) CGSize	tileMarginSize;
@property (nonatomic, assign) double	maxTileRows;
@property (nonatomic, assign) double	maxTileColumns;
@property (nonatomic, assign) CGPoint	layoutStartPoint;

///All the currently displayed tile views;
@property (nonatomic, readonly) NSSet * displayedTileViews;

///for setting margins & overall size
@property (nonatomic, assign) CGRect	tileDisplayFrame; 

///Just gets a frame for a tile, as if it were at the given index
-(CGRect)frameForTileNumber:(NSInteger)tileNumber;


///This delegate method allTileViewsForTiledContentController to be called, and all tiles to be layed-out 
-(void)		reloadTileObjectData;

/// add a tile to display; it will be place at frameForTileNumber:[[self displayedTileViews] count]
-(void)		addTile:(UIView*)tile;
/// remove the tile from view
-(void)		removeTile:(UIView*)tile;

///This one is great for setting cell size and their margins; use this init function
-(id)		initWithDisplayFrame:(CGRect)tileDisplayFrame tileContentControllerDelegate:(id<swypTiledContentViewControllerContentDelegate>)delegate withCenteredTilesSized:(CGSize)tileSize andMargins:(CGSize)tileMargins;

-(id)		initWithDisplayFrame:(CGRect)tileDisplayFrame tileContentControllerDelegate:(id<swypTiledContentViewControllerContentDelegate>)delegate withCenteredTilesSized:(CGSize)tileSize withMaxRows:(double)maxRows maxColumns:(double)maxColumns;

-(id)		initWithDisplayFrame:(CGRect)tileDisplayFrame tileContentControllerDelegate:(id<swypTiledContentViewControllerContentDelegate>)delegate;


@end
