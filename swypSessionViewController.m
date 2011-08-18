//
//  swypSessionViewController.m
//  swyp
//
//  Created by Alexander List on 7/29/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import "swypSessionViewController.h"


@implementation swypSessionViewController
@synthesize connectionSession = _connectionSession;


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
	
	[self.view setBackgroundColor:[_connectionSession sessionHueColor]];
}

@end
