//
//  swypWorkspaceViewController.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import "swypWorkspaceViewController.h"
#import "swypInGestureRecognizer.h"
#import "swypOutGestureRecognizer.h"
#import "swypSessionViewController.h"
#include <QuartzCore/QuartzCore.h>


static swypWorkspaceViewController	* _singleton_sharedSwypWorkspace = nil;
@implementation swypWorkspaceViewController
@synthesize connectionManager = _connectionManager, contentManager = _contentManager;
@synthesize contentDataSource;

#pragma mark -
#pragma mark swypConnectionManagerDelegate
-(swypConnectionManager*)	connectionManager{
	if (_connectionManager == nil){
		_connectionManager = [[swypConnectionManager alloc] init];
		[_connectionManager setDelegate:self];
	}
	
	return _connectionManager;
}

-(void)	swypConnectionSessionWasCreated:(swypConnectionSession*)session		withConnectionManager:(swypConnectionManager*)manager{
	
	swypSessionViewController * sessionViewController	= [[swypSessionViewController alloc] initWithConnectionSession:session];
    // Position the sessionVC
    swypInfoRef *connectionSwypeInfo = [[session representedCandidate] matchedLocalSwypInfo];
	[sessionViewController.view setCenter:connectionSwypeInfo.endPoint];
    
    swypScreenEdgeType screenEdge = [connectionSwypeInfo screenEdgeOfSwyp];
    CGPoint oldCenter = sessionViewController.view.center;
    switch (screenEdge) {
        case swypScreenEdgeTypeLeft:
            [sessionViewController.view setCenter:CGPointMake(0, oldCenter.y)];
            break;
        case swypScreenEdgeTypeRight:
            [sessionViewController.view setCenter:CGPointMake(_mainWorkspaceView.size.width, oldCenter.y)];
            break;
        case swypScreenEdgeTypeBottom:
            [sessionViewController makeLandscape];
            [sessionViewController.view setCenter:CGPointMake(oldCenter.x, _mainWorkspaceView.size.height)];
            break;
        default:
            break;
    }
    
	BOOL handledSessionDisplay = FALSE;
	if (_mainWorkspaceView != nil  && ([_mainWorkspaceView isDescendantOfView:[[UIApplication sharedApplication] keyWindow]] == NO) && [_allWorkspaceViews count] > 1){

		for (swypWorkspaceView * workspaceView	in _allWorkspaceViews){
			if ([workspaceView isDescendantOfView:[[UIApplication sharedApplication] keyWindow]]){
		
				[workspaceView.backgroundView addSubview:sessionViewController.view];
				[workspaceView.backgroundView setBackgroundColor:[[session sessionHueColor] colorWithAlphaComponent:.4]];	
				handledSessionDisplay	=	TRUE;
			}
		}

	}
	if (handledSessionDisplay == NO){
		[_mainWorkspaceView.backgroundView addSubview:sessionViewController.view];
		[_mainWorkspaceView.backgroundView setBackgroundColor:[[session sessionHueColor] colorWithAlphaComponent:.4]];	
		handledSessionDisplay	=	TRUE;
	}
	
	[[self contentManager] maintainSwypSessionViewController:sessionViewController];
	SRELS(sessionViewController);
	
	
	UIView *swypBeginningContentView	=	[[[session representedCandidate] matchedLocalSwypInfo] swypBeginningContentView];
	NSString * contentID	=	[[_contentManager contentViewsByContentID] keyForObject:swypBeginningContentView];


	if (StringHasText(contentID)){

#pragma mark TODO: make some runloop excuse for this not being a cludge		
		//sadly I think we're just messy
		NSBlockOperation *	contentSwypOp	=	[NSBlockOperation blockOperationWithBlock:^{
			
				[_contentManager sendContentWithID:contentID throughConnectionSession:session];
		}];
		
		[NSTimer scheduledTimerWithTimeInterval:.2 target:contentSwypOp selector:@selector(start) userInfo:nil repeats:NO];

	}
			
}
-(void)	swypConnectionSessionWasInvalidated:(swypConnectionSession*)session	withConnectionManager:(swypConnectionManager*)manager error:(NSError*)error{
}

