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

@implementation swypWorkspaceViewController
@synthesize workspaceID = _workspaceID, connectionManager = _connectionManager, contentManager = _contentManager;

#pragma mark -
#pragma mark swypConnectionManager
-(swypConnectionManager*)	connectionManager{
	if (_connectionManager == nil){
		_connectionManager = [[swypConnectionManager alloc] init];
		[_connectionManager setDelegate:self];
	}
	
	return _connectionManager;
}

-(void)	swypConnectionSessionWasCreated:(swypConnectionSession*)session		withConnectionManager:(swypConnectionManager*)manager{
	UIView *symbolView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
	[symbolView setBackgroundColor:[session sessionHueColor]];
	[symbolView setCenter:[[[session representedCandidate] matchedLocalSwypInfo]endPoint]];
	
	[self.view addSubview:symbolView];
	
	SRELS(symbolView);
}
-(void)	swypConnectionSessionWasInvalidated:(swypConnectionSession*)session	withConnectionManager:(swypConnectionManager*)manager error:(NSError*)error{
	
}

#pragma mark workspaceInteraction



#pragma mark -
#pragma mark UIGestureRecognizerDelegate
-(void)	swypInGestureChanged:(swypInGestureRecognizer*)recognizer{
	
}

-(void)	swypOutGestureChanged:(swypOutGestureRecognizer*)recognizer{
	if (recognizer.state == UIGestureRecognizerStateBegan){
		
	}
}


#pragma mark UIViewController
-(id)	initWithContentWorkspaceID:(NSString*)workspaceID{
	if (self = [super initWithNibName:nil bundle:nil]){
		[self setModalPresentationStyle:	UIModalPresentationFullScreen];
		[self setModalTransitionStyle:		UIModalTransitionStyleCrossDissolve];
		
	}
	return self;
}
-(void)	viewDidLoad{
	[super viewDidLoad];
	
	[self.view setBackgroundColor:[UIColor blackColor]];
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:NO];	
	[[self connectionManager] beginServices];
	
	swypInGestureRecognizer*	swypInRecognizer =	[[swypInGestureRecognizer alloc] initWithTarget:self action:@selector(swypInGestureChanged:)];
	[swypInRecognizer setDelegate:self];
	[self.view addGestureRecognizer:swypInRecognizer];
	SRELS(swypInRecognizer);

	swypOutGestureRecognizer*	swypOutRecognizer =	[[swypOutGestureRecognizer alloc] initWithTarget:self action:@selector(swypOutGestureChanged:)];
	[swypInRecognizer setDelegate:self];
	[self.view addGestureRecognizer:swypOutRecognizer];
	SRELS(swypOutRecognizer);	
	
}
-(void)	dealloc{
	
	[super dealloc];
}
@end
