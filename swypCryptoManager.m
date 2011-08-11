//
//  swypCryptoManager.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import "swypCryptoManager.h"
#import "NSStringAdditions.h"

@implementation swypCryptoManager
@synthesize delegate = _delegate, sessionsPendingCryptoSetup = _sessionsPendingCryptoSetup;
+(NSString*)			localPersistantPeerID{
	NSString * toHash	= [[[NSString localAppName] stringByAppendingString:[[UIDevice currentDevice] name]] stringByAppendingString:[[UIDevice currentDevice] uniqueIdentifier]];
	return	[toHash SHA1AlphanumericHash];
}
@end
