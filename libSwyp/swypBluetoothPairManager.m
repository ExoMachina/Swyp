//
//  swypBluetoothPairManager.m
//  swyp
//
//  Created by Alexander List on 1/14/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import "swypBluetoothPairManager.h"

#define kGKSessionErrorDomain @"com.apple.gamekit.GKSessionErrorDomain"

@implementation swypBluetoothPairManager

#pragma mark swypInterfaceManager
-(void)	suspendNetworkActivity{
	//stopping everything current
	for (swypInfoRef * ref in [_validSwypOutsForConnectionReceipt copy]){
		[self stopAdvertisingSwypOut:ref];
	}
	for (swypInfoRef * ref in [_validSwypInForConnectionCreation copy]){
		[self stopFindingSwypInServerCandidatesForRef:ref];
	}
	
	for (NSString * peer in _pendingGKPeerServerConnections){
		[_gameKitPeerSession cancelConnectToPeer:peer];
	}
	
	for (swypGKPeerAbstractedStreamSet * streamSet in [_activeAbstractedStreamSetsByPeerName allValues]){
		[streamSet invalidateStreamSet];
	}
	
	[self _updateInterfaceActivity];
	SRELS(_gameKitPeerSession);
}

-(void)	resumeNetworkActivity{
	if (_gameKitPeerSession == nil){
		_gameKitPeerSession	=	[[GKSession alloc] initWithSessionID:@"swyp" displayName:nil sessionMode:GKSessionModePeer];
		[_gameKitPeerSession setDelegate:self];
		[_gameKitPeerSession setDataReceiveHandler:self withContext:nil];
	}
	
	[self _updateInterfaceActivity];
}

-(void) advertiseSwypOutAsPending:(swypInfoRef*)ref{
	NSTimer * advertiseTimer	=	[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(_advertiseAsPendingTimedOutWithTimer:) userInfo:ref repeats:NO];
	[_swypOutTimeoutTimerBySwypInfoRef setObject:advertiseTimer forKey:[NSValue valueWithNonretainedObject:ref]];	
	
	[self _updateInterfaceActivity];
}

-(void) advertiseSwypOutAsCompleted:(swypInfoRef*)ref{
	NSTimer * pendingTimer	=	[_swypOutTimeoutTimerBySwypInfoRef objectForKey:[NSValue valueWithNonretainedObject:ref]];
	if (pendingTimer == nil){
		return;	
	}else{
		EXOLog(@"advertiseSwypOutAsCompleted in swypBluetoothPairManager from ref@time:%@",[[ref startDate]description]);
		[pendingTimer invalidate];
		
		NSTimer * advertiseTimer	=	[NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(_advertiseTimedOutWithTimer:) userInfo:ref repeats:NO];
		[_swypOutTimeoutTimerBySwypInfoRef setObject:advertiseTimer forKey:[NSValue valueWithNonretainedObject:ref]];	
		[_validSwypOutsForConnectionReceipt addObject:ref];
	}
	
	[self _updateInterfaceActivity];
}

-(void) stopAdvertisingSwypOut:(swypInfoRef*)ref{
	EXOLog(@"No longer advertising outRef in swypBluetoothPairManager from time: %@",[[ref startDate] description]);
	
	if ([_validSwypOutsForConnectionReceipt containsObject:ref] == NO){
		return;
	}
	
	NSTimer * advertiseTimer	=	[_swypOutTimeoutTimerBySwypInfoRef objectForKey:[NSValue valueWithNonretainedObject:ref]];
	
	[advertiseTimer invalidate];

	[_swypOutTimeoutTimerBySwypInfoRef removeObjectForKey:[NSValue valueWithNonretainedObject:ref]];	
	[_validSwypOutsForConnectionReceipt removeObject:ref];
	
	[_delegate interfaceManager:self isDoneAdvertisingSwypOutAsPending:ref forConnectionMethod:swypConnectionMethodBluetooth];

	[self _updateInterfaceActivity];
}

-(BOOL) isAdvertisingSwypOut:(swypInfoRef*)ref{
	return ([_swypOutTimeoutTimerBySwypInfoRef objectForKey:[NSValue valueWithNonretainedObject:ref]] != nil);
}

-(void)	startFindingSwypInServerCandidatesForRef:(swypInfoRef*)ref{
	NSTimer * searchTimer	=	[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(_findServersTimedOutWithTimer:) userInfo:ref repeats:NO];
	[_swypInTimeoutTimerBySwypInfoRef setObject:searchTimer forKey:[NSValue valueWithNonretainedObject:ref]];	
	[_validSwypInForConnectionCreation addObject:ref];
	
	[self _updateInterfaceActivity];
}

