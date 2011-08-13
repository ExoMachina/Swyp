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

#pragma mark -
#pragma mark public
+(NSString*)			localPersistantPeerID{
	NSString * toHash	= [[[NSString localAppName] stringByAppendingString:[[UIDevice currentDevice] name]] stringByAppendingString:[[UIDevice currentDevice] uniqueIdentifier]];
	return	[toHash SHA1AlphanumericHash];
}


-(void) beginNegotiatingCryptoSessionWithSwypConnectionSession:	(swypConnectionSession*)session{
	if ([session cryptoSession] != nil){
		EXOLog(@"Cryto session is not nil; NOT beginning");
		return;
	}
	
	swypCryptoSession *		cryptoSession	=	[[swypCryptoSession alloc] init];
	[session setCryptoSession:cryptoSession];
	SRELS(cryptoSession);
	
	[session addDataDelegate:self];
	[session addConnectionSessionInfoDelegate:self];
	
}

#pragma mark NSObject
-(id)	init{
	if (self = [super init]){
		_sessionsPendingCryptoSetup = [[NSMutableSet alloc] init];
	}
	
	return self;
}

-(void)dealloc{
	for (swypConnectionSession * session in _sessionsPendingCryptoSetup){
		[self _abortNegotiatingCryptoSessionForConnectionSession:session];
	}
	SRELS(_sessionsPendingCryptoSetup);
	
	[super dealloc];
}

#pragma mark -
#pragma mark private
-(void)	_handleNextCryptoHandshakeStageWithSession:(swypConnectionSession*)session anyReceivedData:(NSData*)relevantHandshakeData{
	swypCandidateRole candidateRole		= [[session representedCandidate] role];
	swypCryptoSession *	cryptoSession	= [session cryptoSession];
	swypCryptoSessionStage stage		= [cryptoSession cryptoStage];
	
	if (candidateRole == swypCandidateRoleClient){
		if (stage == swypCryptoSessionStagePreKeyShare){
			//client shares public key in clear
			[cryptoSession setCryptoStage:swypCryptoSessionStageSharedPublicKey];
		}else if (stage == swypCryptoSessionStageSharedPublicKey){
			//client recieves shared session key + device id: in payload encrypted with own public key from server- header unencrypted
			//client shares peerID, supported file types, symmetric key confirmation, nametag: in payload encrypted with public key from server- header unencrypted
			//client begins manditory complete encryption
			[cryptoSession setCryptoStage:swypCryptoSessionStageConfirmedSymetricKey];

		}else if (stage == swypCryptoSessionStageConfirmedSymetricKey){
			//we receive symmetrically encrypted filetypes, session hue, nametag
			//we send nothing because we're done crypto neg --If valid, we're ready
			[cryptoSession setCryptoStage:swypCryptoSessionStageReady];
			EXOLog(@"Crypto negotiation completed happily");
			[self _happilyConcludeNegotiatingCryptoSessionForConnectionSession:session];
		}else{
			EXOLog(@"Failed: invalid crypto stage for client:%i",stage);
			[self _failWithCryptoManagerErrorCode:swypCryptoManagerErrorHandshakeFormat forConnectionSession:session];
		}
	}else if (candidateRole == swypCandidateRoleServer){
		if (stage == swypCryptoSessionStagePreKeyShare){
			//server receives client's public key
			//server shares session key, its public key and peerID-- all in payload encrypted with client public key -header unencrypted
			[cryptoSession setCryptoStage:swypCryptoSessionStageSharedSymetricKey];
		}else if (stage == swypCryptoSessionStageSharedSymetricKey){
			//server recieves client's peerID, supported file types, symmetric key confirmation, and nametag in a payload encrypted with its own public key
			//server begins manditory complete encryption
			//server sends filetypes, session hue, nametag -- and we're ready

			[cryptoSession setCryptoStage:swypCryptoSessionStageReady];
			EXOLog(@"Crypto negotiation completed happily");
			[self _happilyConcludeNegotiatingCryptoSessionForConnectionSession:session];

		}else{
			EXOLog(@"Failed: invalid crypto stage for server:%i",stage);
			[self _failWithCryptoManagerErrorCode:swypCryptoManagerErrorHandshakeFormat forConnectionSession:session];
		}
	}else{
		EXOLog(@"Undefinined candidate role");
		if ([self _removeConnectionSession:session]){
			[self _failWithCryptoManagerErrorCode:swypCryptoManagerErrorSessionCorruption forConnectionSession:session];
		}
	}
	
}
-(void)	_happilyConcludeNegotiatingCryptoSessionForConnectionSession:	(swypConnectionSession*)session{
	[_delegate didCompleteCryptoSetupInSession:session warning:nil cryptoManager:self];
	[self _removeConnectionSession:session];
}
-(void)	_abortNegotiatingCryptoSessionForConnectionSession:	(swypConnectionSession*)session{
	if ([self _removeConnectionSession:session]){
		[self _failWithCryptoManagerErrorCode:swypCryptoManagerErrorAborted forConnectionSession:session];
	}
}

 -(void)	_failWithCryptoManagerErrorCode:(swypCryptoManagerErrorCode)errorCode forConnectionSession:(swypConnectionSession*)session{
	 [[session cryptoSession] setCryptoStage:swypCryptoSessionStageFailedNegotiation];
	 [_delegate didFailCryptoSetupInSession:session error:[NSError errorWithDomain:swypCryptoManagerErrorDomain code:errorCode userInfo:nil] cryptoManager:self];
	
}

