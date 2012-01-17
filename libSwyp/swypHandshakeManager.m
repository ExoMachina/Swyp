//
//  swypHandshakeManager.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import "swypHandshakeManager.h"

static NSString * const swypHandshakeManagerErrorDomain = @"swypHandshakeManagerErrorDomain";

@implementation swypHandshakeManager
@synthesize delegate = _delegate;
#pragma mark -
#pragma mark public
-(void) beginHandshakeProcessWithConnectionSession:(swypConnectionSession*)session{
	
	[session addConnectionSessionInfoDelegate:self];
	[session initiate];
		
	NSTimer * timeoutTimer	=	[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(_timedOutHandshakeForConnectionSession:) userInfo:session repeats:FALSE];
	[_swypTimeoutsByConnectionSession setObject:timeoutTimer forKey:[NSValue valueWithNonretainedObject:session]];
	
	[_pendingSwypConnectionSessions addObject:session];
}

-(void)	referenceSwypOutAsPending:(swypInfoRef*)ref{
	if (ref == nil) {
		return;
	}
	NSValue *swypValue	= [NSValue valueWithNonretainedObject:ref];
	
	NSInteger referenceCount =	[[_swypOutRefReferenceCountBySwypRef objectForKey:swypValue] intValue];
	referenceCount ++;
	assert(referenceCount > 0);
	[_swypOutRefReferenceCountBySwypRef setObject:[NSNumber numberWithInt:referenceCount] forKey:swypValue];
	[_swypOutRefRetention	addObject:ref];
}

-(void)	dereferenceSwypOutAsPending:(swypInfoRef*)ref{
	if (ref == nil) {
		return;
	}

	NSValue *swypValue	= [NSValue valueWithNonretainedObject:ref];
	
	NSNumber * refForSwypOut	=	[_swypOutRefReferenceCountBySwypRef objectForKey:swypValue];
	NSInteger referenceCount	=	[refForSwypOut intValue];
	referenceCount --;
	assert(referenceCount >= 0);
	if (referenceCount == 0){
		[_swypOutRefReferenceCountBySwypRef removeObjectForKey:swypValue];
		[_swypOutRefRetention	removeObject:ref];
	}else{
		[_swypOutRefReferenceCountBySwypRef setObject:[NSNumber numberWithInt:referenceCount] forKey:swypValue];		
	}
}

#pragma mark -
#pragma mark NSObject

-(id)	init{
	if (self = [super init]){
		
		_swypTimeoutsByConnectionSession		= [NSMutableDictionary new];
		_swypOutRefReferenceCountBySwypRef		= [NSMutableDictionary new];
		_swypOutRefRetention					= [NSMutableSet new];
		_pendingSwypConnectionSessions			= [NSMutableSet new];
	}
	
	return self;
}

-(void)	dealloc{
	
	for (NSTimer * timer in [_swypTimeoutsByConnectionSession allValues]){
		[timer invalidate];
	}
	SRELS(_swypTimeoutsByConnectionSession);
	
	SRELS(_swypOutRefReferenceCountBySwypRef);
	SRELS(_swypOutRefRetention);
	
	SRELS(_pendingSwypConnectionSessions);
	
	[super dealloc];
}


#pragma mark -
#pragma mark connectionSession Delegates 
-(void) sessionStatusChanged:	(swypConnectionSessionStatus)status	inSession:(swypConnectionSession*)session{
	if (status == swypConnectionSessionStatusReady){
		swypCandidate	*	candidate	=	[session representedCandidate];
		[session addDataDelegate:self];
		EXOLog(@"Session connection dataReady for candidate");

		if ([candidate role] == swypCandidateRoleServer){
			[self _sendClientHelloPacketToServerForSwypConnectionSession:session];
		}
		//	else, you're a server, and you've set all this up right now without the prior resolving business; HOLD TIGHT

	}
}
-(void) sessionDied:	(swypConnectionSession*)session withError:(NSError*)error{
	EXOLog(@"Session connection died for candidate: %@",[error description]);

	swypInfoRef * ref	=	[[session representedCandidate] matchedLocalSwypInfo];
	[_delegate connectionSessionCreationFailedForConnectionSession:session forSwypRef:ref withHandshakeManager:self error:error];
		
	[session removeConnectionSessionInfoDelegate:self];
	
	[self _removeSessionFromLocalStorage:session];
	
}

