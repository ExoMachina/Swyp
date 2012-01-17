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
	for (swypInfoRef * ref in [[_validSwypOutsForConnectionReceipt copy]autorelease]){
		[self stopAdvertisingSwypOut:ref];
	}
	for (swypInfoRef * ref in [[_validSwypInForConnectionCreation copy]autorelease]){
		[self stopFindingSwypInServerCandidatesForRef:ref];
	}
	
	for (NSString * peer in _pendingGKPeerServerConnections){
		[_gameKitPeerSession cancelConnectToPeer:peer];
	}
	
	for (swypGKPeerAbstractedStreamSet * streamSet in [_activeAbstractedStreamSetsByPeerName allValues]){
		[streamSet invalidateStreamSet];
	}
	
	[_connectabilityTimer invalidate];
	SRELS(_connectabilityTimer);
	
	[self _updateInterfaceActivity];
	SRELS(_gameKitPeerSession);
	
}

-(void)	resumeNetworkActivity{
	if (_gameKitPeerSession == nil){
		_gameKitPeerSession	=	[[GKSession alloc] initWithSessionID:@"swyp" displayName:nil sessionMode:GKSessionModePeer];
		[_gameKitPeerSession setDisconnectTimeout:5];
		[_gameKitPeerSession setDelegate:self];
		[_gameKitPeerSession setDataReceiveHandler:self withContext:nil];
		[_gameKitPeerSession setAvailable:TRUE];
	}
	
	//we should add something about BluetoothAvailabilityChangedNotification ; our issue is that we don't get warnings about bluetooth when starting the session, probably because delegate is set SECOND
	
	//for some reason, after a connection is on one end, we get failure on one side, but it doesn't disconnect the other...
	
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
		
		NSTimer * advertiseTimer	=	[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(_advertiseTimedOutWithTimer:) userInfo:ref repeats:NO];
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
	
	[self _makeConnectionIfPossible];
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
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_bluetoothAvailabilityChanged:) name:@"BluetoothAvailabilityChangedNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_bluetoothConnectabilityChanged:) name:@"BluetoothConnectabilityChangedNotification" object:nil];
		
		_delegate = delegate;
		_swypOutTimeoutTimerBySwypInfoRef	=	[NSMutableDictionary new];
		_validSwypOutsForConnectionReceipt	=	[NSMutableSet new];
		
		_swypInTimeoutTimerBySwypInfoRef	=	[NSMutableDictionary new];
		_validSwypInForConnectionCreation	=	[NSMutableSet new];
		
		_pendingGKPeerServerConnections		=	[NSMutableSet new];
		_pendingGKPeerClientConnections		=	[NSMutableSet new];
		
		_availablePeers						=	[NSMutableSet new];
		
		_activeAbstractedStreamSetsByPeerName =	[NSMutableDictionary new];

	}
	return self;
}

-(void)dealloc{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[self suspendNetworkActivity];
	
	SRELS(_swypOutTimeoutTimerBySwypInfoRef);
	SRELS(_validSwypOutsForConnectionReceipt);
	SRELS(_swypInTimeoutTimerBySwypInfoRef);
	SRELS(_validSwypInForConnectionCreation);
	
	SRELS(_pendingGKPeerServerConnections);
	SRELS(_pendingGKPeerClientConnections);
	
	SRELS(_availablePeers);
	
	SRELS(_activeAbstractedStreamSetsByPeerName);
	
	SRELS(_connectabilityTimer);
	[_bluetoothPromptController setDelegate:nil];
	SRELS(_bluetoothPromptController);
	[super dealloc];
}


#pragma mark gamekit
#pragma mark GKPeerPickerDelegate
- (void)peerPickerController:(GKPeerPickerController *)picker didSelectConnectionType:(GKPeerPickerConnectionType)type{
	[_bluetoothPromptController dismiss];
	[_bluetoothPromptController autorelease];
	_bluetoothPromptController = nil;
}
- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker{
	[_bluetoothPromptController dismiss];
	[_bluetoothPromptController autorelease];
	_bluetoothPromptController = nil;
	//tell someone that bluetooth is broken
}

