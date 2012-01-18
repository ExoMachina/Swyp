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

#import "swypWorkspaceBackgroundView.h"

@interface swypWorkspaceViewController (Private)

-(void)animateArrows;
-(void)stopArrows;
    
@end

@implementation swypWorkspaceViewController
@synthesize connectionManager = _connectionManager, contentManager = _contentManager, showContentWithoutConnection = _showContentWithoutConnection, worspaceDelegate = _worspaceDelegate;

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
	[sessionViewController.view setCenter:[[[session representedCandidate] matchedLocalSwypInfo]endPoint]];
	[self.view addSubview:sessionViewController.view];
	[self.view setBackgroundColor:[[session sessionHueColor] colorWithAlphaComponent:.4]];
	[[self contentManager] maintainSwypSessionViewController:sessionViewController];
	SRELS(sessionViewController);
	
	
	UIView *swypBeginningContentView	=	[[[session representedCandidate] matchedLocalSwypInfo] swypBeginningContentView];
#pragma mark CLUDGE!
#pragma mark TODO: make some runloop excuse for this not being a cludge
	NSBlockOperation *	contentSwypOp	=	[NSBlockOperation blockOperationWithBlock:^{
		if (swypBeginningContentView != nil && [[_contentManager contentDisplayController] respondsToSelector:@selector(contentIndexMatchingSwypOutView:)]){
			NSInteger swypOutContentIndex	=	[[_contentManager contentDisplayController] contentIndexMatchingSwypOutView:swypBeginningContentView];
			if (swypOutContentIndex > -1){
				EXOLog(@"Sending 'contentSwyp' content at index: %i", swypOutContentIndex );
				[_contentManager sendContentAtIndex:swypOutContentIndex throughConnectionSession:session];
				[[_contentManager contentDisplayController] returnContentAtIndexToNormalLocation:swypOutContentIndex animated:TRUE];
			}
		}
	}];
	
	[NSTimer scheduledTimerWithTimeInterval:.2 target:contentSwypOp selector:@selector(start) userInfo:nil repeats:NO];
		
}
-(void)	swypConnectionSessionWasInvalidated:(swypConnectionSession*)session	withConnectionManager:(swypConnectionManager*)manager error:(NSError*)error{
	
}

//update UI
-(void) swypConnectionMethodsUpdated:(swypConnectionMethod)availableMethods withConnectionManager:(swypConnectionManager*)manager{
		
	if ([manager activeConnectionClass] == swypConnectionClassWifiAndCloud){
		if (availableMethods & (swypConnectionMethodWifiLoc |swypConnectionMethodWifiCloud | swypConnectionMethodWWANCloud)){
			[_swypNetworkInterfaceClassButton setImage:[UIImage imageNamed:@"connectivity-world-enabled.png"] forState:UIControlStateNormal];
		}else{
			[_swypNetworkInterfaceClassButton setImage:[UIImage imageNamed:@"connectivity-world-disabled.png"] forState:UIControlStateNormal];
		}
	}else if ([manager activeConnectionClass] == swypConnectionClassBluetooth) {
		if (availableMethods & swypConnectionMethodBluetooth){
			[_swypNetworkInterfaceClassButton setImage:[UIImage imageNamed:@"connectivity-bluetooth-enabled.png"] forState:UIControlStateNormal];
		}else{
			[_swypNetworkInterfaceClassButton setImage:[UIImage imageNamed:@"connectivity-bluetooth-disabled.png"] forState:UIControlStateNormal];
		}
	}
	

}



