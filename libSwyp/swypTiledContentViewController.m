//
//  swypTiledContentViewController.m
//  Fibromyalgia
//
//  Created by Alexander List on 7/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "swypTiledContentViewController.h"

@implementation swypTiledContentViewController
@synthesize tileSize = _tileSize, tileMarginSize = _tileMarginSize ,maxTileRows = _maxTileRows, maxTileColumns=_maxTileColumns, pagingDisabled = _pagingDisabled, layoutStartPoint = _layoutStartPoint, tileDisplayFrame = _tileDisplayFrame, displayedTiles = _displayedTiles, currentPage = _currentPage, delegate = _delegate, loadingStatusView = _loadingStatusView;

#pragma mark layout 

-(NSInteger)	tilePageCount{
	if (_pagingDisabled == TRUE)
		return 1;
	
	NSInteger totalTiles	= [_delegate tileCountForTiledContentController:self];
	NSInteger maxPageTiles	= _maxTileRows * _maxTileColumns;
	
	if (totalTiles <= maxPageTiles){
		return 1;
	}
	
	NSInteger	totalPages		= 0;
	NSInteger	remainingTiles	= totalTiles;
	
	//forward controls
	NSInteger	firstPageTiles	= maxPageTiles -1;
	totalPages ++;
	remainingTiles	-=	firstPageTiles;
	
	//forward and back
	NSInteger	middlePageTiles	= maxPageTiles -2; 
	NSInteger	middlePages		= remainingTiles/ middlePageTiles;
	middlePages --; //perhaps it's the last page, in which case we'll need only a back button
	
	totalPages		+=	middlePages;
	remainingTiles	-= middlePageTiles * middlePages;
	
	NSInteger	lastPageTiles	= maxPageTiles -1;
	
	if (remainingTiles > lastPageTiles){
		totalPages ++;
		middlePageTiles -= middlePageTiles;
	}
	
	
	if (remainingTiles > 0)
		totalPages ++;
	
	return totalPages;
}

//	pageNumber zero delimited whereas tilePageCount is 1 page = 1 count
-(NSRange)	tileRangeForPage:(NSInteger)pageNumber needsForwardPagination:(BOOL*)forwardPaginationNeeded needsBackwardPagination:(BOOL*)backwardPaginationNeeded{
	NSInteger totalTiles	= [_delegate tileCountForTiledContentController:self];
	NSInteger maxPageTiles	= _maxTileRows * _maxTileColumns;

	if (_pagingDisabled == YES){
		return NSMakeRange(0, (maxPageTiles > totalTiles)?totalTiles:maxPageTiles);
	}
	
	*forwardPaginationNeeded	= NO;
	*backwardPaginationNeeded	= NO;
	
	if (pageNumber > [self tilePageCount]){
		if (pageNumber > 1){
			return NSMakeRange(NSNotFound, 0);
		}
		[NSException raise:@"NSYou'reTooExcitedException" format:@"your requested tile page %i is past the max page # %i",pageNumber,[self tilePageCount]];
	}
	
	if (totalTiles <= maxPageTiles){
		return NSMakeRange(0, totalTiles);
	}
	
	NSInteger	currentCalculatedPage		= 0;
	NSInteger	remainingTiles				=totalTiles;
	NSInteger	pageBeginningTile			=0;
	
	//forward controls
	NSInteger	firstPageTiles	= maxPageTiles -1;
	*forwardPaginationNeeded	= YES;
	currentCalculatedPage ++;
	remainingTiles				-=	firstPageTiles;
	if (pageNumber == currentCalculatedPage){
		return NSMakeRange(pageBeginningTile, firstPageTiles);
	}
	pageBeginningTile			+=	firstPageTiles;
	*backwardPaginationNeeded	= YES;
	
	//forward and back
	NSInteger	middlePageTiles	= maxPageTiles -2; 
	NSInteger	middlePages		= remainingTiles/ middlePageTiles;
	middlePages --; //perhaps it's the last page, in which case we'll need only a back button
	
	currentCalculatedPage		+=	middlePages;
	remainingTiles	-= middlePageTiles * middlePages;
	if (pageNumber <= currentCalculatedPage){
		pageBeginningTile		+=	middlePageTiles * (pageNumber-1); //not the first page, it's already included in pageBeginningTile
		return NSMakeRange(pageBeginningTile, middlePageTiles);
	}else {
		pageBeginningTile += middlePageTiles * middlePages; //move beginning past middle pages
	}

	
	NSInteger	lastPageTiles	= maxPageTiles -1;
	
	if (remainingTiles > lastPageTiles){
		currentCalculatedPage ++;
		middlePageTiles -= middlePageTiles;
		if (pageNumber == currentCalculatedPage){
			return NSMakeRange(pageBeginningTile, middlePageTiles);
		}
		pageBeginningTile		+=	middlePageTiles; //move beginning past last middle page
	}	

	*forwardPaginationNeeded	= NO;
	
	if (remainingTiles > 0){
		currentCalculatedPage ++;
		if (pageNumber == currentCalculatedPage){
			return NSMakeRange(pageBeginningTile, remainingTiles);
		}
	}

	[NSException raise:@"NSGetANewCoderException" format:@"your requested tile page %i is past the max page # %i",pageNumber,[self tilePageCount]];
	
	return NSMakeRange(NSNotFound, 0);
	
	
}