//update UI
-(void) swypConnectionMethodsUpdated:(swypConnectionMethod)availableMethods withConnectionManager:(swypConnectionManager*)manager{
		
	for (swypWorkspaceView * workspaceView in _allWorkspaceViews){
		UIButton * interfaceButton	=	[workspaceView swypNetworkInterfaceClassButton];
		if ([manager activeConnectionClass] == swypConnectionClassWifiAndCloud){
			if (availableMethods & (swypConnectionMethodWifiLoc |swypConnectionMethodWifiCloud | swypConnectionMethodWWANCloud)){
				[interfaceButton setImage:[UIImage imageNamed:@"connectivity-world-enabled.png"] forState:UIControlStateNormal];
			}else{
				[interfaceButton setImage:[UIImage imageNamed:@"connectivity-world-disabled.png"] forState:UIControlStateNormal];
			}
		}else if ([manager activeConnectionClass] == swypConnectionClassBluetooth) {
			if (availableMethods & swypConnectionMethodBluetooth){
				[interfaceButton setImage:[UIImage imageNamed:@"connectivity-bluetooth-enabled.png"] forState:UIControlStateNormal];
			}else{
				[interfaceButton setImage:[UIImage imageNamed:@"connectivity-bluetooth-disabled.png"] forState:UIControlStateNormal];
			}
		}
	}

}

-(void) swypConnectionMethod:(swypConnectionMethod)method setReadyStatus:(BOOL)isReady withConnectionManager:(swypConnectionManager*)manager{
	for (swypWorkspaceView * workspaceView in _allWorkspaceViews){
		SwypPromptImageView * promptImageView	=	[workspaceView swypPromptImageView];
		if (method == swypConnectionMethodBluetooth){
			if ([_connectionManager activeConnectionClass] == swypConnectionClassBluetooth){
				[promptImageView showBluetoothLoadingPrompt:!isReady];
			}else{
				[promptImageView showBluetoothLoadingPrompt:FALSE];
			}
		}
	}
}


#pragma mark swypSwypableContentSuperviewWorkspaceDelegate
-(UIView*)workspaceView{
	return self.view; //or _mainWorkspaceView
}
-(void)	presentContentSwypWorkspaceAtopViewController:(UIViewController*)controller withContentView:(swypSwypableContentSuperview*)contentView swypableContentImage:(UIImage*)contentImage forContentOfID:(NSString*)contentID atRect:(CGRect)contentRect{
	//Causes the workspace to appear, and automatically positions the content of contentID under the user's finger
	//
	
	_openingOrientation	=	[[UIApplication sharedApplication] statusBarOrientation];

	UIGraphicsBeginImageContextWithOptions([[[UIApplication sharedApplication] keyWindow] frame].size,YES, 0);
	[[[UIApplication sharedApplication] keyWindow].layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *image	= UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	if (_openingOrientation == UIInterfaceOrientationLandscapeLeft){
		image		= [UIImage imageWithCGImage:image.CGImage scale:0 orientation:UIImageOrientationRight];
	}else if(_openingOrientation == UIInterfaceOrientationLandscapeRight){
		image		= [UIImage imageWithCGImage:image.CGImage scale:0 orientation:UIImageOrientationLeft];			
	}else if (_openingOrientation == UIInterfaceOrientationPortraitUpsideDown){
		image		= [UIImage imageWithCGImage:image.CGImage scale:0 orientation:UIImageOrientationDown];			
	}
	
	[_mainWorkspaceView.prettyOverlay setBackgroundColor:nil];
	[_mainWorkspaceView.prettyOverlay setAlpha:.1];
	[_mainWorkspaceView.prettyOverlay setImage:image];
	
	
	[self _setupUIForCurrentOrientation];
	
	[self setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];

	[_contentManager handleContentSwypOfContentWithID:contentID withContentImage:contentImage toRect:contentRect];
		
	[UIView animateWithDuration:.3 animations:nil completion:^(BOOL complete){
		[controller presentModalViewController:self animated:TRUE];
	}];
	
}


#pragma mark -
#pragma mark public

-(void)presentContentWorkspaceAtopViewController:(UIViewController*)controller{
	
	_openingOrientation	=	[[UIApplication sharedApplication] statusBarOrientation];
	[self _setupUIForCurrentOrientation];
	
	[_mainWorkspaceView.prettyOverlay setImage:nil];
	[_mainWorkspaceView.prettyOverlay setAlpha:.4];
	[_mainWorkspaceView.prettyOverlay setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"swypWorkspaceBackground.png"]]];
		
	[self setModalTransitionStyle:UIModalTransitionStyleCoverVertical];	
	
	if ([controller modalViewController] == self){
		EXOLog(@"Already a modal view for object: %@", [controller description]);
		return;
	}

	[UIView animateWithDuration:.3 animations:nil completion:^(BOOL complete){
		[controller presentModalViewController:self animated:TRUE];
	}];

}

- (void)presentContentWorkspaceAtopRootViewController {
    [self presentContentWorkspaceAtopViewController:[[[UIApplication sharedApplication] keyWindow] rootViewController]];
}

-(void)setContentDataSource:(NSObject<swypContentDataSourceProtocol,swypConnectionSessionDataDelegate> *)dataSource{
	[[self contentManager] setContentDataSource:dataSource];
}

-(NSObject<swypContentDataSourceProtocol,swypConnectionSessionDataDelegate> *)contentDataSource{
	return [[self contentManager] contentDataSource];
}

