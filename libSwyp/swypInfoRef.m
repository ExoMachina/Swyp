//
//  swypInfoRef.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import "swypInfoRef.h"


@implementation swypInfoRef
@synthesize velocity,startPoint,endPoint,startDate,endDate,swypBeginningContentView,swypType;
-(void) setSwypBeginningContentView:(UIView *)swypOutView{
	SRELS(swypBeginningContentView);
	swypBeginningContentView = [swypOutView retain];
}

-(void)dealloc{
	SRELS(swypBeginningContentView);
	SRELS(startDate);
	SRELS(endDate);
	[super dealloc];
}

@end
