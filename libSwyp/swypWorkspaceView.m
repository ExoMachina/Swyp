//
//  swypWorkspaceView.m
//  libSwyp
//
//  Created by Alexander List on 2/4/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import "swypWorkspaceView.h"


@implementation swypWorkspaceView
@synthesize prettyOverlay = _prettyOverlay, backgroundView = _backgroundView, swypPromptImageView = _swypPromptImageView, swypNetworkInterfaceClassButton = _swypNetworkInterfaceClassButton;

-(swypWorkspaceView*)	initWithFrame:(CGRect)frame workspaceTarget:(id)workspace{
	
	if (self = [super initWithFrame:frame]){
		[self setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
		[self setClipsToBounds:TRUE];
		
		_backgroundView		= [[swypWorkspaceBackgroundView alloc] initWithFrame:self.frame];
		[self addSubview:_backgroundView];
		self.backgroundColor= [UIColor whiteColor];
		
		_prettyOverlay		=	[[UIImageView alloc] initWithFrame:self.frame];
		[_prettyOverlay setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
		[self.backgroundView addSubview:_prettyOverlay];
		[_prettyOverlay setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"swypWorkspaceBackground.png"]]];

		
		_swypPromptImageView = [[SwypPromptImageView alloc] init];
		[_swypPromptImageView setUserInteractionEnabled:FALSE];
		CGRect promptImageFrame	=	CGRectMake(self.frame.size.width/2 - (250/2), self.frame.size.height/2 - (250/2), 250, 250);
		[_swypPromptImageView setFrame:promptImageFrame];
		[self addSubview:_swypPromptImageView];

		
		swypInGestureRecognizer*	swypInRecognizer	=	[[swypInGestureRecognizer alloc] initWithTarget:self action:@selector(swypInGestureChanged:)];
		[swypInRecognizer setDelegate:workspace];
		[swypInRecognizer setDelaysTouchesBegan:FALSE];
		[swypInRecognizer setDelaysTouchesEnded:FALSE];
		[swypInRecognizer setCancelsTouchesInView:FALSE];
		[self.backgroundView addGestureRecognizer:swypInRecognizer];
		SRELS(swypInRecognizer);
		
		swypOutGestureRecognizer*	swypOutRecognizer	=	[[swypOutGestureRecognizer alloc] initWithTarget:self action:@selector(swypOutGestureChanged:)];
		[swypOutRecognizer setDelegate:workspace];
		[swypOutRecognizer setDelaysTouchesBegan:FALSE];
		[swypOutRecognizer setDelaysTouchesEnded:FALSE];
		[swypOutRecognizer setCancelsTouchesInView:FALSE];
		[self.backgroundView addGestureRecognizer:swypOutRecognizer];
		SRELS(swypOutRecognizer);

		
		_swypNetworkInterfaceClassButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 38, 27)];
		[_swypNetworkInterfaceClassButton setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin];
		[_swypNetworkInterfaceClassButton setShowsTouchWhenHighlighted:TRUE];
		[_swypNetworkInterfaceClassButton addTarget:workspace action:@selector(networkInterfaceClassButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
		[_swypNetworkInterfaceClassButton setEnabled:FALSE];
		[_swypNetworkInterfaceClassButton setOrigin:CGPointMake(9, self.frame.size.height-32)];
		[self addSubview:_swypNetworkInterfaceClassButton];
		

		_swypPromptImageView.alpha				=	0;
		_swypNetworkInterfaceClassButton.alpha	=	0;
		[UIView animateWithDuration:.75 animations:^{
			[_swypPromptImageView setAlpha:0.7];
			[_swypNetworkInterfaceClassButton setAlpha:1];
		}completion:nil];

	}	
	return self;
}

-(void) dealloc{
	SRELS(_backgroundView);
	SRELS(_prettyOverlay);
	SRELS(_swypPromptImageView);
	SRELS(_swypNetworkInterfaceClassButton);
	[super dealloc];
}

@end
