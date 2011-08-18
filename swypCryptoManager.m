//
//  swypCryptoManager.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import "swypCryptoManager.h"
#import "NSStringAdditions.h"
#import "NSData+Base64.h"

@implementation swypCryptoManager
@synthesize delegate = _delegate, sessionsPendingCryptoSetup = _sessionsPendingCryptoSetup;

#pragma mark -
#pragma mark public
+(NSString*)			localpersistentPeerID{
	NSString * toHash	= [[[NSString localAppName] stringByAppendingString:[[UIDevice currentDevice] name]] stringByAppendingString:[[UIDevice currentDevice] uniqueIdentifier]];
	return	[toHash SHA1AlphanumericHash];
}

+(NSData*)				localPrivateKey{
	return [@"localPrivateKeyPlaceholder" dataUsingEncoding:NSUTF8StringEncoding];
}
+(NSData*)				localPublicKey{
	return [@"localPublicKeyPlaceholder" dataUsingEncoding:NSUTF8StringEncoding];

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
	
	if ([[session representedCandidate] role] == swypCandidateRoleServer){ //thus, you're the client
		[self _handleNextCryptoHandshakeStageWithSession:session anyReceivedData:nil];
	}
	
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
	swypCandidateRole ourRole			= ([[session representedCandidate] role] == swypCandidateRoleServer)?swypCandidateRoleClient : swypCandidateRoleServer;
	swypCryptoSession *	cryptoSession	= [session cryptoSession];
	swypCryptoSessionStage stage		= [cryptoSession cryptoStage];
	
	if (ourRole == swypCandidateRoleClient){
		if (stage == swypCryptoSessionStagePreKeyShare){
			//client shares public key in clear
			
			[self _clientShareStageSharedPublicKeyWithSession:session];
			
			[cryptoSession setCryptoStage:swypCryptoSessionStageSharedPublicKey];
		}else if (stage == swypCryptoSessionStageSharedPublicKey){
			//client recieves shared session key + device id: in payload encrypted with own public key from server- header unencrypted
			//client shares peerID, supported file types, symmetric key confirmation, nametag: in payload encrypted with public key from server- header unencrypted
			//client begins manditory complete encryption

			if ([self _clientHandleStageSharedPublicKeyWithSession:session data:relevantHandshakeData] == NO){
				[cryptoSession setCryptoStage:swypCryptoSessionStageFailedNegotiation];
				[self _failWithCryptoManagerErrorCode:swypCryptoManagerErrorHandshakeFormat forConnectionSession:session];
				return;
			}

			[self _clientShareStageConfirmedSymetricKeyWithSession:session];
			
			[cryptoSession setCryptoStage:swypCryptoSessionStageConfirmedSymetricKey];

		}else if (stage == swypCryptoSessionStageConfirmedSymetricKey){
			//we receive symmetrically encrypted filetypes, session hue, nametag
			//we send nothing because we're done crypto neg --If valid, we're ready
			
			if ([self _clientHandleStageConfirmedSymetricKeyWithSession:session data:relevantHandshakeData] == NO){
				[cryptoSession setCryptoStage:swypCryptoSessionStageFailedNegotiation];
				[self _failWithCryptoManagerErrorCode:swypCryptoManagerErrorHandshakeFormat forConnectionSession:session];
				return;
			}
			
			[cryptoSession setCryptoStage:swypCryptoSessionStageReady];
			EXOLog(@"Crypto negotiation completed happily");
			[self _happilyConcludeNegotiatingCryptoSessionForConnectionSession:session];
		}else{
			EXOLog(@"Failed: invalid crypto stage for client:%i",stage);
			[self _failWithCryptoManagerErrorCode:swypCryptoManagerErrorHandshakeFormat forConnectionSession:session];
		}
	}else if (ourRole == swypCandidateRoleServer){
		if (stage == swypCryptoSessionStagePreKeyShare){
			//server receives client's public key
			//server shares session key, its public key-- all in payload encrypted with client public key -header unencrypted
			
			if ([self _serverHandleStagePreKeyShareWithSession:session data:relevantHandshakeData] == NO){
				[cryptoSession setCryptoStage:swypCryptoSessionStageFailedNegotiation];
				[self _failWithCryptoManagerErrorCode:swypCryptoManagerErrorHandshakeFormat forConnectionSession:session];
				return;
			}
			
			[self _serverShareStageSharedSymetricKeyWithSession:session];
			
			[cryptoSession setCryptoStage:swypCryptoSessionStageSharedSymetricKey];
		}else if (stage == swypCryptoSessionStageSharedSymetricKey){
			//server recieves client's peerID, supported file types, symmetric key confirmation, and nametag in a payload encrypted with its own public key
			//server begins manditory complete encryption
			//server sends filetypes, session hue, nametag -- and we're ready

			if ([self _serverHandleStageSharedSymetricKeyWithSession:session data:relevantHandshakeData] == NO){
				[cryptoSession setCryptoStage:swypCryptoSessionStageFailedNegotiation];
				[self _failWithCryptoManagerErrorCode:swypCryptoManagerErrorHandshakeFormat forConnectionSession:session];
				return;
			}
			
			[self _serverShareStageReadyWithSession:session];			
			
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


#pragma mark -
#pragma mark private cryptoHandshakePacketHandlers
#pragma mark client
-(void)	_clientShareStageSharedPublicKeyWithSession:(swypConnectionSession*)session{
	
	NSMutableDictionary *	sendDictionary	=	[NSMutableDictionary dictionary];
	[sendDictionary setValue:@"publicKeyValue" forKey:@"publicKey"];
	
	NSString *jsonString	=	[sendDictionary jsonStringValue];
	NSData	 *jsonData		= 	[jsonString		dataUsingEncoding:NSUTF8StringEncoding];

	[session beginSendingDataWithTag:@"clientShareStageSharedPublicKey" type:[NSString swypCryptoNegotiationFileType] dataForSend:jsonData];
	EXOLog(@"queued clientShareStageSharedPublicKey");

}

-(BOOL)	_clientHandleStageSharedPublicKeyWithSession:(swypConnectionSession*)session data:(NSData*)	data{
	NSString * dataString  = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSDictionary * receivedDictionary	=	[NSDictionary dictionaryWithJSONString:dataString];
	SRELS(dataString);
	
	
	NSString * publicKeyString	=	[receivedDictionary valueForKey:@"publicKey"];
	if (StringHasText(publicKeyString)){
		[[session cryptoSession] setCandidatePublicKey:[NSData dataWithBase64String:publicKeyString]];
	}else{
		return FALSE;
	}
	
	NSString * persistentPeerID			=	[receivedDictionary valueForKey:@"persistentPeerID"];
	if (!StringHasText(persistentPeerID))
		return FALSE;
	[[session representedCandidate] setPersistentPeerID:persistentPeerID];

	NSString * sessionKeyString			=	[receivedDictionary valueForKey:@"sessionKey"];
	if (StringHasText(sessionKeyString) == NO)
		return FALSE;	
	NSData * sessionKeyData				=	[NSData dataWithBase64String:sessionKeyString];
	if ([sessionKeyData length] > 0)
		[[session cryptoSession] setSharedSessionKey:sessionKeyData];
	
	EXOLog(@"HandlePublicKey: %@",receivedDictionary);
	SRELS(dataString);
	return TRUE;
}

-(void)	_clientShareStageConfirmedSymetricKeyWithSession:(swypConnectionSession*)session{
	
	NSMutableDictionary *	sendDictionary	=	[NSMutableDictionary dictionary];
	[sendDictionary setValue:[swypCryptoManager localpersistentPeerID] forKey:@"persistentPeerID"];
	[sendDictionary setValue:def_bonjourHostName forKey:@"nametag"];
	[sendDictionary setValue:[NSArray arrayWithObject:[NSString imagePNGFileType]] forKey:@"supportedFileTypes"];
	[sendDictionary setValue:[[[session cryptoSession] sharedSessionKey] base64EncodedString] forKey:@"sessionKeyConfirmation"];
	
	NSString *jsonString	=	[sendDictionary jsonStringValue];
	NSData	 *jsonData		= 	[jsonString		dataUsingEncoding:NSUTF8StringEncoding];
	
	[session beginSendingDataWithTag:@"clientShareStageConfirmedSymetricKey" type:[NSString swypCryptoNegotiationFileType] dataForSend:jsonData];
	EXOLog(@"queued clientShareStageConfirmedSymetricKey");
}

-(BOOL) _clientHandleStageConfirmedSymetricKeyWithSession:(swypConnectionSession*)session data:(NSData*)	data{
	
	NSString * dataString  = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSDictionary * receivedDictionary	=	[NSDictionary dictionaryWithJSONString:dataString];
	SRELS(dataString);
	
	if (receivedDictionary == nil){
		return FALSE;
	}
	
	NSArray * supportedfileTypes	=	[receivedDictionary valueForKey:@"supportedFileTypes"];
	if (ArrayHasItems(supportedfileTypes) == NO)
		return FALSE;
	
	[[session representedCandidate] setSupportedFiletypes:supportedfileTypes];
	
	NSString * sessionHue			=	[receivedDictionary valueForKey:@"sessionHue"];
	if (!StringHasText(sessionHue))
		return FALSE;
	UIColor * sessionHueColor		=	[UIColor colorWithSwypEncodedColorString:sessionHue];
	if (sessionHueColor == nil)
		return FALSE;
	
	[session setSessionHueColor:sessionHueColor];
	
	return TRUE;
}

#pragma mark server
-(BOOL)	_serverHandleStagePreKeyShareWithSession:(swypConnectionSession*)session data:(NSData*) data{
	NSString * dataString  = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSDictionary * receivedDictionary	=	[NSDictionary dictionaryWithJSONString:dataString];
	SRELS(dataString);
	
	if (receivedDictionary == nil){
		return FALSE;
	}
	
	EXOLog(@"serverHandleStagePreKeyShare: %@",receivedDictionary);
	
	NSString * publicKeyString	=	[receivedDictionary valueForKey:@"publicKey"];
	if (StringHasText(publicKeyString)){
		[[session cryptoSession] setCandidatePublicKey:[NSData dataWithBase64String:publicKeyString]];
	}else{
		return FALSE;
	}
	
	return TRUE;
}
-(void)	_serverShareStageSharedSymetricKeyWithSession:(swypConnectionSession*)session{
	NSMutableDictionary *	sendDictionary	=	[NSMutableDictionary dictionary];
	NSData * sessionKeyData					=	[@"sessionKeyValue" dataUsingEncoding:NSUTF8StringEncoding];
	[[session cryptoSession] setSharedSessionKey:sessionKeyData];
	
	[sendDictionary setValue:[sessionKeyData base64EncodedString] forKey:@"sessionKey"];
	[sendDictionary setValue:[[swypCryptoManager localPublicKey] base64EncodedString]forKey:@"publicKey"];
	[sendDictionary setValue:[swypCryptoManager localpersistentPeerID] forKey:@"persistentPeerID"];
	
	NSString *jsonString	=	[sendDictionary jsonStringValue];
	NSData	 *jsonData		= 	[jsonString		dataUsingEncoding:NSUTF8StringEncoding];
	
	[session beginSendingDataWithTag:@"serverShareStageSharedSymetricKey" type:[NSString swypCryptoNegotiationFileType] dataForSend:jsonData];
	EXOLog(@"queued serverShareStageSharedSymetricKey");

}
-(BOOL)	_serverHandleStageSharedSymetricKeyWithSession:(swypConnectionSession*)session data:(NSData*) data{
	
	NSString * dataString  = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSDictionary * receivedDictionary	=	[NSDictionary dictionaryWithJSONString:dataString];
	SRELS(dataString);
	
	if (receivedDictionary == nil){
		return FALSE;
	}
	
	NSArray * supportedfileTypes	=	[receivedDictionary valueForKey:@"supportedFileTypes"];
	if (ArrayHasItems(supportedfileTypes) == NO)
		return FALSE;
	
	[[session representedCandidate] setSupportedFiletypes:supportedfileTypes];
	
	NSString * persistentPeerID			=	[receivedDictionary valueForKey:@"persistentPeerID"];
	if (!StringHasText(persistentPeerID))
		return FALSE;
	[[session representedCandidate] setPersistentPeerID:persistentPeerID];

	NSString * sessionKeyString			=	[receivedDictionary valueForKey:@"sessionKeyConfirmation"];
	if (StringHasText(sessionKeyString) == NO)
		return FALSE;	
	NSData * sessionKeyData				=	[NSData dataWithBase64String:sessionKeyString];
	if ([sessionKeyData isEqualToData:[[session cryptoSession] sharedSessionKey]] == NO)
		return FALSE;

	return TRUE;
}
-(void)	_serverShareStageReadyWithSession:(swypConnectionSession*)session{
	NSMutableDictionary *	sendDictionary	=	[NSMutableDictionary dictionary];
	[sendDictionary setValue:[swypCryptoManager localpersistentPeerID] forKey:@"persistentPeerID"];
	[sendDictionary setValue:def_bonjourHostName forKey:@"nametag"];
	[sendDictionary setValue:[NSArray arrayWithObject:[NSString imagePNGFileType]] forKey:@"supportedFileTypes"];
	
	[session setSessionHueColor:[UIColor randomSwypHueColor]];
	[sendDictionary setValue:[[session sessionHueColor] swypEncodedColorStringValue] forKey:@"sessionHue"];
	
	NSString *jsonString	=	[sendDictionary jsonStringValue];
	NSData	 *jsonData		= 	[jsonString		dataUsingEncoding:NSUTF8StringEncoding];
	
	[session beginSendingDataWithTag:@"serverShareStageReady" type:[NSString swypCryptoNegotiationFileType] dataForSend:jsonData];
	EXOLog(@"queued serverShareStageReady");
}


#pragma mark -
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
