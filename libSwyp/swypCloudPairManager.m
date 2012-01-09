//
//  swypCloudPairManager.m
//  swyp
//
//  Created by Alexander List on 1/4/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import "swypCloudPairManager.h"


@implementation swypCloudPairManager
@synthesize cloudService = _cloudService, pairServerManager = _pairServerManager, delegate = _delegate;

#pragma mark public
-(swypCloudNetService*)cloudService{
	if (_cloudService == nil){
		_cloudService	=	[[swypCloudNetService alloc] initWithDelegate:self];
	}
	return _cloudService;
}

-(swypPairServerInteractionManger*)pairServerManager{
	if (_pairServerManager == nil){
		
		_pairServerManager	=	[[swypPairServerInteractionManger alloc] initWithDelegate:self];
	}
	return _pairServerManager;
}

#pragma mark swyp updates
//out
-(void)swypOutBegan:(swypInfoRef*)swyp{
	[_cloudPairPendingSwypRefs addObject:swyp];
	
	[[self pairServerManager] postSwypToPairServer:swyp withUserInfo:[self _userInfoDictionary]];
}
-(void)swypOutCompleted:(swypInfoRef*)swyp{
	[[self pairServerManager] putSwypUpdateToPairServer:swyp swypToken:[_swypTokenBySwypRef objectForKey:[NSValue valueWithNonretainedObject:swyp]] withUserInfo:[self _userInfoDictionary]];
}
-(void)swypOutFailed:(swypInfoRef*)swyp{
	[[self pairServerManager] deleteSwypFromPairServer:swyp swypToken:[_swypTokenBySwypRef objectForKey:[NSValue valueWithNonretainedObject:swyp]]];
	
	[self _invalidateSwypRef:swyp];
}
//in
-(void)swypInCompleted:	(swypInfoRef*)swyp{
	[_cloudPairPendingSwypRefs addObject:swyp];

	[[self pairServerManager] postSwypToPairServer:swyp withUserInfo:[self _userInfoDictionary]];
}

-(void)	suspendNetworkActivity{
	[[self cloudService] suspendNetworkActivity];
}
-(void)	resumeNetworkActivity{
	[[self cloudService] resumeNetworkActivity];	
}

#pragma mark NSObject
-(id)initWithSwypCloudPairManagerDelegate:(id<swypCloudPairManagerDelegate>) delegate{
	if (self = [super init]){
		_delegate	=	delegate;
		_swypTokenBySwypRef		= [NSMutableDictionary new];
		_swypRefByPeerInfo		= [NSMutableDictionary new];
		_cloudPairPendingSwypRefs	= [NSMutableSet new];

	}
	return self;
}

-(void)dealloc{
	SRELS(_swypTokenBySwypRef);
	SRELS(_swypRefByPeerInfo);
	//should invalidate all pending httpRequestManager requests
	SRELS(_cloudPairPendingSwypRefs);
	SRELS(_cloudService);
	SRELS(_pairServerManager);
	_delegate	= nil;
	
	[super dealloc];
}

#pragma mark - private
-(NSDictionary*)_userInfoDictionary{
	NSMutableDictionary* infoDictionary	= [NSMutableDictionary dictionary];
	[infoDictionary setValue:[NSNumber numberWithInt:[[self cloudService] portNumber]] forKey:@"port"];
	[infoDictionary setValue:@"long" forKey:@"longitude"];
	[infoDictionary setValue:@"lat" forKey:@"latitude"];
	return infoDictionary;
}

-(void)	_invalidateSwypRef:(swypInfoRef*)swyp{
	[_swypTokenBySwypRef removeObjectForKey:[NSValue valueWithNonretainedObject:swyp]];
	[_cloudPairPendingSwypRefs removeObject:swyp];
}