#pragma mark - 
#pragma mark swypContentInteractionManagerDelegate
-(void) setupWorkspacePromptUIForAllConnectionsClosedWithInteractionManager:(swypContentInteractionManager*)interactionManager{
	if (_swypPromptImageView == nil){
		_swypPromptImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"swypPromptHud.png"]];
		[_swypPromptImageView setUserInteractionEnabled:FALSE];
	}
	
	//we're phasing out wifi as a availability-selectable type in favor of globe vs bluetooth
	
	
	if (_swypNetworkInterfaceClassButton == nil){
		_swypNetworkInterfaceClassButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 38, 27)];
		[_swypNetworkInterfaceClassButton setShowsTouchWhenHighlighted:TRUE];
		[_swypNetworkInterfaceClassButton addTarget:self action:@selector(networkInterfaceClassButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
		[_swypNetworkInterfaceClassButton setEnabled:FALSE];
	}
	
	[self _setupUIForCurrentOrientation];

	
	
	//set background images
	[self swypConnectionMethodsUpdated:[_connectionManager availableConnectionMethods] withConnectionManager:nil];
	
	[_swypNetworkInterfaceClassButton setAlpha:0];
	[_swypPromptImageView setAlpha:0];
	[self.view addSubview:_swypNetworkInterfaceClassButton];	
	[self.view addSubview:_swypPromptImageView];
	[self.view sendSubviewToBack:_swypPromptImageView];

	[UIView animateWithDuration:.75 animations:^{
		[_swypPromptImageView setAlpha:0.5];
		[_swypNetworkInterfaceClassButton setAlpha:1];
	}completion:nil];
}

-(void) setupWorkspacePromptUIForConnectionEstablishedWithInterationManager:(swypContentInteractionManager*)interactionManager{

	if ([_swypPromptImageView superview] != nil){
		[UIView animateWithDuration:.75 animations:^{
			[_swypPromptImageView setAlpha:0];
			[_swypNetworkInterfaceClassButton setAlpha:0];
		}completion:nil];
	}
}

#pragma mark -
#pragma mark public
-(swypContentInteractionManager*)	contentManager{
	if (_contentManager == nil){
		_contentManager = [[swypContentInteractionManager alloc] initWithMainWorkspaceView:self.view];
		[_contentManager setInteractionManagerDelegate:self];
		
		#pragma mark CLUDGE!
		#warning CLUDGE!
		//	this is where plainly	[_contentManager initializeInteractionWorkspace]; should be; It's cludged because otherwise contentInteractionController is un-interactable 
		//	So we just run this at the beginning of the next runLoop
		NSBlockOperation * initializeWorkspaceOperation = [NSBlockOperation blockOperationWithBlock:^{
			[[self contentManager] initializeInteractionWorkspace];
		}];
		[[NSOperationQueue mainQueue] addOperation:initializeWorkspaceOperation];
		[[NSOperationQueue mainQueue] setSuspended:FALSE];

	}
	
	return _contentManager;
}

#pragma mark -
#pragma mark workspaceInteraction
-(void)setShowContentWithoutConnection:(BOOL)showContentWithoutConnection{
	_showContentWithoutConnection = showContentWithoutConnection;
	if ((_contentManager != nil || _showContentWithoutConnection == TRUE) && [[self contentManager] showContentBeforeConnection] != showContentWithoutConnection){
		SRELS(_contentManager);
		[self contentManager];
	}
}


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

-(void)	leaveWorkspaceButtonPressed:(id)sender {
    EXOLog(@"PRESSED IT.");
	[_worspaceDelegate delegateShouldDismissSwypWorkspace:self];
}
- (void)animateArrows:(id)sender {
    [UIView animateWithDuration:0.5 delay:0 options:(UIViewAnimationOptionAutoreverse|UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionRepeat) animations:^(void){
        _downArrowView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, 10);
    } completion:nil];
}
- (void)stopArrows:(id)sender {
    _downArrowView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, 0);
}


