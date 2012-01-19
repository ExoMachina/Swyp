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
	
	[_gameKitPeerSession disconnectFromAllPeers];
	
	
	for (swypGKPeerAbstractedStreamSet * streamSet in [_activeAbstractedStreamSetsByPeerName allValues]){
		[streamSet invalidateFromManager];
	}
	[_activeAbstractedStreamSetsByPeerName removeAllObjects];
	
	[_connectabilityTimer invalidate];
	SRELS(_connectabilityTimer);
	
	SRELS(_gameKitPeerSession);
	
}

-(GKSession*)gameKitPeerSession{
	if (_gameKitPeerSession == nil){
		_gameKitPeerSession	=	[[GKSession alloc] initWithSessionID:@"swyp" displayName:nil sessionMode:GKSessionModePeer];
		[_gameKitPeerSession setDisconnectTimeout:5];
		[_gameKitPeerSession setDelegate:self];
		[_gameKitPeerSession setDataReceiveHandler:self withContext:nil];
		[_gameKitPeerSession setAvailable:TRUE];
	}
	return _gameKitPeerSession;
}

-(void)	resumeNetworkActivity{
	[self gameKitPeerSession];
	//we should add something about BluetoothAvailabilityChangedNotification ; our issue is that we don't get warnings about bluetooth when starting the session, probably because delegate is set SECOND
	
	//for some reason, after a connection is on one end, we get failure on one side, but it doesn't disconnect the other...
	
}

-(void) advertiseSwypOutAsPending:(swypInfoRef*)ref{
	NSTimer * advertiseTimer	=	[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(_advertiseAsPendingTimedOutWithTimer:) userInfo:ref repeats:NO];
	[_swypOutTimeoutTimerBySwypInfoRef setObject:advertiseTimer forKey:[NSValue valueWithNonretainedObject:ref]];	
	
}

-(void) advertiseSwypOutAsCompleted:(swypInfoRef*)ref{
	//We'll try clearing out existing swypOuts to see if we get more responsivenes
	for (swypInfoRef * ref in _validSwypOutsForConnectionReceipt){
		[self stopAdvertisingSwypOut:ref];
	}
	
	NSTimer * pendingTimer	=	[_swypOutTimeoutTimerBySwypInfoRef objectForKey:[NSValue valueWithNonretainedObject:ref]];
	if (pendingTimer == nil){
		return;	
	}else{
//		EXOLog(@"advertiseSwypOutAsCompleted in swypBluetoothPairManager from ref@time:%@",[[ref startDate]description]);
		[pendingTimer invalidate];
		
		NSTimer * advertiseTimer	=	[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(_advertiseTimedOutWithTimer:) userInfo:ref repeats:NO];
		[_swypOutTimeoutTimerBySwypInfoRef setObject:advertiseTimer forKey:[NSValue valueWithNonretainedObject:ref]];	
		[_validSwypOutsForConnectionReceipt addObject:ref];

		[self _createSessionsIfNeeded];
	}
	
}

-(void) stopAdvertisingSwypOut:(swypInfoRef*)ref{
//	EXOLog(@"No longer advertising outRef in swypBluetoothPairManager from time: %@",[[ref startDate] description]);
	
	if ([_validSwypOutsForConnectionReceipt containsObject:ref] == NO){
		return;
	}
	
	NSTimer * advertiseTimer	=	[_swypOutTimeoutTimerBySwypInfoRef objectForKey:[NSValue valueWithNonretainedObject:ref]];
	
	[advertiseTimer invalidate];

	[_swypOutTimeoutTimerBySwypInfoRef removeObjectForKey:[NSValue valueWithNonretainedObject:ref]];	
	[_validSwypOutsForConnectionReceipt removeObject:ref];
	
	[_delegate interfaceManager:self isDoneAdvertisingSwypOutAsPending:ref forConnectionMethod:swypConnectionMethodBluetooth];

}

-(BOOL) isAdvertisingSwypOut:(swypInfoRef*)ref{
	return ([_swypOutTimeoutTimerBySwypInfoRef objectForKey:[NSValue valueWithNonretainedObject:ref]] != nil);
}

-(void)	startFindingSwypInServerCandidatesForRef:(swypInfoRef*)ref{
	NSTimer * searchTimer	=	[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(_findServersTimedOutWithTimer:) userInfo:ref repeats:NO];
	[_swypInTimeoutTimerBySwypInfoRef setObject:searchTimer forKey:[NSValue valueWithNonretainedObject:ref]];	
	[_validSwypInForConnectionCreation addObject:ref];
	
	
	[self _createSessionsIfNeeded];
}