-(swypContentInteractionManager*)	contentManager{
	if (_contentManager == nil){
		if (!self.view){//is hack
			
		}
		_contentManager = [[swypContentInteractionManager alloc] initWithMainWorkspaceView:_mainWorkspaceView];
		
		#pragma mark TODO: File bug; we need to wait until next runloop otherwise no user interface works
		//	this is where plainly	[_contentManager initializeInteractionWorkspace]; should be; It's cludged because otherwise contentInteractionController is un-interactable 
		//	So we just run this at the beginning of the next runLoop
		NSBlockOperation * initializeWorkspaceOperation = [NSBlockOperation blockOperationWithBlock:^{
			[[self contentManager] addSwypWorkspaceViewToInteractionLoop:_mainWorkspaceView];
		}];
		[[NSOperationQueue mainQueue] addOperation:initializeWorkspaceOperation];
		[[NSOperationQueue mainQueue] setSuspended:FALSE];

	}
	
	return _contentManager;
}

-(UIView*)backgroundView{
	return [[self.view subviews] objectAtIndex:0];
}

-(swypWorkspaceView*)	embeddableSwypWorkspaceViewForWithFrame:(CGRect)frame{
	swypWorkspaceView * workspaceView	=	[[swypWorkspaceView alloc] initWithFrame:frame workspaceTarget:self];
	[[self contentManager] addSwypWorkspaceViewToInteractionLoop:workspaceView];
	[_allWorkspaceViews addObject:workspaceView];
	[[self connectionManager] startServices];
	[self swypConnectionMethodsUpdated:[_connectionManager availableConnectionMethods] withConnectionManager:nil];
	return 	[workspaceView autorelease];
}

-(void)	removeEmbeddableSwypWorkspaceView:(swypWorkspaceView*)workspaceView{
	[_allWorkspaceViews removeObject:workspaceView];
	[[self contentManager] removeSwypWorkspaceViewFromInteractionLoop:workspaceView];
}

#pragma mark -
#pragma mark workspaceInteraction

-(void)networkInterfaceClassButtonPressed:(id)sender{
	if ([_connectionManager activeConnectionClass] == swypConnectionClassWifiAndCloud){
		[_connectionManager setUserPreferedConnectionClass:swypConnectionClassBluetooth];
	}else if ([_connectionManager activeConnectionClass] == swypConnectionClassBluetooth){
		[_connectionManager setUserPreferedConnectionClass:swypConnectionClassWifiAndCloud];
	}
}

#pragma mark -
#pragma mark UIGestureRecognizerDelegate
-(void)	swypInGestureChanged:(swypInGestureRecognizer*)recognizer{
	if (recognizer.state == UIGestureRecognizerStateRecognized){
		[_connectionManager swypInCompletedWithSwypInfoRef:[recognizer swypGestureInfo]];
	}
}

-(void)	swypOutGestureChanged:(swypOutGestureRecognizer*)recognizer{
	if (recognizer.state == UIGestureRecognizerStateBegan){
		[_connectionManager swypOutStartedWithSwypInfoRef:[recognizer swypGestureInfo]];
	}else if (recognizer.state == UIGestureRecognizerStateCancelled){
		[_connectionManager swypOutFailedWithSwypInfoRef:[recognizer swypGestureInfo]];
	}else if (recognizer.state == UIGestureRecognizerStateRecognized){
		[_connectionManager swypOutCompletedWithSwypInfoRef:[recognizer swypGestureInfo]];	
	}
}


-(BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
	
	if ([gestureRecognizer isKindOfClass:[swypGestureRecognizer class]])
		return TRUE;
	
	return FALSE;
}

-(void)	leaveWorkspaceWantedBySender:(id)sender {
	if ([sender isKindOfClass:[UIGestureRecognizer class]]){
		UIGestureRecognizer * recognizer = (UIGestureRecognizer*)sender;
		if ([recognizer state] == UIGestureRecognizerStateRecognized){
			[self dismissModalViewControllerAnimated:TRUE];			
		}
	}else{
		[self dismissModalViewControllerAnimated:TRUE];
	}

}


#pragma mark UIViewController

+(swypWorkspaceViewController*)	sharedSwypWorkspace{
	if (_singleton_sharedSwypWorkspace == nil){
		_singleton_sharedSwypWorkspace	=	[[swypWorkspaceViewController alloc] init];
	}
	return _singleton_sharedSwypWorkspace;
}

-(id) init{
	if (self = [super initWithNibName:nil bundle:nil]){
		_allWorkspaceViews		=			[[NSMutableSet alloc] init];
		[self setModalPresentationStyle:	UIModalPresentationFullScreen];
		[self setModalTransitionStyle:		UIModalTransitionStyleCoverVertical];		
	}
	return self;
}