-(void)		layoutTilePageNumber:(NSInteger)startTilePage{
	//determine tiles to display
	
	BOOL needsReversePaging =	NO;
	BOOL needsForwardPaging =	NO;
	NSRange pageTileRange	=	[self tileRangeForPage:startTilePage needsForwardPagination:&needsForwardPaging needsBackwardPagination:&needsReversePaging];
	
	if (pageTileRange.location == NSNotFound){
		if (startTilePage > 1)
			[self setCurrentPage:1];
		return;
	}
	
	//begin layout
	
	NSInteger tileLayoutIndex	=	0;
	NSMutableSet *	tilesToRemove	= [NSMutableSet setWithSet:_displayedTileViews];
	
	if (needsReversePaging){
		
		
		UIView *previousTilePageButtonContainerView = [[UIView alloc] initWithFrame:[self frameForTileNumber:tileLayoutIndex]];
		tileLayoutIndex++;
		
		UIImageView *reversePagingImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"swypTiledContentPreviousPageImage.png"]];
		float leftForwardMargin = (previousTilePageButtonContainerView.frame.size.width - reversePagingImage.frame.size.width)/2;
		float upperForwardMargin = (previousTilePageButtonContainerView.frame.size.height - reversePagingImage.frame.size.height)/2;
		reversePagingImage.frame = CGRectMake(leftForwardMargin, upperForwardMargin, reversePagingImage.frame.size.width,reversePagingImage.frame.size.height);
		[previousTilePageButtonContainerView addSubview:reversePagingImage];
		SRELS(reversePagingImage);
		
		
		UITapGestureRecognizer *pageFlipPressRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(flipTilePageBack:)];
		[previousTilePageButtonContainerView addGestureRecognizer:pageFlipPressRecognizer];
		SRELS(pageFlipPressRecognizer);
		
		
		[self.view addSubview:previousTilePageButtonContainerView];
		[_displayedTileViews addObject:previousTilePageButtonContainerView];
		[tilesToRemove removeObject:previousTilePageButtonContainerView];

		SRELS(previousTilePageButtonContainerView);
	}

	for (int nextTileIndex = pageTileRange.location; nextTileIndex < pageTileRange.location + pageTileRange.length; nextTileIndex ++){
		
		UIView *nextTile = [_delegate tileViewAtIndex:nextTileIndex forTiledContentController:self];
		if (nextTile == nil){
			[NSException raise:@"NSYou'reTryingToScamThisClassException" format:@"you told my class you'd give a tile at index %i, but it's nil-- what kind of game are you trying to pull here?",nextTileIndex];

		}
		
		if ([_displayedTileViews containsObject:nextTile] == NO){
			
			[self.view addSubview:nextTile];
			
			double preAlpha	= nextTile.alpha;
			nextTile.alpha	= 0;
			[UIView animateWithDuration:.4 animations:^{nextTile.alpha = preAlpha;} completion:nil];
			
			CGRect tileFrame	= [self frameForTileNumber:tileLayoutIndex];
			if (CGSizeEqualToSize(tileFrame.size, nextTile.size) == NO){
				tileFrame.size	= nextTile.size;
			}
			[nextTile setFrame:tileFrame];

			[_displayedTileViews addObject:nextTile];
			[tilesToRemove removeObject:nextTile];
			
		}else {
			[UIView beginAnimations:@"moveAnimations" context:nil];
			[UIView setAnimationDuration:.4];
			[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
			[UIView setAnimationBeginsFromCurrentState:TRUE];
						
			[_displayedTileViews addObject:nextTile];
			[tilesToRemove removeObject:nextTile];
			[nextTile setFrame:[self frameForTileNumber:tileLayoutIndex]];

			[UIView commitAnimations];
		}
		
		tileLayoutIndex++;
	}
	

	if (needsForwardPaging){
		
		
		UIView *nextTilePageButtonContainerView = [[UIView alloc] initWithFrame:[self frameForTileNumber:tileLayoutIndex]];
		
		UIImageView *forwardPagingImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"swypTiledContentNextPageImage.png"]];
		float leftForwardMargin = (nextTilePageButtonContainerView.frame.size.width - forwardPagingImage.frame.size.width)/2;
		float upperForwardMargin = (nextTilePageButtonContainerView.frame.size.height - forwardPagingImage.frame.size.height)/2;
		forwardPagingImage.frame = CGRectMake(leftForwardMargin, upperForwardMargin, forwardPagingImage.frame.size.width,forwardPagingImage.frame.size.height);
		[nextTilePageButtonContainerView addSubview:forwardPagingImage];
		SRELS(forwardPagingImage);
		
		
		UITapGestureRecognizer *pageFlipPressRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(flipTilePageForward:)];
		[nextTilePageButtonContainerView addGestureRecognizer:pageFlipPressRecognizer];
		SRELS(pageFlipPressRecognizer);
		
		
		[self.view addSubview:nextTilePageButtonContainerView];
		[_displayedTileViews addObject:nextTilePageButtonContainerView];
		[tilesToRemove removeObject:nextTilePageButtonContainerView];

		SRELS(nextTilePageButtonContainerView);		

		tileLayoutIndex++;
	}
	
	for (UIView * removeTileView in tilesToRemove){
		[removeTileView removeFromSuperview];
	}
	
}

