//
//  swypServerCandidate.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import "swypServerCandidate.h"


@implementation swypServerCandidate
@synthesize netService;
-(id)init{
	if (self= [super init]){
		[self setRole:swypCandidateRoleServer];
	}
	return self;
}
-(void)dealloc{
	SRELS(netService);
	[super dealloc];
}
@end
