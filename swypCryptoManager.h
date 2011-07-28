//
//  swypCryptoManager.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- check online.
//

#import <Foundation/Foundation.h>
#import "swypCryptoSession.h"
#import "swypConnectionSession.h"

@class swypCryptoManager;

@protocol swypCryptoManagerDelegate <NSObject>
-(void) didCompleteCryptoSetupInSession:	(swypConnectionSession*)session warning:	(NSString*)cryptoWarning;
-(void) didFailCryptoSetupInSession:		(swypConnectionSession*)session error:		(NSError*)cryptoError;
@end


@interface swypCryptoManager : NSObject <swypConnectionSessionDataDelegate>  {
	NSMutableSet*			_sessionsPendingCryptoSetup;
	
}
+(swypCryptoManager*)	sharedCryptoManager;
+(NSData*)				localPrivateKey;
+(NSData*)				localPublicKey;

-(void) beginNegotiatingCryptoSessionWithSwypConnectionSession:	(swypConnectionSession*)session;

//
//private
-(void)	_initializeCryptoSessionForConnectionSession:	(swypConnectionSession*)session;
-(void)	_beginMandatingCryptoInConnectionSession:		(swypConnectionSession*)session;

-(void)	_handleCryptoHandshakeStage:(swypCryptoSessionStage)stage withReceivedData:(NSData*)handshakeData; 

@end
