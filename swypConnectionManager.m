//
//  swypConnectionManager.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import "swypConnectionManager.h"

@implementation swypConnectionManager
@synthesize delegate = _delegate, activeConnectionSessions = _activeConnectionSessions;

#pragma mark -
#pragma mark public 

-(void)	beginServices{
	[_bonjourListener	setServiceIsListening:TRUE];
}

-(void)	stopServices{
	[_bonjourListener	setServiceIsListening:FALSE];
	[_bonjourAdvertiser setAdvertising:FALSE];

	for (swypConnectionSession * session in _activeConnectionSessions){
		[session removeConnectionSessionInfoDelegate:self];
		[session removeDataDelegate:self];
		[session invalidate];
	}	
}

-(id) init{
	if (self = [super init]){
		_activeConnectionSessions	=	[[NSMutableSet alloc] init];

		_swypIns			= [[NSMutableSet alloc] init];
		_swypOuts			= [[NSMutableSet alloc] init];
		_swypOutTimeouts	= [[NSMutableSet alloc] init];
		_swypInTimeouts		= [[NSMutableSet alloc] init];
		
		_bonjourListener	= [[swypBonjourServiceListener alloc] init];
		[_bonjourListener	setDelegate:self];
		
		_bonjourAdvertiser	= [[swypBonjourServiceAdvertiser alloc] init];
		[_bonjourAdvertiser setDelegate:self];
		
		_handshakeManager	= [[swypHandshakeManager alloc] init];
		[_handshakeManager	setDelegate:self];
		
	}
	return self;
}

-(void)	dealloc{
	
	SRELS(_bonjourListener);
	SRELS(_bonjourAdvertiser);
	SRELS(_handshakeManager);
	
	for (NSTimer * timer in _swypOutTimeouts){
		[timer invalidate];
	}
	SRELS(_swypOutTimeouts);
	
	for (NSTimer * timer in _swypInTimeouts){
		[timer invalidate];
	}
	SRELS(_swypInTimeouts);
	
	SRELS(_activeConnectionSessions);
	
	
	SRELS(_swypIns);
	SRELS(_swypOuts);
	
	[super dealloc];
}

#pragma mark -
#pragma mark SWYP Responders

-(swypInfoRef*)	oldestSwypInSet:(NSSet*)swypSet{
	swypInfoRef * oldest = nil;
	for (swypInfoRef * next in swypSet){
		if ([[next startDate] timeIntervalSinceReferenceDate] < [[oldest startDate] timeIntervalSinceReferenceDate] || oldest == nil)
			oldest = next;
	}
	
	return oldest;
}
#pragma mark IN
-(void) swypInCompletedWithSwypInfoRef:	(swypInfoRef*)inInfo{
	NSTimer* swypInTimeout = [[NSTimer timerWithTimeInterval:4 target:self selector:@selector(swypInResponseTimeoutOccuredWithTimer:) userInfo:inInfo repeats:NO] retain];
	[[NSRunLoop mainRunLoop] addTimer:swypInTimeout forMode:NSRunLoopCommonModes];
	[_swypInTimeouts addObject:swypInTimeout];
	SRELS(swypInTimeout);

	[_handshakeManager beginHandshakeProcessWithServerCandidates:[_bonjourListener allServerCandidates]];

}
-(void) swypInResponseTimeoutOccuredWithTimer:	(NSTimer*)timeoutTimer{
	[_swypInTimeouts removeObject:timeoutTimer];
	
	swypInfoRef* swypInfo =	[timeoutTimer userInfo];
	if ([swypInfo isKindOfClass:[swypInfoRef class]]){
		[_swypIns removeObject:swypInfo];
	}
	
	if ([_swypInTimeouts count] == 0){
		EXOLog(@"no longer within swyp-in window");
	}
}

#pragma mark OUT
-(void)	swypOutStartedWithSwypInfoRef:	(swypInfoRef*)outInfo{
	[_bonjourAdvertiser setAdvertising:TRUE];
	[_swypOuts addObject:outInfo];
}
-(void)	swypOutCompletedWithSwypInfoRef:(swypInfoRef*)outInfo{
	NSTimer* swypOutTimeout = [[NSTimer timerWithTimeInterval:6 target:self selector:@selector(swypOutResponseTimeoutOccuredWithTimer:) userInfo:outInfo repeats:NO] retain];
	[[NSRunLoop mainRunLoop] addTimer:swypOutTimeout forMode:NSRunLoopCommonModes];
	[_swypOutTimeouts addObject:swypOutTimeout];
	SRELS(swypOutTimeout);
}
-(void)	swypOutFailedWithSwypInfoRef:	(swypInfoRef*)outInfo{
	[_swypOuts removeObject:outInfo];
	
	if (SetHasItems(_swypOuts) == NO){
		[_bonjourAdvertiser setAdvertising:FALSE];		
	}
}