#pragma mark - delegation
#pragma mark swypCloudNetServiceDelegate
-(void)cloudNetService:(swypCloudNetService*)service didCreateInputStream:(NSInputStream*)inputStream outputStream:(NSOutputStream*)outputStream withPeerFromInfo:(NSDictionary*)peerInfo{
	swypServerCandidate * candidate = [[swypServerCandidate alloc] init];
	// if xmpp 	[candidate setNametag:[peerInfo valueForKey:@"smppPeer"]];

	swypInfoRef *swypRef			= 	[_swypRefByPeerInfo objectForKey:[NSValue valueWithNonretainedObject:peerInfo]];
	
	if (swypRef == nil){
		return;
	}else{
		//cleanup time
		[self _invalidateSwypRef:swypRef];
		[_swypRefByPeerInfo removeObjectForKey:[NSValue valueWithNonretainedObject:peerInfo]]; //autoreleasing here
	}
	
	[candidate setMatchedLocalSwypInfo:swypRef];

	[_delegate swypCloudPairManager:self didCreateSwypConnectionToServer:candidate withStreamIn:inputStream streamOut:outputStream];

	SRELS(candidate);
}
-(void)cloudNetService:(swypCloudNetService*)service didReceiveInputStream:(NSInputStream*)inputStream outputStream:(NSOutputStream*)outputStream withPeerFromInfo:(NSDictionary*)peerInfo{
	swypClientCandidate * candidate =	[[swypClientCandidate alloc] init];
	// if xmpp 	[candidate setNametag:[peerInfo valueForKey:@"smppPeer"]];
	
	[_delegate swypCloudPairManager:self didReceiveSwypConnectionFromClient:candidate withStreamIn:inputStream streamOut:outputStream];
	swypInfoRef *swypRef	= 	[_swypRefByPeerInfo objectForKey:[NSValue valueWithNonretainedObject:peerInfo]];
	[_swypTokenBySwypRef removeObjectForKey:[NSValue valueWithNonretainedObject:swypRef]];
	[_swypRefByPeerInfo removeObjectForKey:[NSValue valueWithNonretainedObject:peerInfo]]; 
	
	SRELS(candidate);
	
}
-(void)cloudNetService:(swypCloudNetService*)service didFailToCreateConnectionWithPeerFromInfo:(NSDictionary*)peerInfo{

	swypInfoRef *swypRef	= 	[_swypRefByPeerInfo objectForKey:[NSValue valueWithNonretainedObject:peerInfo]];
	[self _invalidateSwypRef:swypRef];
	[_swypRefByPeerInfo removeObjectForKey:[NSValue valueWithNonretainedObject:peerInfo]]; 
}

#pragma mark swypPairServerInteractionMangerDelegate
-(void)swypPairServerInteractionManger:(swypPairServerInteractionManger*)manager didReturnSwypToken:(NSString*)token forSwypRef:(swypInfoRef*)swyp withPeerInfo:(NSDictionary*)peerInfo{
	if ([_cloudPairPendingSwypRefs containsObject:swyp] == NO){
		EXOLog(@"%@",@"received response, but localswyp already failed");
		return;
	}
	
	[_swypTokenBySwypRef setObject:token forKey:[NSValue valueWithNonretainedObject:swyp]];
		
	if (peerInfo){
		[_swypRefByPeerInfo setObject:swyp forKey:[NSValue valueWithNonretainedObject:peerInfo]];
		
		if ([swyp swypType] == swypInfoRefTypeSwypIn){
			[[self cloudService] beginConnectionToPeerWithInfo:peerInfo];
			EXOLog(@"%@", @"attempting WAN conneciton after swypIn pairing");
		}else{
			EXOLog(@"%@", @"got swypOut peerInfo after pairing");
		}
	}else if ([swyp swypType] == swypInfoRefTypeSwypOut){

		[NSTimer scheduledTimerWithTimeInterval:.5 target:[NSBlockOperation blockOperationWithBlock:^{[[self pairServerManager] updateSwypPairStatus:swyp swypToken:[_swypTokenBySwypRef objectForKey:[NSValue valueWithNonretainedObject:swyp]]];}] selector:@selector(start) userInfo:nil repeats:NO];
		
		EXOLog(@"%@",@"Automatically scheduling swypOut swypPair update after pending-peer response");
	}else{
		EXOLog(@"%@",@"Weird no-peer no-fail response from swyp-in");
	}
}

-(void)swypPairServerInteractionManger:(swypPairServerInteractionManger*)manager didFailToGetSwypInfoForSwypRef:(swypInfoRef*)swyp orSwypToken:(NSString*)token{
	
	[self _invalidateSwypRef:swyp];
}

@end
