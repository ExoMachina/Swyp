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
@synthesize contentLoadingThumbs = _contentLoadingThumbs;
@synthesize transferringData = _transferringData;

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
		_connectionSession		= [session retain];
		_contentLoadingThumbs	= [NSMutableSet new];
	}
	return self;
}

-(void)dealloc{
	SRELS(_connectionSession);
	SRELS(_contentLoadingThumbs);
	
	[super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return TRUE;
}
-(void) viewDidLoad{
	[super viewDidLoad];
	
	self.view.layer.cornerRadius	=	20;
	self.view.layer.borderWidth		=	2;
	self.view.layer.borderColor		=	[UIColor blackColor].CGColor;
	[self.view setBounds:CGRectMake(0, 0, 50, 150)];
	[self.view setBackgroundColor:[_connectionSession sessionHueColor]];
	
	UITapGestureRecognizer * cancelationRecognizer	=	[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognized:)];
	[cancelationRecognizer setNumberOfTapsRequired:1];
	[self.view addGestureRecognizer:cancelationRecognizer];
	SRELS(cancelationRecognizer);
}

-(void)setTransferringData:(BOOL)isTransferring {
    _transferringData = isTransferring;
    
    if (isTransferring) {
        self.view.layer.borderColor = [UIColor whiteColor].CGColor;
    } else {
        self.view.layer.borderColor	= [UIColor blackColor].CGColor;
    }
}

-(void) makeLandscape {
    self.view.size = CGSizeMake(150, 50);
}

#pragma mark gestures
-(void) tapGestureRecognized: (UITapGestureRecognizer*) tapGesture{
	if (tapGesture.state == UIGestureRecognizerStateRecognized){
		[_connectionSession invalidate];
	}
}

@end
