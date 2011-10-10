//
//  swypSessionViewController.m
//  swyp
//
//  Created by Alexander List on 7/29/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import "swypSessionViewController.h"
#import <QuartzCore/QuartzCore.h>


@implementation swypSessionViewController
@synthesize connectionSession = _connectionSession;
@synthesize showActiveTransferIndicator = _showActiveTransferIndicator;

#pragma mark public 
-(BOOL)	overlapsRect:(CGRect)testRect inView:(UIView*)	testView{
	
	if ([self.view isDescendantOfView:testView]){
		if (CGRectIntersectsRect(testRect, self.view.frame))
			return TRUE;
	}
	
	return FALSE;
}


#pragma mark -
#pragma mark private
-(id)	initWithConnectionSession:	(swypConnectionSession*)session{
	if (self = [super initWithNibName:nil bundle:nil]){
		_connectionSession = [session retain];
	}
	return self;
}

-(void)dealloc{
	SRELS(_connectionSession);
	
	[super dealloc];
}

-(void) viewDidLoad{
	[super viewDidLoad];
	
	self.view.layer.cornerRadius	=	75;
	self.view.layer.borderWidth		=	5;
	self.view.layer.borderColor		=	[[UIColor blackColor] CGColor];
	[self.view setBounds:CGRectMake(0, 0, 150, 150)];
	[self.view setBackgroundColor:[_connectionSession sessionHueColor]];
	
	UITapGestureRecognizer * cancelationRecognizer	=	[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognized:)];
	[cancelationRecognizer setNumberOfTapsRequired:2];
	[self.view addGestureRecognizer:cancelationRecognizer];
	SRELS(cancelationRecognizer);
}

-(void) setShowActiveTransferIndicator:(BOOL)showActiveTransferIndicator{
	_showActiveTransferIndicator	= showActiveTransferIndicator;
	if (_activityIndicator == nil) {
		_activityIndicator			= [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		[_activityIndicator setFrame:CGRectMake(0, 0, 50, 50)];
	}
	
	if (showActiveTransferIndicator){
		[self.view addSubview:_activityIndicator];
		[_activityIndicator setOrigin:CGPointMake(50, 50)];
		[_activityIndicator startAnimating];
	}else{
		[_activityIndicator stopAnimating];
		[_activityIndicator removeFromSuperview];
	}
	
}

#pragma mark gestures
-(void) tapGestureRecognized: (UITapGestureRecognizer*) tapGesture{
	if (tapGesture.state == UIGestureRecognizerStateRecognized){
		[_connectionSession invalidate];
	}
}

@end
