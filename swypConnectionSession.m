//
//  swypConnectionSession.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import "swypConnectionSession.h"


@implementation swypConnectionSession
@synthesize representedCandidate = _representedCandidate, connectionStatus = _connectionStatus, sessionHueColor	= _sessionHueColor;



-(id)initWithSwypCandidate:(swypCandidate *)candidate inputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream{
	if (self = [super init]){

		if ([inputStream streamStatus] < NSStreamStatusOpen){
			[inputStream	setDelegate:self];
			[inputStream	scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
			[inputStream	open];
		}
		if ([outputStream streamStatus] < NSStreamStatusOpen){
			[outputStream	setDelegate:self];
			[outputStream	scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
			[outputStream	open];
		}
		
		_socketInputStream	= [inputStream retain];
		_socketOutputStream	= [outputStream retain];
		
		[self _changeStatus:swypConnectionSessionStatusPreparing];
		
	}
	
	return self;
}

-(void)	dealloc{
	[_socketInputStream		setDelegate:nil];
	[_socketOutputStream	setDelegate:nil];
	SRELS(_socketInputStream);
	SRELS(_socketOutputStream);
	
	[super dealloc];
}


-(void)	_changeStatus:	(swypConnectionSessionStatus)status{
	if (_connectionStatus != status){
		_connectionStatus = status;
		for (id<swypConnectionSessionInfoDelegate> delegate in _connectionSessionInfoDelegates){
			if ([delegate respondsToSelector:@selector(sessionStatusChanged:inSession:)])
				[delegate sessionStatusChanged:status inSession:self];
		}
	}
}

#pragma mark -
#pragma mark NSStreamDelegate
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode{
	if (eventCode == NSStreamEventOpenCompleted){
		if ([_socketInputStream streamStatus] >= NSStreamStatusOpen && [_socketOutputStream streamStatus] >= NSStreamStatusOpen){
			[self _changeStatus:swypConnectionSessionStatusReady];
		}
	}else if (eventCode == NSStreamEventErrorOccurred){
		[self _changeStatus:swypConnectionSessionStatusNotReady];

		NSError *error = [NSError errorWithDomain:swypConnectionSessionErrorDomain code:swypConnectionSessionSocketError userInfo:nil];
		for (id<swypConnectionSessionInfoDelegate> delegate in _connectionSessionInfoDelegates){
			if ([delegate respondsToSelector:@selector(sessionDied:withError:)])
				[delegate sessionDied:self withError:error];
		}
		
	}
}

@end
