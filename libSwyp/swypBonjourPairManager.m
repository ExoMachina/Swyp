//
//  swypBonjourPairManager.m
//  swyp
//
//  Created by Alexander List on 1/14/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import "swypBonjourPairManager.h"

@implementation swypBonjourPairManager

-(void) dealloc{
//for (swypServerCandidate * candidate in _resolvingServerCandidates){
//	NSNetService * resolvingService	=	[candidate netService];
//	[resolvingService setDelegate:nil];
//	[resolvingService stop];
//}
	[super dealloc];
}

//#pragma mark resolution and connection
//-(void)	_startResolvingConnectionToServerCandidate:	(swypServerCandidate*)serverCandidate{
//	NSNetService * resolveService	=	[serverCandidate netService]; 
//	
//	if ([_resolvingServerCandidates objectForKey:[NSValue valueWithNonretainedObject:resolveService]] != nil){
//		return;
//	}
//	
//	EXOLog(@"Began resolving server candidate: %@", [[serverCandidate netService] name]);
//	[resolveService				setDelegate:self];
//	[resolveService				resolveWithTimeout:3];
//	[_resolvingServerCandidates setObject:serverCandidate forKey:[NSValue valueWithNonretainedObject:resolveService]];
//}
//
//-(void)	_startConnectionToServerCandidate:			(swypServerCandidate*)serverCandidate{
//	NSNetService *		connectService	=	[serverCandidate netService];
//	
//	NSInputStream *		inputStream		=	nil;
//	NSOutputStream *	outputSteam		=	nil;
//	
//	//neither are open
//	BOOL success	=	[connectService getInputStream:&inputStream outputStream:&outputSteam];
//	if (success && inputStream != nil && outputSteam != nil){
//		[self _initializeConnectionSessionObjectForCandidate:serverCandidate streamIn:inputStream streamOut:outputSteam];
//	}else {
//		[_delegate	connectionSessionCreationFailedForCandidate:serverCandidate withHandshakeManager:self error:[NSError errorWithDomain:swypHandshakeManagerErrorDomain code:swypHandshakeManagerSocketSetupError userInfo:nil]];
//	}
//	
//}
//#pragma mark NSNetServiceDelegate
//- (void)netServiceDidResolveAddress:(NSNetService *)sender{
//	swypServerCandidate	*	candidate	=	[_resolvingServerCandidates objectForKey:[NSValue valueWithNonretainedObject:sender]];
//	
//	
//	EXOLog(@"Resolved candidate: %@", [sender name]);
//	
//	if (candidate != nil){
//		[self _startConnectionToServerCandidate:candidate];
//		[sender setDelegate:nil];
//		[_resolvingServerCandidates removeObjectForKey:[NSValue valueWithNonretainedObject:sender]];
//	}
//}
//- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict{
//	swypServerCandidate	*	candidate	=	[_resolvingServerCandidates objectForKey:[NSValue valueWithNonretainedObject:sender]];
//	
//	EXOLog(@"Did not resolve candidate: %@", [sender name]);
//	if (candidate != nil){
//		[_delegate	connectionSessionCreationFailedForCandidate:candidate withHandshakeManager:self error:[NSError errorWithDomain:[errorDict valueForKey:NSNetServicesErrorDomain] code:[[errorDict valueForKey:NSNetServicesErrorCode] intValue] userInfo:nil]];
//		[sender setDelegate:nil];
//		[sender stop];
//		[_resolvingServerCandidates removeObjectForKey:[NSValue valueWithNonretainedObject:sender]];
//	}
//}


@end
