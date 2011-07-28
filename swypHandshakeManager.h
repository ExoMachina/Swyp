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

@class swypHandshakeManager;

@protocol swypHandshakeManagerDelegate <NSObject>
-(swypInfoRef*)	mostRelevantSwypInfoForCandidate:	(swypCandidate*)candidate		withHandshakeManager:	(swypHandshakeManager*)manager;

-(void)	connectionSessionCreationFailedForCandidate:(swypCandidate*)candidate		withHandshakeManager:	(swypHandshakeManager*)manager error:(NSError*)error;
-(void)	connectionSessionWasCreatedSuccessfully:	(swypConnectionSession*)session	withHandshakeManager:	(swypHandshakeManager*)manager;

@end


@interface swypHandshakeManager : NSObject <swypConnectionSessionDelegate,swypConnectionSessionDataDelegate, swypCryptoManagerDelegate> {
	NSMutableSet *	_resolvingServerCandidates;
	NSMutableSet *	_pendingClientConnectionSessions;
	NSMutableSet *	_pendingServerConnectionSessions;
	
	swypCryptoManager*		_cryptoManager;
}
/*
	LEARN: We accept a set of Server candidates, why not a set of Client candidates?
		Client candidates connect one by one, and need immediate servicing with 'hello' packets
		Server candidates are found through NSNetServices and are batched for connections when needed
*/

-(void)	beginHandshakeProcessWithServerCandidates:	(NSSet*)candidates;
-(void)	beginHandshakeProcessWithClientCandidate:	(swypClientCandidate*)clientCandidate	streamIn:(NSInputStream*)inputStream	streamOut:(NSOutputStream*)outputStream;

//
//privates
-(void)	_startResolvingConnectionToServerCandidate:	(swypServerCandidate*)serverCandidate;
-(void)	_startConnectionToServerCandidate:			(swypServerCandidate*)serverCandidate;

-(swypConnectionSession*)	_connectionSessionObjectForServerCandidate:	(swypServerCandidate*)serverCandidate	streamIn:(NSInputStream*)inputStream	streamOut:(NSOutputStream*)outputStream;
-(swypConnectionSession*)	_connectionSessionObjectForClientCandidate:	(swypClientCandidate*)clientCandidate	streamIn:(NSInputStream*)inputStream	streamOut:(NSOutputStream*)outputStream;

-(void)	_sendClientHelloPacketForSwypConnectionSession:	(swypConnectionSession*)session;
-(void)	_sendServerHelloPacketForSwypConnectionSession:	(swypConnectionSession*)session;

-(void)	_handleClientHelloPacket:	(NSDictionary*)helloPacket forConnectionSession:	(swypConnectionSession*)session;
-(void)	_handleServerHelloPacket:	(NSDictionary*)helloPacket forConnectionSession:	(swypConnectionSession*)session;

-(BOOL)	_clientCandidate:	(swypClientCandidate*)clientCandidate	isMatchForSwypInfo:	(swypInfoRef*)swypInfo;
-(BOOL)	_serverCandidate:	(swypServerCandidate*)serverCandidate	isMatchForSwypInfo:	(swypInfoRef*)swypInfo;

-(BOOL)	_handSessionOffForCryptoNegotiation:	(swypConnectionSession*)session;

-(BOOL)	_completeHandshakeManagementOfSession:	(swypConnectionSession*)session;
@end
