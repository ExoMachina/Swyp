//
//  swypOutputToDataStream.m
//  swyp
//
//  Created by Alexander List on 1/15/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import "swypOutputToDataStream.h"

@implementation swypOutputToDataStream
@synthesize dataDelegate = _dataDelegate;

-(id) initWithDataDelegate:(id <swypOutputToDataStreamDataDelegate>)delegate{
	if (self =[super init]){
		_dataDelegate	=	delegate;
	}
	return self;
}

-(void)dealloc{
	
	[super dealloc];
}
@end