-(void) stopFindingSwypInServerCandidatesForRef:(swypInfoRef*)ref{
	if ([_validSwypInForConnectionCreation containsObject:ref] == NO)
		return;
	
	[_swypInTimeoutTimerBySwypInfoRef removeObjectForKey:[NSValue valueWithNonretainedObject:ref]];
	[_validSwypInForConnectionCreation removeObject:ref];

	[_delegate interfaceManager:self isDoneSearchForSwypInServerCandidatesForRef:ref forConnectionMethod:swypConnectionMethodBluetooth];
	
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
						
		_activeAbstractedStreamSetsByPeerName =	[NSMutableDictionary new];
		
		_bluetoothEnabled					= FALSE; //begin with false until proved otherwise

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
			
	SRELS(_activeAbstractedStreamSetsByPeerName);
	
	SRELS(_connectabilityTimer);
	[_bluetoothPromptController setDelegate:nil];
	SRELS(_bluetoothPromptController);
	[super dealloc];
}


#pragma mark gamekit
#pragma mark GKPeerPickerDelegate
- (void)peerPickerController:(GKPeerPickerController *)picker didSelectConnectionType:(GKPeerPickerConnectionType)type{
	_bluetoothEnabled	= TRUE;
	[_bluetoothPromptController dismiss];
	[_bluetoothPromptController setDelegate:nil];
	_bluetoothPromptController = nil;
}
- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker{
	[_bluetoothPromptController dismiss];
	[_bluetoothPromptController setDelegate:nil];
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
	EXOLog(@"Failed connecting to peer :%@",peerID);
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID{
	EXOLog(@"Accepting connection via bluetooth for peer: %@",peerID);
	NSError * connectError = nil;
	[_gameKitPeerSession acceptConnectionFromPeer:peerID error:&connectError];
	if (connectError != nil){
		EXOLog(@"Error connecting to peer %@: %@",peerID,[connectError description]);
	}
	
}
- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state{
	
	if (state == GKPeerStateAvailable){
		EXOLog(@"Found bluetooth peer, preconnecting: %@",peerID);
		[_gameKitPeerSession connectToPeer:peerID withTimeout:5];
		
		_bluetoothEnabled	= TRUE;
		
		if (_bluetoothPromptController != nil){
			[_bluetoothPromptController setDelegate:nil];
			[_bluetoothPromptController dismiss]; //this command seems to deallocating the controller.
			_bluetoothPromptController	=	nil; // set to nil to remove.
		}
		
	}else if (state == GKPeerStateConnected){
		//great, we're connected, but NBD, we'll use it if there's a swyp later
		//we are de-coupling connections on swyp level from those on GameKit
		EXOLog(@"pre-connected via bluetooth to peer: %@",peerID);
		[self _createSessionsIfNeeded];
		
	}else if (state == GKPeerStateDisconnected){
		EXOLog(@"GKSession says peer is discon: %@",peerID);
		swypGKPeerAbstractedStreamSet * existingStreamSet	=	[_activeAbstractedStreamSetsByPeerName valueForKey:peerID];
		if (existingStreamSet != nil){
			[existingStreamSet invalidateFromManager];
		}

//		if ([_activeAbstractedStreamSetsByPeerName count] == 0){
//			[self _restartBluetooth];
//		}
	}else if (state == GKPeerStateUnavailable){
		EXOLog(@"GKSession says peer is unavail: %@",peerID);
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
	//all we need to do is remove it from here
	[peerAbstraction setDelegate:nil];
	[_activeAbstractedStreamSetsByPeerName removeObjectForKey:peerName];
	
}

#pragma mark - private
#pragma mark bluetooth detection
-(void)_bluetoothAvailabilityChanged:(id)sender{
	EXOLog(@"bluetooth availability notification: %@",[sender description]);
	//if this notification shows but connectability doesn't, then we know BT is disabled, and we prompt to enable.
	if (_connectabilityTimer == nil && _bluetoothEnabled == FALSE){
		_connectabilityTimer = [[NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(_connectabilityTimeoutOccured:) userInfo:nil repeats:NO] retain];
	}
}
-(void)_bluetoothConnectabilityChanged:(id)sender{
	//indicating that bluetooth is enabled
	EXOLog(@"bluetooth connectivity notification: %@",[sender description]);
	_bluetoothEnabled = TRUE;
	if (_bluetoothPromptController != nil){
		[_bluetoothPromptController setDelegate:nil];
		[_bluetoothPromptController dismiss]; //this command seems to deallocating the controller.
		_bluetoothPromptController	=	nil; // set to nil to remove.
	}else{
		[_connectabilityTimer invalidate];
	}
}

-(void) _connectabilityTimeoutOccured:(NSTimer*)sender{
	if (_bluetoothEnabled == FALSE){
		[self _launchBluetoothPromptPeerPicker];
	}
}
	
-(void)_launchBluetoothPromptPeerPicker{
	EXOLog(@"%@",@"Bluetooth Disabled: launching peer picker");
	//let's prompt to turn on:
	//keep in mind that there is a shitty bug where calling dismiss literally 'DEALLOCS' the picker!
	if (_bluetoothPromptController == nil){
		_bluetoothPromptController =  [[GKPeerPickerController alloc] init];
		[_bluetoothPromptController setDelegate:self];
		[_bluetoothPromptController setConnectionTypesMask:GKPeerPickerConnectionTypeNearby];
	}
	[_bluetoothPromptController show];	
}


#pragma mark connections

-(void) _restartBluetooth{
	SRELS(_gameKitPeerSession);
	[self gameKitPeerSession];
}

-(void) _createSessionsIfNeeded{
	//at this point we're already connected, but we need to make sessions out of users
	if (([_validSwypInForConnectionCreation count] == 0 )&& ([_validSwypOutsForConnectionReceipt count] == 0)){
		return;
	}
			
	for (NSString * peerID in [_gameKitPeerSession peersWithConnectionState:GKPeerStateConnected]){
		if ([self _peerIsInConnection:peerID]){
			EXOLog(@"Session aleady exists with peerID:%@",peerID);
			continue;
		}
		
		swypGKPeerAbstractedStreamSet * newPeerStreamSet	=	[[[swypGKPeerAbstractedStreamSet alloc] initWithPeerName:peerID streamSetDelegate:self] autorelease];
		[_activeAbstractedStreamSetsByPeerName setObject:newPeerStreamSet forKey:peerID];
		
		//this sucks, but I'll try to explain:
		
		//see if it's a pending connection from a client
		if ([_validSwypOutsForConnectionReceipt count] > 0){
			
			//create a client candidate
			//they are connecting to us
			swypClientCandidate * clientCandidate	= [[swypClientCandidate alloc] init];
			
			//wrap it in a new connection session; setting the input and output stream to your new swypGKPeerAbstractedStreamSet
			swypConnectionSession * newSession		= [[swypConnectionSession alloc] initWithSwypCandidate:clientCandidate inputStream:[newPeerStreamSet peerReadStream]  outputStream:[newPeerStreamSet peerWriteStream]];
			
			EXOLog(@"Created client candidate & session out of peer %@",peerID);
			//tell the delegate that a client is waiting to chat
			[_delegate interfaceManager:self receivedUninitializedSwypClientCandidateConnectionSession:newSession withConnectionMethod:swypConnectionMethodBluetooth];
			SRELS(newSession);
			SRELS(clientCandidate);
			
			//otherwise it's probably a pending connection to a server
		}else if ([_validSwypInForConnectionCreation count] > 0){
			
			swypServerCandidate * serverCandidate	= [[swypServerCandidate alloc] init];
			
			//as a client, we must set matchedLocalSwypInfo
			[serverCandidate setMatchedLocalSwypInfo:[_validSwypInForConnectionCreation anyObject]];
			
			swypConnectionSession * newSession		= [[swypConnectionSession alloc] initWithSwypCandidate:serverCandidate inputStream:[newPeerStreamSet peerReadStream]  outputStream:[newPeerStreamSet peerWriteStream]];
			
			EXOLog(@"Created server candidate & session out of peer %@",peerID);
			//tell manager that a server connection can be tapped if interested
			[_delegate interfaceManager:self madeUninitializedSwypServerCandidateConnectionSession:newSession forRef:[serverCandidate matchedLocalSwypInfo] withConnectionMethod:swypConnectionMethodBluetooth];
			SRELS(newSession);
			SRELS(serverCandidate);
		}else{
			//otherwise what are we even doing?
			EXOLog(@"did not create candidate out of peer %@",peerID);
			[_activeAbstractedStreamSetsByPeerName removeObjectForKey:peerID];
			newPeerStreamSet = nil;
		}
	}

}


-(BOOL)_peerIsInConnection:(NSString*)peerID{
	if ([_activeAbstractedStreamSetsByPeerName objectForKey:peerID] != nil){
		if ([[[_activeAbstractedStreamSetsByPeerName objectForKey:peerID] peerWriteStream] streamStatus] & (NSStreamStatusClosed | NSStreamStatusError) || [[[_activeAbstractedStreamSetsByPeerName objectForKey:peerID] peerWriteStream] streamStatus] == NSStreamStatusNotOpen){
			[[_activeAbstractedStreamSetsByPeerName objectForKey:peerID] invalidateFromManager];
			[_activeAbstractedStreamSetsByPeerName removeObjectForKey:peerID];
		}else{
			return TRUE;
		}
	}
	return FALSE;
}


@end
