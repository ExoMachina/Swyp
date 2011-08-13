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
+(NSString*)			localPersistantPeerID;

-(void) beginNegotiatingCryptoSessionWithSwypConnectionSession:	(swypConnectionSession*)session;

//
//private
-(void)	_handleNextCryptoHandshakeStageWithSession:(swypConnectionSession*)session anyReceivedData:(NSData*)relevantHandshakeData; 

-(void)	_happilyConcludeNegotiatingCryptoSessionForConnectionSession:	(swypConnectionSession*)session;
-(void)	_abortNegotiatingCryptoSessionForConnectionSession:	(swypConnectionSession*)session;
-(void)	_failWithCryptoManagerErrorCode:(swypCryptoManagerErrorCode)errorCode forConnectionSession:(swypConnectionSession*)session;
-(BOOL)	_removeConnectionSession:	(swypConnectionSession*)session;

-(void)	_beginMandatingCryptoInConnectionSession:		(swypConnectionSession*)session;
@end