-(void) stopFindingSwypInServerCandidatesForRef:(swypInfoRef*)ref{
	if ([_validSwypInForConnectionCreation containsObject:ref] == NO)
		return;
	
	[_swypInTimeoutTimerBySwypInfoRef removeObjectForKey:[NSValue valueWithNonretainedObject:ref]];
	[_validSwypInForConnectionCreation removeObject:ref];

	[_delegate interfaceManager:self isDoneSearchForSwypInServerCandidatesForRef:ref forConnectionMethod:swypConnectionMethodBluetooth];
	
	[self _updateInterfaceActivity];
}

#pragma mark timeouts
-(void)_findServersTimedOutWithTimer:(NSTimer*)sender{
	[self stopFindingSwypInServerCandidatesForRef:sender.userInfo];
}
-(void)_advertiseAsPendingTimedOutWithTimer:(NSTimer*)sender{
	[self stopAdvertisingSwypOut:sender.userInfo];
}
-(void)_advertiseTimedOutWithTimer:(NSTimer*)sender{
	[self stopAdvertisingSwypOut:sender.userInfo];
}

#pragma mark NSObject
-(id) initWithInterfaceManagerDelegate:(id<swypInterfaceManagerDelegate>)delegate{
	if (self = [super init]){
		_delegate = delegate;
		_swypOutTimeoutTimerBySwypInfoRef	=	[NSMutableDictionary new];
		_validSwypOutsForConnectionReceipt	=	[NSMutableSet new];
		
		_swypInTimeoutTimerBySwypInfoRef	=	[NSMutableDictionary new];
		_validSwypInForConnectionCreation	=	[NSMutableSet new];
		
		_pendingGKPeerServerConnections		=	[NSMutableSet new];
		_pendingGKPeerClientConnections		=	[NSMutableSet new];
		
		_activeAbstractedStreamSetsByPeerName =	[NSMutableDictionary new];

	}
	return self;
}

-(void)dealloc{
	[self suspendNetworkActivity];
	
	SRELS(_swypOutTimeoutTimerBySwypInfoRef);
	SRELS(_validSwypOutsForConnectionReceipt);
	SRELS(_swypInTimeoutTimerBySwypInfoRef);
	SRELS(_validSwypInForConnectionCreation);
	
	SRELS(_pendingGKPeerServerConnections);
	SRELS(_pendingGKPeerClientConnections);
	
	SRELS(_activeAbstractedStreamSetsByPeerName);
	[super dealloc];
}