-(void) swypOutResponseTimeoutOccuredWithTimer:	(NSTimer*)timeoutTimer{
	[_swypOutTimeouts removeObject:timeoutTimer];
	
	swypInfoRef* swypInfo =	[timeoutTimer userInfo];
	if ([swypInfo isKindOfClass:[swypInfoRef class]]){
		[_swypOuts removeObject:swypInfo];
	}
	
	if (SetHasItems(_swypOuts) == NO){
		[_bonjourAdvertiser setAdvertising:FALSE];		
	}
}

#pragma mark -
#pragma mark private
#pragma mark -
#pragma mark bonjourAdvertiser 
-(void)	bonjourServiceAdvertiserReceivedConnectionFromSwypClientCandidate:(swypClientCandidate*)clientCandidate withStreamIn:(NSInputStream*)inputStream streamOut:(NSOutputStream*)outputStream serviceAdvertiser: (swypBonjourServiceAdvertiser*)advertiser{
	[_handshakeManager beginHandshakeProcessWithClientCandidate:clientCandidate streamIn:inputStream streamOut:outputStream];
}

#pragma mark bonjourListener
-(void)	bonjourServiceListenerFoundServerCandidate: (swypServerCandidate*) serverCandidate withListener:(swypBonjourServiceListener*) serviceListener{
	EXOLog(@"Listener found server candidate: %@", [[serverCandidate netService] name]);
	if ([_swypInTimeouts count] > 0){
		[_handshakeManager beginHandshakeProcessWithServerCandidates:[NSSet setWithObject:serverCandidate]];
	}
}
-(void)	bonjourServiceListenerFailedToBeginListen:	(swypBonjourServiceListener*) listener	error:(NSError*)error{
	EXOLog(@"Listener failed to begin listen with error!:%@",[error description]);	
}


#pragma mark -
#pragma mark swypHandshakeManagerDelegate
-(NSArray*)	relevantSwypsForCandidate:	(swypCandidate*)candidate		withHandshakeManager:	(swypHandshakeManager*)manager{
	if ([candidate isKindOfClass:[swypServerCandidate class]]){
		
		return [NSArray arrayWithObject:[self oldestSwypInSet:_swypIns]];
	}else if ([candidate isKindOfClass:[swypClientCandidate class]]){
		
		return [_swypOuts allObjects];
	}
	
	return nil;
}

-(void)	connectionSessionCreationFailedForCandidate:(swypCandidate*)candidate		withHandshakeManager:	(swypHandshakeManager*)manager error:(NSError*)error{
	EXOLog(@"Candidate session failed creation with error: %@",[error description]);
}
-(void)	connectionSessionWasCreatedSuccessfully:	(swypConnectionSession*)session	withHandshakeManager:	(swypHandshakeManager*)manager{
	[session addDataDelegate:self];
	[session addConnectionSessionInfoDelegate:self];
	[_activeConnectionSessions addObject:session];
	[_delegate swypConnectionSessionWasCreated:session withConnectionManager:self];
}

#pragma mark -
#pragma mark swypConnectionSessionInfoDelegate
-(void) sessionStatusChanged:	(swypConnectionSessionStatus)status	inSession:(swypConnectionSession*)session{
}
-(void) sessionWillDie:			(swypConnectionSession*)session{	
}
-(void) sessionDied:			(swypConnectionSession*)session withError:(NSError*)error{
	[_activeConnectionSessions removeObject:session];
	[_delegate swypConnectionSessionWasInvalidated:session withConnectionManager:self error:error];
}
#pragma mark swypConnectionSessionDataDelegate
-(NSOutputStream*) streamToWriteReceivedDataWithTag:(NSString*)tag type:(swypFileTypeString*)type length:(NSUInteger)streamLength connectionSession:(swypConnectionSession*)session{
	if ([type isFileType:[swypFileTypeString swypControlPacketFileType]]){
		return [NSOutputStream outputStreamToMemory];
	}	
	
	return nil;
}
-(void) finishedReceivingDataWithOutputStream:(NSOutputStream*)stream error:(NSError*)error tag:(NSString*)tag type:(swypFileTypeString*)type connectionSession:(swypConnectionSession*)session{
	if ([type isFileType:[swypFileTypeString swypControlPacketFileType]]){
		//do something to handle this :)
		NSData	*	readStreamData	=	[stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
		
		NSDictionary *	receivedDictionary = nil;
		if ([readStreamData length] >0){
			NSString *	readStreamString	=	[NSString stringWithUTF8String:[readStreamData bytes]];
			if (StringHasText(readStreamString))
				receivedDictionary				=	[NSDictionary dictionaryWithJSONString:readStreamString];
		}		
		
		if (receivedDictionary != nil){
			EXOLog(@"Received %@ dictionary of contents:%@",type,[receivedDictionary description]);
		}
	}
}


@end