#pragma mark UIViewController
-(id)	initWithWorkspaceDelegate:(id<swypWorkspaceDelegate>)	worspaceDelegate{
	if (self = [super initWithNibName:nil bundle:nil]){
		[self setModalPresentationStyle:	UIModalPresentationFullScreen];
		[self setModalTransitionStyle:		UIModalTransitionStyleCoverVertical];
		
		_worspaceDelegate	=	worspaceDelegate;
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
}

-(void) viewWillDisappear:(BOOL)animated{
	[super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
}

-(void)	viewDidLoad{
	[super viewDidLoad];
        
	swypWorkspaceBackgroundView * backgroundView	= [[[swypWorkspaceBackgroundView alloc] initWithFrame:self.view.frame] autorelease];
	self.view	= backgroundView;
    self.view.opaque = YES;
    
    _downArrowView = [[UIView alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, 20)];
    _downArrowView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"down_arrow"]];
    // workaround for bug in iOS 4
    [_downArrowView.layer setOpaque:NO];
    [self.view addSubview:_downArrowView];
    
    UIButton *curlButton = [UIButton buttonWithType:UIButtonTypeCustom];
    curlButton.adjustsImageWhenHighlighted = YES;
    curlButton.frame = CGRectMake(0, 0, self.view.frame.size.width, 60);
    curlButton.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"top_curl"]];
    [curlButton.layer setOpaque:NO];
    
    // weird ios4 bug
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 5) {
        [curlButton addTarget:self action:@selector(animateArrows:) forControlEvents:UIControlEventTouchDown];
    }
    
    [curlButton addTarget:self action:@selector(leaveWorkspaceButtonPressed:) 
         forControlEvents:UIControlEventTouchUpInside];
         
    [curlButton addTarget:self action:@selector(stopArrows:) forControlEvents:(UIControlEventTouchCancel|UIControlEventTouchUpInside|UIControlEventTouchDragOutside)];
    
    UISwipeGestureRecognizer *swipeDownRecognizer = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(leaveWorkspaceButtonPressed:)] autorelease];
    swipeDownRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
    [curlButton addGestureRecognizer:swipeDownRecognizer];
    
    [self.view addSubview:curlButton];
	
	[[self connectionManager] startServices];
	
	swypInGestureRecognizer*	swypInRecognizer	=	[[swypInGestureRecognizer alloc] initWithTarget:self action:@selector(swypInGestureChanged:)];
	[swypInRecognizer setDelegate:self];
	[swypInRecognizer setDelaysTouchesBegan:FALSE];
	[swypInRecognizer setDelaysTouchesEnded:FALSE];
	[swypInRecognizer setCancelsTouchesInView:FALSE];
	[self.view addGestureRecognizer:swypInRecognizer];
	SRELS(swypInRecognizer);

	swypOutGestureRecognizer*	swypOutRecognizer	=	[[swypOutGestureRecognizer alloc] initWithTarget:self action:@selector(swypOutGestureChanged:)];
	[swypOutRecognizer setDelegate:self];
	[swypOutRecognizer setDelaysTouchesBegan:FALSE];
	[swypOutRecognizer setDelaysTouchesEnded:FALSE];
	[swypOutRecognizer setCancelsTouchesInView:FALSE];
	[self.view addGestureRecognizer:swypOutRecognizer];	
	SRELS(swypOutRecognizer);
    
	[self setupWorkspacePromptUIForAllConnectionsClosedWithInteractionManager:nil];    
}

-(void)	dealloc{
	
    SRELS( _downArrowView);
	SRELS( _swypPromptImageView);
	SRELS(_swypNetworkInterfaceClassButton);
    
	[super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{	
	[super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
	
	return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	
	[UIView animateWithDuration:.5 animations:^{
		[self _setupUIForCurrentOrientation];
	}];
}
			

-(void) _setupUIForCurrentOrientation{
	[_swypPromptImageView setFrame:CGRectMake(self.view.size.width/2 - (250/2), self.view.size.height/2 - (250/2), 250, 250)];
	[_swypNetworkInterfaceClassButton setOrigin:CGPointMake(9, self.view.size.height-32)];
}

- (void)didReceiveMemoryWarning {
	if ([_swypPromptImageView superview] == nil){
		SRELS(_swypPromptImageView);
		SRELS(_swypNetworkInterfaceClassButton);
	}
}

@end