-(void)	setCurrentPage:(NSInteger)nextPage{
	if (nextPage != _currentPage){
		_currentPage = nextPage;
		[self layoutTilePageNumber:_currentPage];
	}
}

-(void)		reloadTileObjectData{
	[self layoutTilePageNumber:_currentPage];
}

-(CGRect)frameForTileNumber:(NSInteger)tileNumber{
	
	CGPoint startRectPoint		=	_layoutStartPoint;
	
	CGRect frameRect = CGRectZero;
	frameRect.size = _tileSize;
	frameRect.origin = startRectPoint;
	
	NSInteger row			= tileNumber / (int)_maxTileColumns;
	NSInteger column		= tileNumber % (int)_maxTileColumns;
	
	frameRect.origin.x += column * (_tileSize.width + _tileMarginSize.width);
	frameRect.origin.y += row *  (_tileSize.height + _tileMarginSize.height);
	
	//now fit in the center of the cell
	//be sure that the object's size is smaller or equal to the cellSize
//	frameRect.origin.x += (_tileSize.width - notebookObjectViewSize.width)/2;
//	frameRect.origin.y += (_tileSize.height - notebookObjectViewSize.height)/2;
	
	return frameRect;
}

#pragma mark interactivity


-(void)flipTilePageForward:(UIGestureRecognizer*)recognizer{
	[self viewNextTilePageAnimated:TRUE];
}
-(void)flipTilePageBack:(UIGestureRecognizer*)recognizer{	
	[self viewPreviousTilePageAnimated:TRUE];
}



