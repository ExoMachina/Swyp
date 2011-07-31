//
//  swypHandshakeManager.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import "swypHandshakeManager.h"
#import "exoBlockOperationAlertView.h"

@implementation swypHandshakeManager
@synthesize delegate = _delegate;
#pragma mark -
#pragma mark public
-(void)	beginHandshakeProcessWithServerCandidates:	(NSSet*)candidates{
	for (swypServerCandidate * serverCandidate in candidates){
		[self _startResolvingConnectionToServerCandidate:serverCandidate];
	}
}
-(void)	beginHandshakeProcessWithClientCandidate:	(swypClientCandidate*)clientCandidate	streamIn:(NSInputStream*)inputStream	streamOut:(NSOutputStream*)outputStream{
	[self _initializeConnectionSessionObjectForCandidate:clientCandidate streamIn:inputStream streamOut:outputStream];
}

#pragma mark -
#pragma mark NSObject

-(id)	init{
	if (self = [super init]){
		_resolvingServerCandidates			=	[[NSMutableDictionary alloc] init];
		_pendingConnectionSessions			=	[[NSMutableSet alloc] init];
	}
	
	return self;
}

-(void)	dealloc{
	for (swypServerCandidate * candidate in _resolvingServerCandidates){
		NSNetService * resolvingService	=	[candidate netService];
		[resolvingService setDelegate:nil];
		[resolvingService stop];
	}
	
	SRELS(_pendingConnectionSessions);
	SRELS(_resolvingServerCandidates);
	
	
	SRELS(_cryptoManager);
	
	[super dealloc];
}


#pragma mark -
#pragma mark resolution and connection
-(void)	_startResolvingConnectionToServerCandidate:	(swypServerCandidate*)serverCandidate{
	NSNetService * resolveService	=	[serverCandidate netService];
	[resolveService				setDelegate:self];
	[resolveService				resolveWithTimeout:1];
	[_resolvingServerCandidates setObject:serverCandidate forKey:[NSValue valueWithNonretainedObject:resolveService]];
}

-(void)	_startConnectionToServerCandidate:			(swypServerCandidate*)serverCandidate{
	NSNetService *		connectService	=	[serverCandidate netService];
	
	NSInputStream *		inputStream		=	nil;
	NSOutputStream *	outputSteam		=	nil;
	
	//neither are open
	BOOL success	=	[connectService getInputStream:&inputStream outputStream:&outputSteam];
	if (success && inputStream != nil && outputSteam != nil){
		[self _initializeConnectionSessionObjectForCandidate:serverCandidate streamIn:inputStream streamOut:outputSteam];
	}else {
		[_delegate	connectionSessionCreationFailedForCandidate:serverCandidate withHandshakeManager:self error:[NSError errorWithDomain:swypHandshakeManagerErrorDomain code:swypHandshakeManagerSocketSetupError userInfo:nil]];
	}

}
#pragma mark NSNetServiceDelegate
- (void)netServiceDidResolveAddress:(NSNetService *)sender{
	swypServerCandidate	*	candidate	=	[_resolvingServerCandidates objectForKey:[NSValue valueWithNonretainedObject:sender]];
	
	EXOLog(@"Resolved service to address!:%@",[sender description]);
	
	if (candidate != nil){
		[self _startConnectionToServerCandidate:candidate];
		[sender setDelegate:nil];
		[_resolvingServerCandidates removeObjectForKey:[NSValue valueWithNonretainedObject:sender]];
	}
}
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict{
	swypServerCandidate	*	candidate	=	[_resolvingServerCandidates objectForKey:[NSValue valueWithNonretainedObject:sender]];
	
	if (candidate != nil){
		[_delegate	connectionSessionCreationFailedForCandidate:candidate withHandshakeManager:self error:[NSError errorWithDomain:[errorDict valueForKey:NSNetServicesErrorDomain] code:[[errorDict valueForKey:NSNetServicesErrorCode] intValue] userInfo:nil]];
		[sender setDelegate:nil];
		[_resolvingServerCandidates removeObjectForKey:[NSValue valueWithNonretainedObject:sender]];
	}
}