#pragma mark connectionSession data delegates
-(BOOL) delegateWillHandleDiscernedStream:(swypDiscernedInputStream*)discernedStream wantsAsData:(BOOL *)wantsProvidedAsNSData inConnectionSession:(swypConnectionSession*)session{
	
	if ([[NSString swypControlPacketFileType] isFileType:[discernedStream streamType]]){
		*wantsProvidedAsNSData = TRUE;
		return TRUE;
	}else {
		swypCandidate	*	candidate	=	[session representedCandidate];
		EXOLog(@"Session connection returned unexpected type '%@' during HELLO sequence for candidate appearing at time:%@",[discernedStream streamType],[candidate appearanceDate]);
		[self _removeAndInvalidateSession:session];		
		return FALSE;
	}
}

-(void)	yieldedData:(NSData*)streamData discernedStream:(swypDiscernedInputStream*)discernedStream inConnectionSession:(swypConnectionSession*)session{
	if ([streamData length] > 0){
		if ([[NSString swypControlPacketFileType] isFileType:[discernedStream streamType]]){
						
			NSDictionary *	receivedDictionary = nil;
			if ([streamData length] >0){
				NSString *	readStreamString	=	[[[NSString alloc]  initWithBytes:[streamData bytes] length:[streamData length] encoding: NSUTF8StringEncoding] autorelease];
				if (StringHasText(readStreamString)){
					receivedDictionary				=	[NSDictionary dictionaryWithJSONString:readStreamString];
				}else{
					EXOLog(@"No valid text for dict string %@",readStreamString);
				}
			}
			
			if (receivedDictionary != nil){
//				EXOLog(@"Received %@ dictionary of contents:%@",[discernedStream streamType],[receivedDictionary description]);
				if ([[session representedCandidate] role] == swypCandidateRoleClient && [[discernedStream streamTag] isEqualToString:@"clientHello"]){
					[self _handleClientHelloPacket:receivedDictionary forConnectionSession:session];
				}else if ([[session representedCandidate] role] == swypCandidateRoleServer && [[discernedStream streamTag] isEqualToString:@"serverHello"]){
					[self _handleServerHelloPacket:receivedDictionary forConnectionSession:session];
				}else {
					EXOLog(@"Invalid tag during handshake %@", [discernedStream streamTag]);
					[self _removeAndInvalidateSession:session];
				}
			}else{
				EXOLog(@"Bad receive dict for handshake");
				[self _removeAndInvalidateSession:session];
			}
		}

	}else{
		swypCandidate	*	candidate	=	[session representedCandidate];
		EXOLog(@"Session connection failed without HELLO packet data for candidate appearing at time:%@",[candidate appearanceDate]);
		[self _removeAndInvalidateSession:session];
	}
	
}

#pragma mark - private
-(void)_timedOutHandshakeForConnectionSession:(NSTimer*)sender{
	swypConnectionSession * timedOutSession	=	[sender userInfo];
	EXOLog(@"Timed out handshake for connection session w/ tagname: %@",[[timedOutSession representedCandidate] nametag]);

	[self _removeAndInvalidateSession:timedOutSession];
}

#pragma mark helloPacket
-(void)	_sendServerHelloPacketToClientForSwypConnectionSession:	(swypConnectionSession*)session{
	NSMutableDictionary *	helloDictionary	=	[NSMutableDictionary dictionary];
	swypInfoRef *			matchedSwyp		=	[[session representedCandidate] matchedLocalSwypInfo];
	
	if (matchedSwyp != nil){
		[helloDictionary setValue:@"accepted" forKey:@"status"];
		[helloDictionary setValue:[swypContentInteractionManager supportedFileTypes] forKey:@"supportedFileTypes"];
		[helloDictionary setValue:[NSNumber numberWithDouble:[matchedSwyp velocity]] forKey:@"swypOutVelocity"];
	}else {
		[helloDictionary setValue:@"rejected" forKey:@"status"];
	}
	
	NSString *jsonString	=	[helloDictionary jsonStringValue];
	NSData	 *jsonData		= 	[jsonString		dataUsingEncoding:NSUTF8StringEncoding];

	EXOLog(@"Sending server hello packet");
	[session beginSendingDataWithTag:@"serverHello" type:[NSString swypControlPacketFileType] dataForSend:jsonData];
	
}
-(void)	_sendClientHelloPacketToServerForSwypConnectionSession:	(swypConnectionSession*)session{
	NSMutableDictionary *	helloDictionary	=	[NSMutableDictionary dictionary];
	
	swypInfoRef *			querySwyp		=	[[session representedCandidate] matchedLocalSwypInfo];	
	assert(querySwyp != nil);
	
	if (querySwyp != nil){
		[session setSessionHueColor:[UIColor randomSwypHueColor]];
		
		[helloDictionary setValue:[swypContentInteractionManager supportedFileTypes] forKey:@"supportedFileTypes"];
		double intervalSinceSwyp	=	[[querySwyp startDate] timeIntervalSinceNow] * -1;
		[helloDictionary setValue:[NSNumber numberWithDouble:intervalSinceSwyp] forKey:@"intervalSinceSwypIn"];
		[helloDictionary setValue:[[session sessionHueColor] swypEncodedColorStringValue] forKey:@"sessionHue"];
	}else {
		EXOLog(@"No swypIn set for matchedLocalSwypInfo... this is odd!");
		return;
	}
	
	
	NSString *jsonString	=	[helloDictionary jsonStringValue];
	NSData	 *jsonData		= 	[jsonString		dataUsingEncoding:NSUTF8StringEncoding];
	
	EXOLog(@"Sending client hello");
	[session beginSendingDataWithTag:@"clientHello" type:[NSString swypControlPacketFileType] dataForSend:jsonData];	
}

