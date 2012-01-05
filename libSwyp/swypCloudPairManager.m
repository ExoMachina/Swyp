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

		if (_swypTokenBySwypRef == nil)	_swypTokenBySwypRef		= [NSMutableDictionary new];
		if (_swypRefByPeerInfo == nil)	_swypRefByPeerInfo		= [NSMutableDictionary new];
		
		_pairServerManager	=	[[swypPairServerInteractionManger alloc] initWithDelegate:self];
	}
	return _pairServerManager;
}

#pragma mark swyp updates
//out
-(void)swypOutBegan:(swypInfoRef*)swyp{
	[[self pairServerManager] postSwypToPairServer:swyp withUserInfo:[self _userInfoDictionary]];
}
-(void)swypOutCompleted:(swypInfoRef*)swyp{
	[[self pairServerManager] putSwypUpdateToPairServer:swyp swypToken:[_swypTokenBySwypRef objectForKey:[NSValue valueWithNonretainedObject:swyp]] withUserInfo:[self _userInfoDictionary]];

	[NSTimer scheduledTimerWithTimeInterval:1 target:[NSBlockOperation blockOperationWithBlock:^{[[self pairServerManager] updateSwypPairStatus:swyp swypToken:[_swypTokenBySwypRef objectForKey:[NSValue valueWithNonretainedObject:swyp]]];}] selector:@selector(start) userInfo:nil repeats:NO];
}
-(void)swypOutFailed:(swypInfoRef*)swyp{
	[[self pairServerManager] deleteSwypFromPairServer:swyp swypToken:[_swypTokenBySwypRef objectForKey:[NSValue valueWithNonretainedObject:swyp]]];
}
//in
-(void)swypInCompleted:	(swypInfoRef*)swyp{
	[[self pairServerManager] postSwypToPairServer:swyp withUserInfo:[self _userInfoDictionary]];
}

#pragma mark NSObject
-(id)initWithSwypCloudPairManagerDelegate:(id<swypCloudPairManagerDelegate>) delegate{
	if (self = [super init]){
		_delegate	=	delegate;
	}
	return self;
}

-(void)dealloc{
	
	SRELS(_swypTokenBySwypRef);
	SRELS(_swypRefByPeerInfo);
	//should invalidate all pending httpRequestManager requests
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


#pragma mark - delegation
#pragma mark swypCloudNetServiceDelegate
-(void)cloudNetService:(swypCloudNetService*)service didCreateInputStream:(NSInputStream*)inputStream outputStream:(NSOutputStream*)outputStream withPeerFromInfo:(NSDictionary*)peerInfo{
	
}
-(void)cloudNetService:(swypCloudNetService*)service didReceiveInputStream:(NSInputStream*)inputStream outputStream:(NSOutputStream*)outputStream withPeerFromInfo:(NSDictionary*)peerInfo{
	
}
-(void)cloudNetService:(swypCloudNetService*)service didFailToCreateConnectionWithPeerFromInfo:(NSDictionary*)peerInfo{
	
}

#pragma mark swypPairServerInteractionMangerDelegate
-(void)swypPairServerInteractionManger:(swypPairServerInteractionManger*)manager didReturnSwypToken:(NSString*)token forSwypRef:(swypInfoRef*)swyp withPeerInfo:(NSDictionary*)peerInfo{
	[_swypTokenBySwypRef setObject:token forKey:[NSValue valueWithNonretainedObject:swyp]];
	
	if (peerInfo){
		[_swypRefByPeerInfo setObject:swyp forKey:[NSValue valueWithNonretainedObject:peerInfo]];
		[_cloudService beginConnectionToPeerWithInfo:peerInfo];
	}

#pragma mark TODO: remove old swyps
	//we could go on an infitite loop until we hit "failed" or the server actually stops responding, or we've expired locally; at that point we can drop the pair attempt -- but for now we're good
}

-(void)swypPairServerInteractionManger:(swypPairServerInteractionManger*)manager didFailToGetSwypInfoForSwypRef:(swypInfoRef*)swyp orSwypToken:(NSString*)token{
	//if peer exists, remove it
}

@end