-(BOOL)	_removeConnectionSession:	(swypConnectionSession*)session{
	
	if (session != nil && [_sessionsPendingCryptoSetup containsObject:session]){
		[session removeDataDelegate:self];
		[session removeConnectionSessionInfoDelegate:self];
		[_sessionsPendingCryptoSetup removeObject:session];
		return TRUE;
	}
	
	return FALSE;
}

-(void)	_beginMandatingCryptoInConnectionSession:		(swypConnectionSession*)session{
	//for us, this means simply activating encryption/decryption transforms
	
	swypUnencryptingTransform * unencryptionTransform	=	[[swypUnencryptingTransform alloc] initWithSessionAES128Key:[[session cryptoSession] sharedSessionKey]];
	[[session socketInputTransformStream] setTransformStreamArray:[NSArray arrayWithObject:unencryptionTransform]];
	SRELS(unencryptionTransform);
	
	swypEncryptingTransform *	encryptingTransform		=	[[swypEncryptingTransform alloc] initWithSessionAES128Key:[[session cryptoSession] sharedSessionKey]];
	[[session socketOutputTransformStream] setTransformStreamArray:[NSArray arrayWithObject:encryptingTransform]];
	SRELS(encryptingTransform);
}

#pragma mark swypConnectionSessionDataDelegate
-(BOOL) delegateWillHandleDiscernedStream:(swypDiscernedInputStream*)discernedStream wantsAsData:(BOOL *)wantsProvidedAsNSData inConnectionSession:(swypConnectionSession*)session{
	if ([[NSString swypCryptoNegotiationFileType] isFileType:[discernedStream streamType]]){
		*wantsProvidedAsNSData = TRUE;
		return TRUE;
	}
	
	return FALSE;

}
-(void)	yieldedData:(NSData*)streamData discernedStream:(swypDiscernedInputStream*)discernedStream inConnectionSession:(swypConnectionSession*)session{
	if ([streamData length] > 0){
		if ([[NSString swypCryptoNegotiationFileType] isFileType:[discernedStream streamType]]){
			[self _handleNextCryptoHandshakeStageWithSession:session anyReceivedData:streamData];
		} else {
			if ([self _removeConnectionSession:session]){
				[self _failWithCryptoManagerErrorCode:swypCryptoManagerErrorHandshakeFormat forConnectionSession:session];
			}
		}
	}
}

-(void)	failedSendingStream:(NSInputStream*)stream error:(NSError*)error connectionSession:(swypConnectionSession*)session{
	if ([self _removeConnectionSession:session]){
		[self _failWithCryptoManagerErrorCode:swypCryptoManagerErrorConnectivity forConnectionSession:session];
	}
}

#pragma mark swypConnectionSessionInfoDelegate
-(void) sessionDied:			(swypConnectionSession*)session withError:(NSError*)error{
	if ([self _removeConnectionSession:session]){
		[self _failWithCryptoManagerErrorCode:swypCryptoManagerErrorConnectivity forConnectionSession:session];
	}
}
@end
