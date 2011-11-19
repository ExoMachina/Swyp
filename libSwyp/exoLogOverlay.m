//
//  exoLogOverlay.m
//  swyp
//
//  Created by Alexander List on 8/3/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import "exoLogOverlay.h"

static exoLogOverlay * sharedLogOverlay;

@implementation exoLogOverlay

-(id) init{
	if (self = [super init]){
		_logTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 320, 400)];
		[_logTextView setTextColor:[UIColor whiteColor]];
		[_logTextView setBackgroundColor:[UIColor blackColor]];
		[_logTextView setAlpha:.4];
		[_logTextView setUserInteractionEnabled:FALSE];
	
		[[[UIApplication sharedApplication] keyWindow] addSubview:_logTextView];
		
	}
	return self;
}

+(exoLogOverlay*)	sharedLogOverlay{
	if (sharedLogOverlay == nil){
		sharedLogOverlay = [[exoLogOverlay alloc] init];
	}
	
	return sharedLogOverlay;
}

-(void)	log:(NSString*)logText{
	[_logTextView setText:[logText stringByAppendingFormat:@"\n%@",[_logTextView text]]];
}

-(void)dealloc{
	SRELS(_logTextView);

	[super dealloc];
}

@end
