//
//  swypClientCandidate.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import "swypClientCandidate.h"


@implementation swypClientCandidate
-(id)init{
	if (self= [super init]){
		[self setRole:swypCandidateRoleClient];
	}
	return self;
}
@end
