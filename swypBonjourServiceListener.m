//
//  swypBonjourServiceListener.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import "swypBonjourServiceListener.h"


@implementation swypBonjourServiceListener
@synthesize delegate = _delegate, serviceIsListening = _serviceIsListening;


#pragma mark candidates
-(NSSet*) allServerCandidates{
	if ([_serverCandidates count] == 0)
		return nil;
	
	return [NSSet setWithArray:[_serverCandidates allValues]];
}

#pragma mark NSNetServiceBrowserDelegate
- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser{
	_serviceIsListening	= YES;
}
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser{
	_serviceIsListening	= NO;
}
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict{
	_serviceIsListening	= NO;
	[_delegate bonjourServiceListenerFailedToBeginListen:self error:[NSError errorWithDomain:[errorDict valueForKey:NSNetServicesErrorDomain] code:[errorDict valueForKey:NSNetServicesErrorCode] userInfo:nil]];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing{
	swypServerCandidate * nextCandidate = [_serverCandidates objectForKey:[NSValue valueWithNonretainedObject:aNetService]];
	if (nextCandidate == nil){
		nextCandidate =	[[swypServerCandidate alloc] init];
		[nextCandidate	setNetService:aNetService];
		[nextCandidate	setAppearanceDate:[NSDate date]];
		
		[_serverCandidates setObject:nextCandidate forKey:[NSValue valueWithNonretainedObject:aNetService]];
	}
}
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing{
	[_serverCandidates removeObjectForKey:[NSValue valueWithNonretainedObject:aNetService]];
}

#pragma mark NSObject
-(id) init{
	if (self = [super init]){
		_serverBrowser		=	[[NSNetServiceBrowser alloc] init];
		[_serverBrowser			setDelegate:self];
		
		_serverCandidates	=	[[NSMutableDictionary alloc] init];
	}
	return self;
}

-(void)	dealloc{
	[self setServiceIsListening:FALSE];
	SRELS(_serverBrowser)
	SRELS(_serverCandidates);
	
	[super dealloc];
}


-(void)	setServiceIsListening:(BOOL)listening{
	if (_serviceIsListening == listening)
		return;
	
	if (listening == YES){
		[_serverBrowser searchForServicesOfType:@"_swyp._tcp." inDomain:@""];
	}else {
		[_serverBrowser	stop];
	}
}


@end
