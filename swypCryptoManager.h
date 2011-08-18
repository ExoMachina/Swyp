//
//  swypCryptoManager.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//


#import <Foundation/Foundation.h>
#import "swypCryptoSession.h"
#import "swypConnectionSession.h"

@class swypCryptoManager;
@protocol swypCryptoManagerDelegate <NSObject, swypConnectionSessionDataDelegate, swypConnectionSessionInfoDelegate>
-(void) didCompleteCryptoSetupInSession:	(swypConnectionSession*)session warning:	(NSString*)cryptoWarning cryptoManager:(swypCryptoManager*)cryptoManager;
-(void) didFailCryptoSetupInSession:		(swypConnectionSession*)session error:		(NSError*)cryptoError cryptoManager:(swypCryptoManager*)cryptoManager;
@end

static NSString * const swypCryptoManagerErrorDomain = @"swypCryptoManagerErrorDomain";

typedef enum{
	swypCryptoManagerErrorNone = 0,
	swypCryptoManagerErrorAborted,
	swypCryptoManagerErrorHandshakeFormat,
	swypCryptoManagerErrorConnectivity,
	swypCryptoManagerErrorKeyValidity,
	swypCryptoManagerErrorSessionCorruption
} swypCryptoManagerErrorCode;


@interface swypCryptoManager : NSObject <swypConnectionSessionDataDelegate,swypConnectionSessionInfoDelegate>  {
	NSMutableSet*					_sessionsPendingCryptoSetup;
	
	
	id<swypCryptoManagerDelegate>	_delegate;
	
}
@property (nonatomic, assign)	id<swypCryptoManagerDelegate>	delegate;
@property (nonatomic, readonly)	NSSet*							sessionsPendingCryptoSetup;

+(NSData*)				localPrivateKey;
+(NSData*)				localPublicKey;
+(NSString*)			localpersistentPeerID;

-(void) beginNegotiatingCryptoSessionWithSwypConnectionSession:	(swypConnectionSession*)session;

//
//private
-(void)	_handleNextCryptoHandshakeStageWithSession:(swypConnectionSession*)session anyReceivedData:(NSData*)relevantHandshakeData; 

-(void)	_happilyConcludeNegotiatingCryptoSessionForConnectionSession:	(swypConnectionSession*)session;
-(void)	_abortNegotiatingCryptoSessionForConnectionSession:	(swypConnectionSession*)session;
-(void)	_failWithCryptoManagerErrorCode:(swypCryptoManagerErrorCode)errorCode forConnectionSession:(swypConnectionSession*)session;
-(BOOL)	_removeConnectionSession:	(swypConnectionSession*)session;

-(void)	_beginMandatingCryptoInConnectionSession:		(swypConnectionSession*)session;

//client handlers
-(void)	_clientShareStageSharedPublicKeyWithSession:(swypConnectionSession*)session;
-(BOOL)	_clientHandleStageSharedPublicKeyWithSession:(swypConnectionSession*)session data:(NSData*)	data;
-(void)	_clientShareStageConfirmedSymetricKeyWithSession:(swypConnectionSession*)session;
-(BOOL) _clientHandleStageConfirmedSymetricKeyWithSession:(swypConnectionSession*)session data:(NSData*)	data;

//server handlers
-(BOOL)	_serverHandleStagePreKeyShareWithSession:(swypConnectionSession*)session data:(NSData*) data;
-(void)	_serverShareStageSharedSymetricKeyWithSession:(swypConnectionSession*)session;
-(BOOL)	_serverHandleStageSharedSymetricKeyWithSession:(swypConnectionSession*)session data:(NSData*) data;
-(void)	_serverShareStageReadyWithSession:(swypConnectionSession*)session;

@end