-(void)viewPreviousTilePageAnimated:(BOOL)animate{	
	
	if (_currentPage <= 1)
		return;
	
		
	[UIView performPageSwitchAnimationWithExistingView:self.view viewUpdateBlock:^(void){
		[self setCurrentPage:_currentPage -1 ];
	}
									 nextViewGrabBlock:nil direction:UIViewPageAnimationDirectionRight];
	
}

-(void)viewNextTilePageAnimated:(BOOL)animate{	
	
	if ([self tilePageCount] < _currentPage + 1 ) //needs room for one more page, and currentPage is 0-delimited while count is 1-delimited
		return;
	
	
	
	[UIView performPageSwitchAnimationWithExistingView:self.view viewUpdateBlock:^(void){
				[self setCurrentPage:_currentPage +1 ];
		
	}
						nextViewGrabBlock:nil direction:UIViewPageAnimationDirectionLeft];	
}


#pragma mark supplementalInfo
-(UIView*) loadingStatusView{
	if (_loadingStatusView == nil){
		[self showLoadingStatusViewWithLabelText:@"Loading..." withIndicatorAnimating:TRUE];
		[_loadingStatusView setHidden:TRUE];
	}
	
	return _loadingStatusView;
}

-(void)showLoadingStatusViewWithLabelText:(NSString*)labelText withIndicatorAnimating:(BOOL)animate{
	if (_loadingStatusView != nil){
		[_loadingStatusView removeFromSuperview];
		SRELS(_loadingStatusView);
	}
	
	if (labelText == nil && animate == FALSE)
		return;
	
	_loadingStatusView = [[UIView alloc] init];
	_loadingStatusView.frame		= CGRectMake(124, 228.0, 346, 45.0);
	_loadingStatusView.center	= self.view.center; 
	_loadingStatusView.hidden	= NO;
	
	
	UIActivityIndicatorView *activityindicatorview5 = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	activityindicatorview5.frame = CGRectMake(124, 13.0, 20.0, 20.0);
	activityindicatorview5.alpha = 1.000;
	activityindicatorview5.autoresizesSubviews = YES;
	activityindicatorview5.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
	activityindicatorview5.clearsContextBeforeDrawing = YES;
	activityindicatorview5.clipsToBounds = NO;
	activityindicatorview5.contentMode = UIViewContentModeScaleToFill;
	activityindicatorview5.contentStretch = CGRectFromString(@"{{0, 0}, {1, 1}}");
	activityindicatorview5.hidden = NO;
	activityindicatorview5.hidesWhenStopped = NO;
	activityindicatorview5.multipleTouchEnabled = NO;
	activityindicatorview5.opaque = NO;
	activityindicatorview5.tag = 0;
	activityindicatorview5.userInteractionEnabled = YES;
	[activityindicatorview5 startAnimating];
	
	
	UILabel *loadingStatusViewLabel = [[UILabel alloc] init];
	loadingStatusViewLabel.frame = CGRectMake(162, 11.0, 164, 24.0);
	loadingStatusViewLabel.adjustsFontSizeToFitWidth = YES;
	loadingStatusViewLabel.alpha = 1.000;
	loadingStatusViewLabel.autoresizesSubviews = YES;
	loadingStatusViewLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
	loadingStatusViewLabel.clearsContextBeforeDrawing = YES;
	loadingStatusViewLabel.clipsToBounds = YES;
	loadingStatusViewLabel.contentMode = UIViewContentModeLeft;
	loadingStatusViewLabel.contentStretch = CGRectFromString(@"{{0, 0}, {1, 1}}");
	loadingStatusViewLabel.enabled = YES;
	loadingStatusViewLabel.hidden = NO;
	loadingStatusViewLabel.highlightedTextColor = [UIColor colorWithWhite:1.000 alpha:1.000];
	loadingStatusViewLabel.lineBreakMode = UILineBreakModeTailTruncation;
	loadingStatusViewLabel.minimumFontSize = 10.000;
	loadingStatusViewLabel.font	=	[UIFont fontWithName:@"Marker Felt" size:17];
	loadingStatusViewLabel.multipleTouchEnabled = NO;
	loadingStatusViewLabel.numberOfLines = 1;
	loadingStatusViewLabel.opaque = NO;
	loadingStatusViewLabel.shadowOffset = CGSizeMake(0.0, -1.0);
	loadingStatusViewLabel.tag = 0;
	loadingStatusViewLabel.text = labelText;
	loadingStatusViewLabel.textAlignment = UITextAlignmentLeft;
	loadingStatusViewLabel.textColor = [UIColor colorWithRed:0.000 green:0.000 blue:0.000 alpha:1.000];
	loadingStatusViewLabel.backgroundColor = [UIColor clearColor];
	loadingStatusViewLabel.userInteractionEnabled = NO;
	
	if (animate == NO){
		CGRect preRect							= loadingStatusViewLabel.frame;
		preRect.size							= CGSizeMake(346, 24.0);
		preRect.origin							= CGPointMake((_loadingStatusView.frame.size.width - preRect.size.width)/2, preRect.origin.y);
		loadingStatusViewLabel.frame			= preRect;
		loadingStatusViewLabel.textAlignment	= UITextAlignmentCenter;
	}
	
	
	if (animate){
		UIActivityIndicatorView *loadingStatusViewIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		loadingStatusViewIndicator.frame = CGRectMake(124, 13.0, 20.0, 20.0);
		loadingStatusViewIndicator.alpha = 1.000;
		loadingStatusViewIndicator.autoresizesSubviews = YES;
		loadingStatusViewIndicator.clearsContextBeforeDrawing = YES;
		loadingStatusViewIndicator.clipsToBounds = NO;
		loadingStatusViewIndicator.hidden = NO;
		loadingStatusViewIndicator.hidesWhenStopped = NO;
		loadingStatusViewIndicator.multipleTouchEnabled = NO;
		loadingStatusViewIndicator.opaque = NO;
		loadingStatusViewIndicator.tag = 0;
		loadingStatusViewIndicator.userInteractionEnabled = YES;
		[loadingStatusViewIndicator startAnimating];
		
		[_loadingStatusView addSubview:loadingStatusViewIndicator];
		SRELS(loadingStatusViewIndicator);

		
	}
	[_loadingStatusView addSubview:loadingStatusViewLabel];
	
	SRELS(loadingStatusViewLabel);
	SRELS(activityindicatorview5);
	
	[self.view addSubview:_loadingStatusView];
	
}

#pragma mark lifecycle
-(void)	viewDidLoad{
	[super viewDidLoad];
	
	[self.view setFrame:_tileDisplayFrame];
		
//	UISwipeGestureRecognizer *swipeLeftGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(flipTilePageForward:)];
//	[swipeLeftGesture setDirection:UISwipeGestureRecognizerDirectionLeft];
//	[swipeLeftGesture setNumberOfTouchesRequired:2];
//	[self.view addGestureRecognizer:swipeLeftGesture];
//	SRELS(swipeLeftGesture);
//	
//	UISwipeGestureRecognizer *swipeRightGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(flipTilePageBack:)];
//	[swipeRightGesture setDirection:UISwipeGestureRecognizerDirectionRight];
//	[swipeRightGesture setNumberOfTouchesRequired:2];
//	[self.view addGestureRecognizer:swipeRightGesture];
//	SRELS(swipeRightGesture);
	
	[self setCurrentPage:1];
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
	SRELS(_loadingStatusView);
	
	[super dealloc];
}


@end
