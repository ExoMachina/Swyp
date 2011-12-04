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
#warning CLUDGE!
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
-(void) swypAvailableConnectionMethodsUpdated:(swypAvailableConnectionMethod)availableMethods withConnectionManager:(swypConnectionManager*)manager{
	
}



#pragma mark - 
#pragma mark swypContentInteractionManagerDelegate
-(void) setupWorkspacePromptUIForAllConnectionsClosedWithInteractionManager:(swypContentInteractionManager*)interactionManager{
	if (_swypPromptImageView == nil){
		_swypPromptImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"swypIPhonePromptHud.png"]];
		[_swypPromptImageView setUserInteractionEnabled:FALSE];
	}
	[_swypPromptImageView setFrame:CGRectMake(self.view.size.width/2 - (250/2), self.view.size.height/2 - (250/2), 250, 250)];
	
	if (_swypWifiAvailableButton == nil){
		_swypWifiAvailableButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 74, 50)];
		[_swypWifiAvailableButton setShowsTouchWhenHighlighted:TRUE];
		[_swypWifiAvailableButton addTarget:self action:@selector(wifiAvailableButtonPressed:) forControlEvents:UIControlEventTouchUpInside];	
		[_swypWifiAvailableButton setEnabled:FALSE];
	}
	[_swypWifiAvailableButton setOrigin:CGPointMake(self.view.size.width/2 - (200/2), self.view.size.height/2 + 30+ (250/2))];
	
	if (([_connectionManager availableConnectionMethods] & swypAvailableConnectionMethodWifi) == swypAvailableConnectionMethodWifi){
		[_swypWifiAvailableButton setImage:[UIImage imageNamed:@"wifi-logo-enabled.png"] forState:UIControlStateNormal];
	}else{
		[_swypWifiAvailableButton setImage:[UIImage imageNamed:@"wifi-logo-disabled.png"] forState:UIControlStateNormal];
	}
	
	
	if (_swypBluetoothAvailableButton == nil){
		_swypBluetoothAvailableButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 86)];
		[_swypBluetoothAvailableButton setShowsTouchWhenHighlighted:TRUE];
		[_swypBluetoothAvailableButton addTarget:self action:@selector(bluetoothAvailableButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
		[_swypBluetoothAvailableButton setEnabled:FALSE];
	}
	[_swypBluetoothAvailableButton setOrigin:CGPointMake(self.view.size.width/2 + 50, self.view.size.height/2 + 10+ (250/2))];
	
	if (([_connectionManager availableConnectionMethods] & swypAvailableConnectionMethodWifi) == swypAvailableConnectionMethodWifi){
		[_swypBluetoothAvailableButton setImage:[UIImage imageNamed:@"bluetooth-logo-enabled.png"] forState:UIControlStateNormal];
	}else{
		[_swypBluetoothAvailableButton setImage:[UIImage imageNamed:@"bluetooth-logo-disabled.png"] forState:UIControlStateNormal];
	}

	[_swypWifiAvailableButton setAlpha:0];
	[_swypBluetoothAvailableButton setAlpha:0];
	[_swypPromptImageView setAlpha:0];
	[self.view addSubview:_swypPromptImageView];
	[self.view sendSubviewToBack:_swypPromptImageView];
	[self.view addSubview:_swypWifiAvailableButton];
	[self.view addSubview:_swypBluetoothAvailableButton];
	
	[UIView animateWithDuration:.75 animations:^{
		[_swypPromptImageView setAlpha:1];
		[_swypWifiAvailableButton setAlpha:1];
		[_swypBluetoothAvailableButton setAlpha:1];
	}completion:nil];
}
-(void) setupWorkspacePromptUIForConnectionEstablishedWithInterationManager:(swypContentInteractionManager*)interactionManager{

	if ([_swypPromptImageView superview] != nil){
		[UIView animateWithDuration:.75 animations:^{
			[_swypPromptImageView setAlpha:0];
			[_swypWifiAvailableButton setAlpha:0];
			[_swypBluetoothAvailableButton setAlpha:0];
		}completion:^(BOOL completed){
			[_swypPromptImageView removeFromSuperview];	
			[_swypWifiAvailableButton removeFromSuperview];	
			[_swypBluetoothAvailableButton removeFromSuperview];	
		}];
	}
}

#pragma mark -
#pragma mark public
-(swypContentInteractionManager*)	contentManager{
	if (_contentManager == nil){
		_contentManager = [[swypContentInteractionManager alloc] initWithMainWorkspaceView:self.view showingContentBeforeConnection:_showContentWithoutConnection];
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


-(void)bluetoothAvailableButtonPressed:(id)sender{
	
}
-(void)wifiAvailableButtonPressed:(id)sender{
	
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

-(void)	leaveWorkspaceRecognizerChanged: (UITapGestureRecognizer*)recognizer{
	if (recognizer.state == UIGestureRecognizerStateRecognized){
		[_worspaceDelegate delegateShouldDismissSwypWorkspace:self];
	}
}


#pragma mark UIViewController
-(id)	initWithWorkspaceDelegate:(id<swypWorkspaceDelegate>)	worspaceDelegate{
	if (self = [super initWithNibName:nil bundle:nil]){
		[self setModalPresentationStyle:	UIModalPresentationFullScreen];
		[self setModalTransitionStyle:		UIModalTransitionStyleCrossDissolve];
		
		_worspaceDelegate	=	worspaceDelegate;
	}
	return self;
}
-(void)	viewDidLoad{
	[super viewDidLoad];

	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:YES];	
	
	swypWorkspaceBackgroundView * backgroundView	= [[swypWorkspaceBackgroundView alloc] initWithFrame:self.view.frame];
	self.view	= backgroundView;
	
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

	UITapGestureRecognizer * leaveWorkspaceRecognizer	=	[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(leaveWorkspaceRecognizerChanged:)];
	[leaveWorkspaceRecognizer setNumberOfTapsRequired:2];
	[leaveWorkspaceRecognizer setDelaysTouchesBegan:FALSE];
	[leaveWorkspaceRecognizer setDelaysTouchesEnded:FALSE];
	[leaveWorkspaceRecognizer setCancelsTouchesInView:FALSE];
	[self.view addGestureRecognizer:leaveWorkspaceRecognizer];
	SRELS(leaveWorkspaceRecognizer);
	
	[self setupWorkspacePromptUIForAllConnectionsClosedWithInteractionManager:nil];
		
}
-(void)	dealloc{
	
	SRELS( _swypPromptImageView);
	SRELS(_swypWifiAvailableButton);
	SRELS(_swypBluetoothAvailableButton);
	
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
		[_swypPromptImageView setFrame:CGRectMake(self.view.size.width/2 - (250/2), self.view.size.height/2 - (250/2), 250, 250)];
		[_swypWifiAvailableButton setOrigin:CGPointMake(self.view.size.width/2 - (200/2), self.view.size.height/2 + 30+ (250/2))];
		[_swypBluetoothAvailableButton setOrigin:CGPointMake(self.view.size.width/2 + 50, self.view.size.height/2 + 10+ (250/2))];
	}];
}

- (void)didReceiveMemoryWarning {
	if ([_swypPromptImageView superview] == nil){
		SRELS(_swypPromptImageView);
		SRELS(_swypWifiAvailableButton);
		SRELS(_swypBluetoothAvailableButton);
	}
}
@end
