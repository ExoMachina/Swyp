//
//  swypCandidate.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- check online.
//

#import <Foundation/Foundation.h>
#import "swypInfoRef.h"

typedef enum {
	swypCandidateRoleUndefined = 0, 
	swypCandidateRoleClient,
	swypCandidateRoleServer
}swypCandidateRole;


@interface swypCandidate : NSObject {
	NSNetService*		serverNetService;
	swypInfoRef*		swypInfo;
	NSString*			deviceID;
	NSString*			nametag;
	NSArray*			supportedFiletypes;
	swypCandidateRole	role;
	swypInfoRef*		matchedLocalSwypInfo;
}
//this one is valid only for server candidates
@property (nonatomic, retain) NSNetService*		serverNetService;

@property (nonatomic, retain) swypInfoRef*		swypInfo;
@property (nonatomic, retain) NSString*			deviceID;
@property (nonatomic, retain) NSString*			nametag;
@property (nonatomic, retain) NSArray*			supportedFiletypes;
@property (nonatomic, assign) swypCandidateRole	role;
@property (nonatomic, retain) swypInfoRef*		matchedLocalSwypInfo;

@end
