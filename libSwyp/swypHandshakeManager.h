//
//  swypHandshakeManager.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

//	Handshake manager is passed client and server candidates and handles everything about their setup until its completion

#import <Foundation/Foundation.h>
#import "swypInfoRef.h"
#import "swypClientCandidate.h"
#import "swypServerCandidate.h"
#import "swypConnectionSession.h"


static NSString * const swypHandshakeManagerErrorDomain;
typedef enum {
	swypHandshakeManagerSocketSetupError,
	swypHandshakeManagerSocketHelloMismatchError,//not exactly an important error
	swypHandshakeManagerSocketConnectionError
}	swypHandshakeManagerErrorCode;


@class swypHandshakeManager;

@protocol swypHandshakeManagerDelegate <NSObject>
-(NSArray*)	relevantSwypsForCandidate:				(swypCandidate*)candidate		withHandshakeManager:	(swypHandshakeManager*)manager;

-(void)	connectionSessionCreationFailedForCandidate:(swypCandidate*)candidate		withHandshakeManager:	(swypHandshakeManager*)manager error:(NSError*)error;
-(void)	connectionSessionWasCreatedSuccessfully:	(swypConnectionSession*)session	withHandshakeManager:	(swypHandshakeManager*)manager;

@end


@interface swypHandshakeManager : NSObject <NSNetServiceDelegate, swypConnectionSessionInfoDelegate,swypConnectionSessionDataDelegate> {
	NSMutableDictionary *	_resolvingServerCandidates;
	NSMutableSet *			_pendingConnectionSessions;
		
	
	id<swypHandshakeManagerDelegate>	_delegate;
}
@property (nonatomic, assign)	id<swypHandshakeManagerDelegate>	delegate;
/*
	LEARN: We accept a set of Server candidates, why not a set of Client candidates?
		Server candidates are found through NSNetServices and are batched for connections when needed
		Client candidates connect to servers one by one, and need immediate servicing with 'hello' packets
		Servers don't know of the existence of clients until they connect
*/

-(void)	beginHandshakeProcessWithServerCandidates:	(NSSet*)candidates;
-(void)	beginHandshakeProcessWithClientCandidate:	(swypClientCandidate*)clientCandidate	streamIn:(NSInputStream*)inputStream	streamOut:(NSOutputStream*)outputStream;

//
//private
-(void)	_startResolvingConnectionToServerCandidate:	(swypServerCandidate*)serverCandidate;
-(void)	_startConnectionToServerCandidate:			(swypServerCandidate*)serverCandidate;

-(void)	_initializeConnectionSessionObjectForCandidate:	(swypCandidate*)candidate	streamIn:(NSInputStream*)inputStream	streamOut:(NSOutputStream*)outputStream;

-(void)	_sendServerHelloPacketToClientForSwypConnectionSession:	(swypConnectionSession*)session;
-(void)	_sendClientHelloPacketToServerForSwypConnectionSession:	(swypConnectionSession*)session;

/*
	The following method importantly shows that no clock synchronization is required between a server and client
	We use "miliseconds in the past," instead.
*/
-(void)	_handleClientHelloPacket:	(NSDictionary*)helloPacket forConnectionSession:	(swypConnectionSession*)session;
-(void)	_handleServerHelloPacket:	(NSDictionary*)helloPacket forConnectionSession:	(swypConnectionSession*)session;

-(BOOL)	_clientCandidate:	(swypClientCandidate*)clientCandidate	isMatchForSwypInfo:	(swypInfoRef*)swypInfo;
-(BOOL)	_serverCandidate:	(swypServerCandidate*)serverCandidate	isMatchForSwypInfo:	(swypInfoRef*)swypInfo;

-(void)	_postNegotiationSessionHandOff:	(swypConnectionSession*)session;

-(void) _removeAndInvalidateSession:			(swypConnectionSession*)session;

@end