#pragma mark GKSessionDelegate
- (void)session:(GKSession *)session didFailWithError:(NSError *)error{
	if ([[error domain] isEqual:kGKSessionErrorDomain] && ([error code] == GKSessionCannotEnableError)){
		[self _launchBluetoothPromptPeerPicker];
		
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
		NSError * connectError = nil;
		[_gameKitPeerSession acceptConnectionFromPeer:peerID error:&connectError];
		if (connectError != nil){
			EXOLog(@"Error connecting to peer %@: %@",peerID,[connectError description]);
		}
		[_pendingGKPeerClientConnections addObject:peerID];
	}else {
		[_gameKitPeerSession denyConnectionFromPeer:peerID];
	}
}
- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state{
	if (state == GKPeerStateAvailable){
		EXOLog(@"Found bluetooth peer: %@",peerID);
		[_availablePeers addObject:peerID];
		[self _makeConnectionIfPossible];
	}else if (state == GKPeerStateConnected){
		EXOLog(@"Connected via bluetooth to peer: %@",peerID);
		
		swypGKPeerAbstractedStreamSet * newPeerStreamSet	=	[[[swypGKPeerAbstractedStreamSet alloc] initWithPeerName:peerID streamSetDelegate:self] autorelease];
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
				return;
			}
						
			swypServerCandidate * serverCandidate	= [[swypServerCandidate alloc] init];
			
			//as a client, we must set matchedLocalSwypInfo
			[serverCandidate setMatchedLocalSwypInfo:[_validSwypInForConnectionCreation anyObject]];
			
			swypConnectionSession * newSession		= [[swypConnectionSession alloc] initWithSwypCandidate:serverCandidate inputStream:[newPeerStreamSet peerReadStream]  outputStream:[newPeerStreamSet peerWriteStream]];

			//tell manager that a server connection can be tapped if interested
			[_delegate interfaceManager:self madeUninitializedSwypServerCandidateConnectionSession:newSession forRef:[_validSwypInForConnectionCreation anyObject] withConnectionMethod:swypConnectionMethodBluetooth];
			SRELS(newSession);
			SRELS(serverCandidate);
		}
		
	
	}else if (state == GKPeerStateDisconnected){
		EXOLog(@"GKSession says peer is discon: %@",peerID);
		swypGKPeerAbstractedStreamSet * existingStreamSet	=	[_activeAbstractedStreamSetsByPeerName valueForKey:peerID];
		if (existingStreamSet != nil){
			[existingStreamSet invalidateStreamSet];
		}
	}else if (state == GKPeerStateUnavailable){
		EXOLog(@"GKSession says peer is unavail: %@",peerID);
		[_availablePeers removeObject:peerID];
	}
}

-(void)receiveData:(NSData*)data fromPeer:(NSString*)peerName inSession:(GKSession*)session context:(void*)context{
	swypGKPeerAbstractedStreamSet * sendToSet = [_activeAbstractedStreamSetsByPeerName valueForKey:peerName];
	if (sendToSet == nil){
		EXOLog(@"Data sent to uninitialized, or pre-released peer named %@", peerName);
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
	EXOLog(@"peerAbstractedStreamSetDidClose: %@", peerName);
	[_gameKitPeerSession disconnectPeerFromAllPeers:peerName];
	[_activeAbstractedStreamSetsByPeerName removeObjectForKey:peerName];
}

#pragma mark - private
#pragma mark bluetooth detection
-(void)_bluetoothAvailabilityChanged:(id)sender{
	EXOLog(@"bluetooth availability notification: %@",[sender description]);
	//if this notification shows but connectability doesn't, then we know BT is disabled, and we prompt to enable.
	if (_connectabilityTimer == nil){
		_connectabilityTimer = [[NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(_connectabilityTimeoutOccured:) userInfo:nil repeats:NO] retain];
	}
}
-(void)_bluetoothConnectabilityChanged:(id)sender{
	//indicating that bluetooth is enabled
	EXOLog(@"bluetooth connectivity notification: %@",[sender description]);
	if (_bluetoothPromptController != nil){
		[_bluetoothPromptController setDelegate:nil];
		[_bluetoothPromptController dismiss];
		[_bluetoothPromptController autorelease];
		_bluetoothPromptController = nil;
	}else{
		[_connectabilityTimer invalidate];
	}
}

-(void) _connectabilityTimeoutOccured:(NSTimer*)sender{
	[_connectabilityTimer invalidate];
	[self _launchBluetoothPromptPeerPicker];
}
	
-(void)_launchBluetoothPromptPeerPicker{
	EXOLog(@"%@",@"Bluetooth Disabled: launching peer picker");
	//let's prompt to turn on:
	if (_bluetoothPromptController == nil){
		_bluetoothPromptController =  [[GKPeerPickerController alloc] init];
		[_bluetoothPromptController setDelegate:self];
		[_bluetoothPromptController setConnectionTypesMask:GKPeerPickerConnectionTypeNearby];
	}
	[_bluetoothPromptController show];	
}


#pragma mark connections
-(void)	_updateInterfaceActivity{
	
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

-(void) _makeConnectionIfPossible{
	if ([_validSwypInForConnectionCreation count] > 0){
		for (NSString * peerID in _availablePeers){
			EXOLog(@"Connecting via bluetooth for swypIn to peer: %@",peerID);
			[_gameKitPeerSession connectToPeer:peerID withTimeout:5];
			[_pendingGKPeerServerConnections addObject:peerID];
		}
	}

}

@end
