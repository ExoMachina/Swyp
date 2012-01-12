//
//  swypCandidate.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import "swypCandidate.h"


@implementation swypCandidate
@synthesize swypInfo,nametag,supportedFiletypes,role,matchedLocalSwypInfo,appearanceDate;
-(id)init{
	if (self = [super init]){
		appearanceDate	= [NSDate date];
	}
	return self;
}
-(void)dealloc{
	SRELS(swypInfo);
	SRELS(nametag);
	SRELS(supportedFiletypes);
	SRELS(matchedLocalSwypInfo);
	SRELS(appearanceDate);
	[super dealloc];
}
@end