-(void)	_handleClientHelloPacket:	(NSDictionary*)helloPacket forConnectionSession:	(swypConnectionSession*)session{
	swypClientCandidate	*	candidate		=	(swypClientCandidate*)[session representedCandidate];
	swypInfoRef *	swypRefFromClientInfo	=	[[[swypInfoRef alloc] init] autorelease];

	
	NSArray	*	supportedFileTypes			= [helloPacket valueForKey:@"supportedFileTypes"];
	NSString *	sessionHue					= [helloPacket valueForKey:@"sessionHue"];
	NSNumber*	intervalSinceSwypNumber		= [helloPacket valueForKey:@"intervalSinceSwypIn"];
	
	
	if (ArrayHasItems(supportedFileTypes)){
		NSMutableArray *cleanedTypesArray	=	[NSMutableArray array];
		for (NSString * fileType in supportedFileTypes){
			if (StringHasText(fileType) && [fileType isKindOfClass:[NSString class]]){
				[cleanedTypesArray addObject:fileType];
			}
		}
		[candidate setSupportedFiletypes:cleanedTypesArray];
	}else {
		[self _removeAndInvalidateSession:session]; //invalid packet, so don't bother returning anything
		return;
	}
	
	if ([intervalSinceSwypNumber isKindOfClass:[NSNumber class]]){
		double doubleIntervalSinceSwyp	=	[intervalSinceSwypNumber doubleValue];
		if (doubleIntervalSinceSwyp > 0){
			double secondsInPast		= doubleIntervalSinceSwyp * -1;
			[swypRefFromClientInfo	setStartDate:[NSDate dateWithTimeIntervalSinceNow:secondsInPast]];
		}
	}else {
		[self _removeAndInvalidateSession:session]; //invalid packet, so don't bother returning anything
		return;
	}
	
	if ([sessionHue isKindOfClass:[NSString class]] && StringHasText(sessionHue)){
		[session setSessionHueColor:[UIColor colorWithSwypEncodedColorString:sessionHue]];
	}else {
		[self _removeAndInvalidateSession:session]; //invalid packet, so don't bother returning anything
		return;
	}

	
	[candidate setSwypInfo:swypRefFromClientInfo];
	
	
	swypInfoRef * firstMatchingSwyp	=	nil;
	for (swypInfoRef * localSwyp in _swypOutRefRetention){
		if([self _clientCandidate:candidate isMatchForSwypInfo:localSwyp]){
			firstMatchingSwyp	=	localSwyp;
			break;
		}
	}
	
	if (firstMatchingSwyp != nil){
		[candidate setMatchedLocalSwypInfo:firstMatchingSwyp];
		[self _sendServerHelloPacketToClientForSwypConnectionSession:session]; 
		/*
			connection established as far as we know!
			Handing off to the crypto manager!
		*/
		[self		_postNegotiationSessionHandOff:session];
		
	}else {
		EXOLog(@"NO matching swyp for client candidate");
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
	swypInfoRef *	swypRefFromServerInfo	=	[[[swypInfoRef alloc] init] autorelease];
	NSString *		statusString			=	[helloPacket valueForKey:@"status"];
	NSArray	*		supportedFileTypes		=	[helloPacket valueForKey:@"supportedFileTypes"];
	NSNumber *		swypOutVelocityNumber	=	[helloPacket valueForKey:@"swypOutVelocity"];
	
	
	if ([statusString isKindOfClass:[NSString class]] && StringHasText(statusString)){
		if ([statusString isEqualToString:@"accepted"]){
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
	
	
	if (ArrayHasItems(supportedFileTypes)){
		NSMutableArray *cleanedTypesArray	=	[NSMutableArray array];
		for (NSString * fileType in supportedFileTypes){
			if (StringHasText(fileType) && [fileType isKindOfClass:[NSString class]]){
				[cleanedTypesArray addObject:fileType];
			}
		}
		[candidate setSupportedFiletypes:cleanedTypesArray];
	}else {
		[self _removeAndInvalidateSession:session]; //invalid packet, so don't bother returning anything
		return;
	}

	
	if ([swypOutVelocityNumber isKindOfClass:[NSNumber class]]){
		double swypOutVelocityDouble	= [swypOutVelocityNumber doubleValue];
		if (swypOutVelocityDouble > 0){
			[swypRefFromServerInfo	setVelocity:swypOutVelocityDouble];
		}
	}else {
		[self _removeAndInvalidateSession:session];
		return;
	}
	[candidate setSwypInfo:swypRefFromServerInfo];


	swypInfoRef * localMatchSwyp	=	[[session representedCandidate] matchedLocalSwypInfo];
	
	if([self _serverCandidate:candidate isMatchForSwypInfo:localMatchSwyp] ==  NO){
		localMatchSwyp = nil;
	}
	
	if (localMatchSwyp != nil){
		EXOLog(@"Server accepted hello:, Matching swyp-in found");
		[candidate setMatchedLocalSwypInfo:localMatchSwyp];
		/*
			The server has returned a matching swyp so we're happy to begin crypto!
		*/
		[self		_postNegotiationSessionHandOff:session];
		
	}else {
		EXOLog(@"Server accepted Hello: No matching swyp-in found");
		/*
			No match from any of our swypInfoRefs; 
		 */

		[self _removeAndInvalidateSession:session];
	}
}


#pragma mark swyp matching
-(BOOL)	_clientCandidate:	(swypClientCandidate*)clientCandidate	isMatchForSwypInfo:	(swypInfoRef*)swypInfo{
	
	NSInteger milisecondDifference =	 abs([[[clientCandidate swypInfo] startDate] timeIntervalSinceDate:[swypInfo endDate]] * 1000);
	
	//mostly under 700ms when not debugging
	//when debugging, make sure no breakpoints delay absorbtion of remote intervalInPast into NSDate
	if (milisecondDifference < 1500){
		EXOLog(@"Swyp match: client start %f our end %f, ms diff= %i",[[[clientCandidate swypInfo] startDate] timeIntervalSinceNow],[[swypInfo endDate] timeIntervalSinceNow],milisecondDifference);
		return TRUE;		
	}else {
		EXOLog(@"Swyp mismatch: client start %f our end %f, ms diff= %i",[[[clientCandidate swypInfo] startDate] timeIntervalSinceNow],[[swypInfo endDate] timeIntervalSinceNow],milisecondDifference);
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
	
	EXOLog(@"NEEDIMPR: Local velocity: %f, remote velocity: %f diff:%f",localVelocity,remoteVelocity, velocityDifference);
	
	if (velocityDifference >= 0){ //fix algorithm for determining velocity
		return TRUE;
	}
	
	return FALSE;	
}

#pragma mark -
#pragma mark finalization
-(void)	_postNegotiationSessionHandOff:	(swypConnectionSession*)session{
	//SUCCESS!
	
	EXOLog(@"Successful connection with session w/ swyp from time %@",[[[[session representedCandidate] matchedLocalSwypInfo] startDate] description]);
	NSTimer * timeoutTimer	=	[_swypTimeoutsByConnectionSession objectForKey:[NSValue valueWithNonretainedObject:session]];
	[timeoutTimer invalidate];
	[_swypTimeoutsByConnectionSession removeObjectForKey:[NSValue valueWithNonretainedObject:session]];
	
	
	[session removeConnectionSessionInfoDelegate:self];
	[session removeDataDelegate:self];

	[_delegate connectionSessionWasCreatedSuccessfully:session forSwypRef:[[session representedCandidate] matchedLocalSwypInfo] withHandshakeManager:self];
	
	[self _removeSessionFromLocalStorage:session];
}

-(void) _removeAndInvalidateSession:			(swypConnectionSession*)session{

	[_delegate connectionSessionCreationFailedForConnectionSession:session forSwypRef:[[session representedCandidate] matchedLocalSwypInfo] withHandshakeManager:self error:nil];

	[session	removeConnectionSessionInfoDelegate:self];
	[session	removeDataDelegate:self];
	[session	invalidate];

	[self _removeSessionFromLocalStorage:session];
}

-(void)	_removeSessionFromLocalStorage: (swypConnectionSession*)session{
	[[_swypTimeoutsByConnectionSession objectForKey:[NSValue valueWithNonretainedObject:session]] invalidate];
	[_swypTimeoutsByConnectionSession removeObjectForKey:[NSValue valueWithNonretainedObject:session]];
	
	[_pendingSwypConnectionSessions removeObject:session];
}
@end