#pragma mark socket connection
-(void)	_initializeConnectionSessionObjectForCandidate:	(swypCandidate*)candidate	streamIn:(NSInputStream*)inputStream	streamOut:(NSOutputStream*)outputStream{
	swypConnectionSession * newSession	=	[[swypConnectionSession alloc] initWithSwypCandidate:candidate inputStream:inputStream outputStream:outputStream];
	[newSession addConnectionSessionInfoDelegate:self];
	[_pendingConnectionSessions addObject:newSession];
}

#pragma mark -
#pragma mark connectionSession Delegates 
-(void) sessionStatusChanged:	(swypConnectionSessionStatus)status	inSession:(swypConnectionSession*)session{
	if (status == swypConnectionSessionStatusReady){
		swypCandidate	*	candidate	=	[session representedCandidate];
		[session addDataDelegate:self];
		EXOLog(@"Session connection dataReady for candidate appearing at time:%@",[candidate appearanceDate]);

		if ([candidate role] == swypCandidateRoleServer){
			[self _sendClientHelloPacketToServerForSwypConnectionSession:session];
		}
		//	else, you're a server, and you've set all this up right now without the prior resolving business; HOLD TIGHT

	}
}
-(void) sessionDied:	(swypConnectionSession*)session withError:(NSError*)error{
	swypCandidate	*	candidate	=	[session representedCandidate];
	EXOLog(@"Session connection died for candidate appearing at time:%@",[candidate appearanceDate]);
	[_delegate	connectionSessionCreationFailedForCandidate:candidate withHandshakeManager:self error:error];
	[session removeConnectionSessionInfoDelegate:self];
	[_pendingConnectionSessions	removeObject:session];
}

