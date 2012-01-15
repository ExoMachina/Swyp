//
//  swypCandidate.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import <Foundation/Foundation.h>
#import "swypInfoRef.h"

///We're either unknown, a client, or a server
typedef enum {
	swypCandidateRoleUndefined = 0, 
	swypCandidateRoleClient,
	swypCandidateRoleServer
}swypCandidateRole;

/** candidates encapsulate the potential for a connection.. 
 Though we've transitioned to using swypConnectionSession(s) more, candidates still play the role of encapsulating a bunch of metadata.
 */ 
@interface swypCandidate : NSObject {	
	NSDate *			appearanceDate;
	swypInfoRef*		swypInfo;
	NSString*			nametag;
	NSArray*			supportedFiletypes;
	swypCandidateRole	role;
	swypInfoRef*		matchedLocalSwypInfo;
}
///This property represents THEIR swypInfo
@property (nonatomic, retain) swypInfoRef*		swypInfo;
///When did the candidate firt appear; default is at the object's init date
@property (nonatomic, retain) NSDate *			appearanceDate;
///the following property is used when peers are strictly nameable, as they are with bonjour and bluetooth
@property (nonatomic, retain) NSString*			nametag;
///An NSArray of swypFileTypeString
@property (nonatomic, retain) NSArray*			supportedFiletypes;
///Defines what role a candidate is playing, whether server or client
@property (nonatomic, assign) swypCandidateRole	role;

/** This property represents OUR swyp info.
 
 Clients need to decide this before connectiing to server, servers need to decide this after receiving connection from client. 
 */
@property (nonatomic, retain) swypInfoRef*		matchedLocalSwypInfo;

@end
