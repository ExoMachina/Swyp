//
//  swypCryptoManager.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//


#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import "swypCryptoSession.h"
#import "swypConnectionSession.h"

@class swypCryptoManager;
@protocol swypCryptoManagerDelegate <NSObject>
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


@interface swypCryptoManager : NSObject  {	
	SecIdentityRef					_localCryptoIdentity;
	
	id<swypCryptoManagerDelegate>	_delegate;
	
}
@property (nonatomic, assign)	id<swypCryptoManagerDelegate>	delegate;
@property (nonatomic, readonly)	NSSet*							sessionsPendingCryptoSetup;

+(swypCryptoManager*)	sharedCryptoManager;

-(SecIdentityRef)		localSecIdentity;
+(NSString*)			localpersistentPeerID;


//
//private
//secure key generation
-(SecIdentityRef)		_generateNewLocalCryptoIdentity;
-(SecIdentityRef)		_retrieveLocalCryptoIdentity;
-(void)					_deleteLocalCryptoIdentity;

@end
