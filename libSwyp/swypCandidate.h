//
//  swypCandidate.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import <Foundation/Foundation.h>
#import "swypInfoRef.h"

typedef enum {
	swypCandidateRoleUndefined = 0, 
	swypCandidateRoleClient,
	swypCandidateRoleServer
}swypCandidateRole;


@interface swypCandidate : NSObject {	
	NSDate *			appearanceDate;
	swypInfoRef*		swypInfo;
	NSString*			nametag;
	NSArray*			supportedFiletypes;
	swypCandidateRole	role;
	swypInfoRef*		matchedLocalSwypInfo;
}
@property (nonatomic, retain) swypInfoRef*		swypInfo;
@property (nonatomic, retain) NSDate *			appearanceDate;
@property (nonatomic, retain) NSString*			nametag;
@property (nonatomic, retain) NSArray*			supportedFiletypes;
@property (nonatomic, assign) swypCandidateRole	role;
@property (nonatomic, retain) swypInfoRef*		matchedLocalSwypInfo;

@end
