//
//  swypHandshakeManager.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

//	Handshake manager is passed client and server candidates and handles everything about their setup until its completion

#import <Foundation/Foundation.h>
#import "swyp.h"
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

-(void)	connectionSessionCreationFailedForConnectionSession:(swypConnectionSession*)session	forSwypRef:(swypInfoRef*)ref	withHandshakeManager:	(swypHandshakeManager*)manager error:(NSError*)error;

-(void)	connectionSessionWasCreatedSuccessfully:	(swypConnectionSession*)session forSwypRef:(swypInfoRef*)ref	withHandshakeManager:	(swypHandshakeManager*)manager;

@end

/** Handshake manager deals with */
@interface swypHandshakeManager : NSObject <NSNetServiceDelegate, swypConnectionSessionInfoDelegate,swypConnectionSessionDataDelegate> {

	NSMutableDictionary	*	_swypRefByPendingConnectionSessions;
	NSMutableDictionary	*	_swypTimeoutsByConnectionSession;
	
	NSMutableDictionary *	_swypOutRefReferenceCountBySwypRef;
	NSMutableSet		*	_swypOutRefRetention; //because no retention happens for swypInfoRefs as a key
	
	id<swypHandshakeManagerDelegate>	_delegate;
}
@property (nonatomic, assign)	id<swypHandshakeManagerDelegate>	delegate;

/** Increment reference count for a particular swyp out. 
 
 Swyp outs that have reference count are used for matching client candidates in handshake process.
 */
-(void)	referenceSwypOutAsPending:(swypInfoRef*)ref;

/** Decrement reference count for a particular swyp out. 
 
 This probably means that an interface is no longer advertising for a swyp-out.
 Swyp outs that have reference count are used for matching client candidates in handshake process.
 */
-(void)	dereferenceSwypOutAsPending:(swypInfoRef*)ref;


/** 
 The method for attaching swypConnectionSessions which have already been paired through NSInputStreams and NSOutputStreams, and supposedly work.
 
 This depreicates beginHandshakeProcessWithServerCandidates:.
 
 @warning the connectionSession should be uninitiated. The initiate function causes the socket connections to open and forces the handshake process. 
 */
-(void) beginHandshakeProcessWithConnectionSession:(swypConnectionSession*)session;

//
//private
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

-(void)	_removeSessionFromLocalStorage: (swypConnectionSession*)session;
@end