#pragma mark gamekit
#pragma mark GKSessionDelegate
- (void)session:(GKSession *)session didFailWithError:(NSError *)error{
	if ([[error domain] isEqual:kGKSessionErrorDomain] && ([error code] == GKSessionCannotEnableError)){
		EXOLog(@"%@",@"Bluetooth Disabled: launching peer picker");
		//let's prompt to turn on:
		GKPeerPickerController * picker =  [[[GKPeerPickerController alloc] init] autorelease];
		[picker setConnectionTypesMask:GKPeerPickerConnectionTypeNearby];
		[picker show];
		
	}else{
		EXOLog(@"GKSession error: %@", [error description]);
	}
}
- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error{
	[_pendingGKPeerClientConnections removeObject:peerID];
	[_pendingGKPeerServerConnections removeObject:peerID];
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID{
	if ([_validSwypOutsForConnectionReceipt count] > 0){
		EXOLog(@"Connecting via bluetooth for swypOut to peer: %@",peerID);
		[_gameKitPeerSession connectToPeer:peerID withTimeout:3];
		[_pendingGKPeerClientConnections addObject:peerID];
	}
}
- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state{
	if (state == GKPeerStateAvailable){
		EXOLog(@"Found bluetooth peer: %@",peerID);
		if ([_validSwypInForConnectionCreation count] > 0){
			EXOLog(@"Connecting via bluetooth for swypIn to peer: %@",peerID);
			[_gameKitPeerSession connectToPeer:peerID withTimeout:3];
			[_pendingGKPeerServerConnections addObject:peerID];
		}
	}else if (state == GKPeerStateConnected){
		EXOLog(@"Connected via bluetooth to peer: %@",peerID);
		
		swypGKPeerAbstractedStreamSet * newPeerStreamSet	=	[[swypGKPeerAbstractedStreamSet alloc] initWithPeerName:peerID streamSetDelegate:self];
		[_activeAbstractedStreamSetsByPeerName setObject:newPeerStreamSet forKey:peerID];

		//this sucks, but I'll try to explain:
		
		//see if it's a pending connection from a client
		if ([_pendingGKPeerClientConnections containsObject:peerID]){
			//remove it from pending
			[_pendingGKPeerClientConnections removeObject:peerID];	
			
			//create a client candidate
			swypClientCandidate * clientCandidate	= [[swypClientCandidate alloc] init];
			
			//wrap it in a new connection session; setting the input and output stream to your new swypGKPeerAbstractedStreamSet
			swypConnectionSession * newSession		= [[swypConnectionSession alloc] initWithSwypCandidate:clientCandidate inputStream:[newPeerStreamSet peerReadStream]  outputStream:[newPeerStreamSet peerWriteStream]];
			
			//tell the delegate that a client is waiting to chat
			[_delegate interfaceManager:self receivedUninitializedSwypClientCandidateConnectionSession:newSession withConnectionMethod:swypConnectionMethodBluetooth];
			SRELS(newSession);
			SRELS(clientCandidate);
			
			//otherwise it's probably a pending connection to a server
		}else if ([_pendingGKPeerServerConnections containsObject:peerID]){
			[_pendingGKPeerServerConnections removeObject:peerID];	
			
			//check to see whether we can match a local swyp in
			if ([_validSwypInForConnectionCreation  count] == 0){
				//we're wasting our time if we continue
				EXOLog(@"NO valid swypIn, invalidating connection for peer:%@", peerID);
				[newPeerStreamSet invalidateStreamSet];
				SRELS(newPeerStreamSet);
				return;
			}
						
			swypClientCandidate * serverCandidate	= [[swypClientCandidate alloc] init];
			
			//as a client, we must set matchedLocalSwypInfo
			[serverCandidate setMatchedLocalSwypInfo:[_validSwypInForConnectionCreation anyObject]];
			
			swypConnectionSession * newSession		= [[swypConnectionSession alloc] initWithSwypCandidate:serverCandidate inputStream:[newPeerStreamSet peerReadStream]  outputStream:[newPeerStreamSet peerWriteStream]];

			//tell manager that a server connection can be tapped if interested
			[_delegate interfaceManager:self madeUninitializedSwypServerCandidateConnectionSession:newSession forRef:nil withConnectionMethod:swypConnectionMethodBluetooth];
			SRELS(newSession);
			SRELS(serverCandidate);
		}
		
		SRELS(newPeerStreamSet);
	
	}
}

-(void)receiveData:(NSData*)data fromPeer:(NSString*)peerName inSession:(GKSession*)session context:(void*)context{
	swypGKPeerAbstractedStreamSet * sendToSet = [_activeAbstractedStreamSetsByPeerName valueForKey:peerName];
	assert(sendToSet != nil);
	if (sendToSet == nil){
		EXOLog(@"Data sent to uninitialized peer named %@", peerName);
		return;
	}

	[sendToSet addDataToPeerReadStream:data];
}

#pragma mark abstraction
#pragma mark swypGKPeerAbstractedStreamSetDelegate
-(void)	peerAbstractedStreamSet:(swypGKPeerAbstractedStreamSet*)peerAbstraction wantsDataSent:(NSData*)sendData toPeerNamed:(NSString*)peerName{
	
	NSError *sendError = nil;
	[_gameKitPeerSession sendData:sendData toPeers:[NSArray arrayWithObject:peerName] withDataMode:GKSendDataReliable error:&sendError];
	
	if (sendError != nil){
		EXOLog(@"Error sending data %@",[sendError description]);
	}
	
	assert(sendError == nil);
}

-(void)	peerAbstractedStreamSetDidClose:(swypGKPeerAbstractedStreamSet*)peerAbstraction withPeerNamed:(NSString*)peerName{
	
	[_gameKitPeerSession disconnectPeerFromAllPeers:peerName];
	[_activeAbstractedStreamSetsByPeerName removeObjectForKey:peerName];
}

#pragma mark - private
-(void)	_updateInterfaceActivity{
	if ([_swypOutTimeoutTimerBySwypInfoRef count] > 0 || [_swypInTimeoutTimerBySwypInfoRef count] > 0){
		[_gameKitPeerSession setAvailable:TRUE];
	}else{
		[_gameKitPeerSession setAvailable:FALSE];		
	}
	
	if ([_validSwypInForConnectionCreation count] == 0){
		for (NSString * peer in _pendingGKPeerServerConnections){
			[_gameKitPeerSession cancelConnectToPeer:peer];
		}
	}
	
	if ([_validSwypOutsForConnectionReceipt count] == 0){
		for (NSString * peer in _pendingGKPeerClientConnections){
			[_gameKitPeerSession cancelConnectToPeer:peer];
		}
	}
}

@end