#pragma mark connectionSession data delegates
-(NSOutputStream*) streamToWriteReceivedDataWithTag:(NSString*)tag type:(swypFileTypeString*)type length:(NSUInteger)streamLength connectionSession:(swypConnectionSession*)session{

	if ([type isFileType:[swypFileTypeString swypControlPacketFileType]]){
		return [NSOutputStream outputStreamToMemory];
	}else {
		swypCandidate	*	candidate	=	[session representedCandidate];
		EXOLog(@"Session connection returned unexpected  'type' during HELLO sequence for candidate appearing at time:%@",[candidate appearanceDate]);
		[_delegate	connectionSessionCreationFailedForCandidate:candidate withHandshakeManager:self error:[NSError errorWithDomain:swypHandshakeManagerErrorDomain code:swypHandshakeManagerSocketHelloMismatchError userInfo:nil]];
		[session removeConnectionSessionInfoDelegate:self];
		[session removeDataDelegate:self];
		[session invalidate];
		[_pendingConnectionSessions	removeObject:session];		
	}
	
	return nil;	
}
-(void) finishedReceivingDataWithOutputStream:(NSOutputStream*)stream error:(NSError*)error tag:(NSString*)tag type:(swypFileTypeString*)type connectionSession:(swypConnectionSession*)session{
	if ([type isFileType:[swypFileTypeString swypControlPacketFileType]]){
		
		NSData	*	readStreamData	=	[stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
		
		NSDictionary *	receivedDictionary = nil;
		if ([readStreamData length] >0){
			NSString *	readStreamString	=	[NSString stringWithUTF8String:[readStreamData bytes]];
			if (StringHasText(readStreamString))
				receivedDictionary				=	[NSDictionary dictionaryWithJSONString:readStreamString];
		}
		
		if (receivedDictionary != nil){
			EXOLog(@"Received %@ dictionary of contents:%@",type,[receivedDictionary description]);
			if ([[session representedCandidate] role] == swypCandidateRoleClient && [tag isEqualToString:@"clientHello"]){
				[self _handleClientHelloPacket:receivedDictionary forConnectionSession:session];
			}else if ([[session representedCandidate] role] == swypCandidateRoleServer && [tag isEqualToString:@"serverHello"]){
				[self _handleServerHelloPacket:receivedDictionary forConnectionSession:session];
			}else {
				EXOLog(@"Invalid tag during handshake %@", tag);
				swypCandidate	*	candidate	=	[session representedCandidate];
				[_delegate	connectionSessionCreationFailedForCandidate:candidate withHandshakeManager:self error:error];
				[session removeConnectionSessionInfoDelegate:self];
				[session removeDataDelegate:self];
				[session invalidate];
				[_pendingConnectionSessions	removeObject:session];					
			}

		}
	}
}
#pragma mark -
#pragma mark helloPacket
-(void)	_sendServerHelloPacketToClientForSwypConnectionSession:	(swypConnectionSession*)session{
	NSMutableDictionary *	helloDictionary	=	[NSMutableDictionary dictionary];
	swypInfoRef *			matchedSwyp		=	[[session representedCandidate] matchedLocalSwypInfo];
	
	if (matchedSwyp != nil){
		[helloDictionary setValue:@"accepted" forKey:@"status"];
		[helloDictionary setValue:[swypCryptoManager localPersistantPeerID] forKey:@"persistentPeerID"];
		[helloDictionary setValue:[NSNumber numberWithDouble:[matchedSwyp velocity]] forKey:@"swypOutVelocity"];
	}else {
		[helloDictionary setValue:@"rejected" forKey:@"status"];
	}
	
	NSString *jsonString	=	[helloDictionary jsonStringValue];
	NSData	 *jsonData		= 	[jsonString		dataUsingEncoding:NSUTF8StringEncoding];

	EXOLog(@"Sending server hello packet: %@", jsonString);
	[session beginSendingDataWithTag:@"serverHello" type:[swypFileTypeString swypControlPacketFileType] dataForSend:jsonData];
	
}
-(void)	_sendClientHelloPacketToServerForSwypConnectionSession:	(swypConnectionSession*)session{
	NSMutableDictionary *	helloDictionary	=	[NSMutableDictionary dictionary];
	NSArray *				relevantSwyps	=	[_delegate relevantSwypsForCandidate:[session representedCandidate] withHandshakeManager:self];
	swypInfoRef *			querySwyp		=	(ArrayHasItems(relevantSwyps))?[relevantSwyps objectAtIndex:0]: nil;
	
	
	if (querySwyp != nil){
		[helloDictionary setValue:[swypCryptoManager localPersistantPeerID] forKey:@"persistentPeerID"];
		double intervalSinceSwyp	=	[[querySwyp startDate] timeIntervalSinceNow] * -1;
		[helloDictionary setValue:[NSNumber numberWithDouble:intervalSinceSwyp] forKey:@"intervalSinceSwypIn"];
	}else {
		EXOLog(@"No swypIns found... this is odd!, check expiration times for swypIns");
		return;
	}
	
	
	NSString *jsonString	=	[helloDictionary jsonStringValue];
	NSData	 *jsonData		= 	[jsonString		dataUsingEncoding:NSUTF8StringEncoding];
	
	EXOLog(@"Sending client hello packet: %@", jsonString);
	[session beginSendingDataWithTag:@"clientHello" type:[swypFileTypeString swypControlPacketFileType] dataForSend:jsonData];	
}

-(void)	_handleClientHelloPacket:	(NSDictionary*)helloPacket forConnectionSession:	(swypConnectionSession*)session{
	swypClientCandidate	*	candidate		=	(swypClientCandidate*)[session representedCandidate];
	swypInfoRef *	swypRefFromClientInfo	=	[[swypInfoRef alloc] init];	
	NSString * persistentPeerID				= [helloPacket valueForKey:@"persistentPeerID"];
	id intervalSinceSwyp					= [helloPacket valueForKey:@"intervalSinceSwypIn"];
	
	if ([intervalSinceSwyp isKindOfClass:[NSNumber class]]){
		NSInteger intervalSinceSwyp	= [(NSNumber*) intervalSinceSwyp intValue];
		if (intervalSinceSwyp > 0){
			double intervalInPast	= (double)intervalSinceSwyp/1000 * -1;
			[swypRefFromClientInfo	setStartDate:[NSDate dateWithTimeIntervalSinceNow:intervalInPast]];
		}
	}
	
	if ([persistentPeerID isKindOfClass:[NSString class]] && StringHasText(persistentPeerID)){
		EXOLog(@"Persistent peer ID of candidate is: %@", persistentPeerID);
		[candidate setPersistentPeerID:persistentPeerID];
	}else {
		[self _removeAndInvalidateSession:session]; //invalid packet, so don't bother returning anything
		return;
	}

	
	[candidate setSwypInfo:swypRefFromClientInfo];
	
	
	swypInfoRef * firstMatchingSwyp	=	nil;
	for (swypInfoRef * localSwyp in [_delegate relevantSwypsForCandidate:candidate withHandshakeManager:self]){
		if([self _clientCandidate:candidate isMatchForSwypInfo:localSwyp]){
			firstMatchingSwyp	=	localSwyp;
			return;
		}
	}
	
	if (firstMatchingSwyp != nil){
		[candidate setMatchedLocalSwypInfo:firstMatchingSwyp];
		[self _sendServerHelloPacketToClientForSwypConnectionSession:session]; 
		/*
			connection established as far as we know!
			Handing off to the crypto manager!
		*/
		[self		_handSessionOffForCryptoNegotiation:session];
		
	}else {
		EXOLog(@"No matching swyp found for peerID:%@",persistentPeerID);
		/*
			No match from any of our swypInfoRefs
			The server should return an invalid packet, so I'm being careful to ensure "invalidate" doesn't kill a halfway-done transmission
				Perhaps connection sessions should self-retain when transmitting
		 */
		[self		_sendServerHelloPacketToClientForSwypConnectionSession:session];
		[self		_removeAndInvalidateSession:session];		
		return;
	}

	
}
-(void)	_handleServerHelloPacket:	(NSDictionary*)helloPacket forConnectionSession:	(swypConnectionSession*)session{
	swypServerCandidate	*	candidate		=	(swypServerCandidate*)[session representedCandidate];
	swypInfoRef *	swypRefFromServerInfo	=	[[swypInfoRef alloc] init];	
	NSString *		statusString			=	[helloPacket valueForKey:@"status"];
	NSString *		persistentPeerID		=	[helloPacket valueForKey:@"persistentPeerID"];
	id				swypOutVelocity			=	[helloPacket valueForKey:@"swypOutVelocity"];
	
	
	if ([statusString isKindOfClass:[NSString class]] && StringHasText(statusString)){
		if ([statusString isEqualToString:@"accepted"]){
			EXOLog(@"Swyp accepted by server");
			//you're cool, so don't do anything
		}else{
			EXOLog(@"Swyp rejected by server with status: %@",statusString);
			[self _removeAndInvalidateSession:session];
			return;
		}
	}else {
		[self _removeAndInvalidateSession:session];
		return;
	}

	
	if ([swypOutVelocity isKindOfClass:[NSNumber class]]){
		NSInteger swypOutVelocity	= [(NSNumber*) swypOutVelocity intValue];
		if (swypOutVelocity > 0){
			[swypRefFromServerInfo	setVelocity:swypOutVelocity];
		}
	}
	
	if ([persistentPeerID isKindOfClass:[NSString class]] && StringHasText(persistentPeerID)){
		EXOLog(@"Persistent peer ID of server candidate is: %@", persistentPeerID);
		[candidate setPersistentPeerID:persistentPeerID];
	}else {
		[self _removeAndInvalidateSession:session];
		return;
	}

	
	[candidate setSwypInfo:swypRefFromServerInfo];
	
	
	swypInfoRef * firstMatchingSwyp	=	nil;
	for (swypInfoRef * localSwyp in [_delegate relevantSwypsForCandidate:candidate withHandshakeManager:self]){
		if([self _serverCandidate:candidate isMatchForSwypInfo:localSwyp]){
			firstMatchingSwyp	=	localSwyp;
			break;
		}
	}
	
	if (firstMatchingSwyp != nil){
		EXOLog(@"Server was happy, and a matching swyp-in found for peerID:%@",persistentPeerID);
		[candidate setMatchedLocalSwypInfo:firstMatchingSwyp];
		/*
			The server has returned a matching swyp so we're happy to begin crypto!
		*/
		[self		_handSessionOffForCryptoNegotiation:session];
		
	}else {
		EXOLog(@"Though the server was happy, no matching swyp-in found for peerID:%@",persistentPeerID);
		/*
			No match from any of our swypInfoRefs -- which is sorta odd if we got this far, 
				so set a breakpoint here if things are off..
		*/

		[self _removeAndInvalidateSession:session];
	}
}


#pragma mark swyp matching
-(BOOL)	_clientCandidate:	(swypClientCandidate*)clientCandidate	isMatchForSwypInfo:	(swypInfoRef*)swypInfo{
	
	NSInteger milisecondDifference =	 abs([[[clientCandidate swypInfo] startDate] timeIntervalSinceDate:[swypInfo endDate]] * 1000);

	EXOLog(@"Milisecond difference with client of ID %@ is %i",[clientCandidate persistentPeerID],milisecondDifference);
	
	if (milisecondDifference < 1000){
		return TRUE;		
	}else {
		return FALSE;
	}

}
-(BOOL)	_serverCandidate:	(swypServerCandidate*)serverCandidate	isMatchForSwypInfo:	(swypInfoRef*)swypInfo{
	//test velocity, namely is it WAYY off
	//should do some research and print out loads of swyp timing data at some temporally close instant

	//should correlate to mm/second because of pixel density differences accross devices..
	
	double localVelocity		=	[[serverCandidate swypInfo] velocity];
	double remoteVelocity		=	[swypInfo velocity];
	
	double velocityDifference	=	 abs(localVelocity - remoteVelocity);
	
	EXOLog(@"Local velocity: %f, remote velocity: %f diff:%f",localVelocity,remoteVelocity, velocityDifference);
	
	if (velocityDifference < 20){
		return TRUE;
	}
	
	return FALSE;	
}

#pragma mark -
#pragma mark finalization
-(void)	_handSessionOffForCryptoNegotiation:	(swypConnectionSession*)session{
	
	if (_cryptoManager == nil){
		_cryptoManager =	[[swypCryptoManager alloc] init];
		[_cryptoManager		setDelegate:self];
	}
	[session removeConnectionSessionInfoDelegate:self];
	[session removeDataDelegate:self];

	[_cryptoManager		beginNegotiatingCryptoSessionWithSwypConnectionSession:session];	
}

-(void) _removeAndInvalidateSession:			(swypConnectionSession*)session{
	[_delegate	connectionSessionCreationFailedForCandidate:[session representedCandidate] withHandshakeManager:self error:nil];
	[session	removeConnectionSessionInfoDelegate:self];
	[session	removeDataDelegate:self];
	[session	invalidate];
	[_pendingConnectionSessions	removeObject:session];			
}


#pragma mark swypCryptoManagerDelegate
-(void) didCompleteCryptoSetupInSession:	(swypConnectionSession*)session warning:	(NSString*)cryptoWarning{

	/*
		crypto warnings are important, they represent that something is wrong  --give the user a chance to invalidate the connection
		could be as simple as new certifcate for an old persistantID, could be as malicious as a man-in-the-middle attack
	*/
	if (StringHasText(cryptoWarning)){
		exoBlockOperationAlertView * warningView	=	[[exoBlockOperationAlertView alloc] initWithoutDelegateWithTitle:[[NSBundle mainBundle]localizedStringForKey:@"ConnectionUserWarning" value:@"Connection Warning!" table:nil] message:[[NSBundle mainBundle]localizedStringForKey:cryptoWarning value:cryptoWarning table:nil]  cancelButtonTitle:[[NSBundle mainBundle]localizedStringForKey:@"proceedResponseButtonTitle" value:@"Proceed" table:nil] otherButtonTitles:[NSArray arrayWithObject:[[NSBundle mainBundle]localizedStringForKey:@"closeResponseButtonTitle" value:@"Close" table:nil]] blockOperations:nil];
		
		[warningView	setBlockOperation:[NSBlockOperation blockOperationWithBlock:^{
			[session invalidate];
		}] forButtonIndex:1];
		
		[warningView show];
		
		SRELS(warningView)
	}
	
	[_delegate connectionSessionWasCreatedSuccessfully:session withHandshakeManager:self];
}
-(void) didFailCryptoSetupInSession:		(swypConnectionSession*)session error:		(NSError*)cryptoError{
	EXOLog(@"Failed crypto for session with persistentPeerID %@ for reason %@", [[session representedCandidate] persistentPeerID], [cryptoError description]);
	[_delegate connectionSessionCreationFailedForCandidate:[session representedCandidate] withHandshakeManager:self error:cryptoError];
}



@end
