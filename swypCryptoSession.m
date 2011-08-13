//
//  swypCryptoSession.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import "swypCryptoSession.h"


@implementation swypCryptoSession
@synthesize cryptoStage = _cryptoStage, encryptedCommunicationRequired = _encryptedCommunicationRequired , candidatePublicKey = _candidatePublicKey, sharedSessionKey = _sharedSessionKey, encryptingTransform = _encryptingTransform, unencryptingTransform = _unencryptingTransform;


-(void)dealloc{
	SRELS(_candidatePublicKey);
	SRELS(_sharedSessionKey);
	SRELS(_encryptingTransform);
	SRELS(_unencryptingTransform);
	
	[super dealloc];
}

@end