-(id)	initWithWorkspaceDelegate:(id)	worspaceDelegate{
	if (self = [self init]){

	}
	return self;
}

-(void) viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
    	
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 5) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    } else {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    }
	[self _setupUIForCurrentOrientation];

}
-(void) viewDidAppear:(BOOL)animated{
	[super viewDidAppear:animated];
	//between viewWillAppear and viewDidLoad, the UIWindow is set as superview, and the frame is messed-up

	[self _setupUIForCurrentOrientation];
}

-(void) viewWillDisappear:(BOOL)animated{
	[super viewWillDisappear:animated];

    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
}

-(void)	viewDidLoad{
	[super viewDidLoad];
        
	CGSize windowSize	=	[UIScreen mainScreen].bounds.size;
	if (UIDeviceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])){
		windowSize		=	CGSizeMake(windowSize.height, windowSize.width);
	}
	
	_mainWorkspaceView	=	[[swypWorkspaceView alloc] initWithFrame :CGRectMake(0, 0, windowSize.width, windowSize.height) workspaceTarget:self];
	[_allWorkspaceViews addObject:_mainWorkspaceView];

	self.view								=	_mainWorkspaceView;
	
	[self.view setClipsToBounds:FALSE];

    UIButton *curlButton = [UIButton buttonWithType:UIButtonTypeCustom];
    curlButton.adjustsImageWhenHighlighted = YES;
    curlButton.frame = CGRectMake(0, 0, self.view.frame.size.width, 60);
    curlButton.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"top_curl"]];
	[curlButton setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [curlButton.layer setOpaque:NO];
    UIImage *gripperImage = [[UIImage imageNamed:@"grippers"] stretchableImageWithLeftCapWidth:8 topCapHeight:12];
    UIImageView *gripperView = [[UIImageView alloc] initWithImage:gripperImage];
    gripperView.frame = CGRectMake((curlButton.width - 32)/2, 16, 32, 12);
    gripperView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin;
    [curlButton addSubview:gripperView];
        
    [curlButton addTarget:self action:@selector(leaveWorkspaceWantedBySender:) 
         forControlEvents:UIControlEventTouchUpInside];
	[_mainWorkspaceView addSubview:curlButton];

	
	_leaveWorkspaceTapRecog	= [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(leaveWorkspaceWantedBySender:)] ;
	[_mainWorkspaceView.backgroundView addGestureRecognizer:_leaveWorkspaceTapRecog];
             
    _swipeDownRecognizer	= [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(leaveWorkspaceWantedBySender:)] ;
    _swipeDownRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
    [_mainWorkspaceView addGestureRecognizer:_swipeDownRecognizer];
    
	
	[[self connectionManager] startServices];
	    
	[self swypConnectionMethodsUpdated:[_connectionManager availableConnectionMethods] withConnectionManager:nil];
}

-(void)	dealloc{
	SRELS(_swipeDownRecognizer);
	SRELS(_leaveWorkspaceTapRecog);
	
	for (swypWorkspaceView * eachWorkspace in _allWorkspaceViews){
		[self removeEmbeddableSwypWorkspaceView:eachWorkspace];
	}
	
	SRELS(_allWorkspaceViews);
	SRELS(_mainWorkspaceView);
	
	[super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{	
	return TRUE;
//	return interfaceOrientation == _openingOrientation;
}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	
	[UIView animateWithDuration:2 delay:0 options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionAllowAnimatedContent animations:nil completion:^(BOOL complete){[self _setupUIForCurrentOrientation];}];
}
			

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

#pragma mark - Internal
-(void) _setupUIForCurrentOrientation{	
	//very oddness. 
	//here's the story w/ iPhone rot.
	//When the app opens this modal while in portrait, its superview is UIWindow, and its frame is  320X480
	//When the device rotates, UIWindow and the workspace UIView retain 320X480, yet the content of the view does rotate
	//weirdly, when the modal is displayed in landscape, its superview is NIL, and its frame is 480X320
	//when brought portrait, its superview become UIWindow(!), and its frame is 320X480; the workspace will not subsequently return to 480X320 through rotation
	
	
	//the following shows that we simply DO NOT trust our current orientation
	CGRect frameForOrientation = windowFrameForOrientation();
//	CGRect promptImageFrame	=	CGRectMake(frameForOrientation.size.width/2 - (250/2), frameForOrientation.size.height/2 - (250/2), 250, 250);
//	[_swypPromptImageView setFrame:promptImageFrame];
//	[_swypNetworkInterfaceClassButton setOrigin:CGPointMake(9, frameForOrientation.size.height-32)];
//	
//	//We now re-arrange the bounds for the subviews... For some reason it works HERE.
	[self.view setBounds:frameForOrientation];
//	[[[[self contentManager] contentDisplayController] view] setSize:windowFrameForOrientation().size];
}

@end
