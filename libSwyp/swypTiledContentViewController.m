//
//  swypTiledContentViewController.m
//  Fibromyalgia
//
//  Created by Alexander List on 7/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "swypTiledContentViewController.h"

@implementation swypTiledContentViewController
@synthesize tileSize = _tileSize, tileMarginSize = _tileMarginSize ,maxTileRows = _maxTileRows, maxTileColumns=_maxTileColumns, layoutStartPoint = _layoutStartPoint, tileDisplayFrame = _tileDisplayFrame, delegate = _delegate;
@synthesize displayedTileViews = _displayedTileViews;

#pragma mark layout 

-(void)		addTile:(UIView*)tile animated:(BOOL)animate{
	if ([_displayedTileViews containsObject:tile] == NO){
		[self.view addSubview:tile];
		
		if (animate){
			double preAlpha	= tile.alpha;
			tile.alpha	= 0;
			[UIView animateWithDuration:.4 animations:^{tile.alpha = preAlpha;} completion:nil];
		}
		
		CGRect tileFrame	= [self frameForTileNumber:[_displayedTileViews count]];
		if (CGSizeEqualToSize(tileFrame.size, tile.size) == NO){
			tileFrame.size	= tile.size;
		}
		[tile setFrame:tileFrame];
		
		[_displayedTileViews addObject:tile];
	}
}
-(void)		removeTile:(UIView*)tile animated:(BOOL)animate{
	if (animate){
		[UIView animateWithDuration:.4 delay:0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionAllowAnimatedContent animations:^{
			[tile setAlpha:0];
		}completion:^(BOOL finished){
			[tile removeFromSuperview];
		}];
	}else{
		[tile removeFromSuperview];
	
	}
	[_displayedTileViews removeObject:tile];
}

-(void)		layoutTiles:(NSArray*)tiles{
	//determine tiles to display
	NSMutableSet *	tilesToRemove	= [NSMutableSet setWithSet:_displayedTileViews];

	for (int index = 0; index < [tiles count]; index++){
		UIView *nextTile = [tiles objectAtIndex:index];		
		if ([_displayedTileViews containsObject:nextTile] == NO){
			
			[self addTile:nextTile animated:TRUE];
			
			[tilesToRemove removeObject:nextTile];
			
		}else {

			[tilesToRemove removeObject:nextTile];
		}
		
	}
	
	for (UIView * removeTileView in tilesToRemove){
		[self removeTile:removeTileView animated:TRUE];	
	}
	
}

-(void)		reloadTileObjectData{
	[self layoutTiles:[_delegate allTileViewsForTiledContentController:self]];
}

-(CGRect)frameForTileNumber:(NSInteger)tileNumber{
	
	CGPoint startRectPoint		=	_layoutStartPoint;
	
	CGRect frameRect = CGRectZero;
	frameRect.size = _tileSize;
	frameRect.origin = startRectPoint;
	
	NSInteger row			= tileNumber / (int)_maxTileColumns;
	NSInteger column		= tileNumber % (int)_maxTileColumns;
	
	frameRect.origin.x += column * (_tileSize.width + _tileMarginSize.width);
	frameRect.origin.y += row *  (_tileSize.height + _tileMarginSize.height) + 40;
	
	
	return frameRect;
}

#pragma mark interactivity

#pragma mark lifecycle
-(void)	viewDidLoad{
	[super viewDidLoad];
	
	[self.view setFrame:_tileDisplayFrame];
		
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return TRUE;
}
-(id)	initWithDisplayFrame:(CGRect)tileDisplayFrame tileContentControllerDelegate:(id<swypTiledContentViewControllerContentDelegate>)delegate{
	if (self = [super init]){
		_tileDisplayFrame = tileDisplayFrame;
		_delegate = delegate;
		
		_displayedTileViews = [[NSMutableSet alloc] init];
	}
	return self;
}
-(id)	initWithDisplayFrame:(CGRect)tileDisplayFrame tileContentControllerDelegate:(id<swypTiledContentViewControllerContentDelegate>)delegate withCenteredTilesSized:(CGSize)tileSize andMargins:(CGSize)tileMargins{
	if (self = [self initWithDisplayFrame:tileDisplayFrame tileContentControllerDelegate:delegate]){
		_tileSize		= tileSize;
		_tileMarginSize	= tileMargins;
		_maxTileRows	= tileDisplayFrame.size.height / (tileSize.height + tileMargins.height);
		_maxTileColumns	= tileDisplayFrame.size.width / (tileSize.width + tileMargins.width);
		
		double	xStartPoint	=	(_tileMarginSize.width)/2; 
		double	yStartPoint	=	(_tileMarginSize.height)/2; 

		_layoutStartPoint	=	CGPointMake(xStartPoint, yStartPoint);
	}
	return self;
}
-(id)	initWithDisplayFrame:(CGRect)tileDisplayFrame tileContentControllerDelegate:(id<swypTiledContentViewControllerContentDelegate>)delegate withCenteredTilesSized:(CGSize)tileSize withMaxRows:(double)maxRows maxColumns:(double)maxColumns{
	double widthMarginTotal		= tileDisplayFrame.size.width - maxColumns * tileSize.width;
	double marginWidth			= widthMarginTotal/ maxColumns;
	
	double heightMarginTotal	= tileDisplayFrame.size.height - maxRows * tileSize.height;
	double marginHeight			= heightMarginTotal / maxColumns;	
	if (self = [self initWithDisplayFrame:tileDisplayFrame tileContentControllerDelegate:delegate withCenteredTilesSized:tileSize andMargins:CGSizeMake(marginWidth, marginHeight)]){
		
	}
	return self;
}



-(void)dealloc{
	_delegate = nil;
	SRELS(_displayedTileViews);
	
	[super dealloc];
}


@end
