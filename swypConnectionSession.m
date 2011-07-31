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

#pragma mark -
#pragma mark public
#pragma mark send data

-(void)	beginSendingFileStreamWithTag:(NSString*)tag  type:(swypFileTypeString*)fileType dataStreamForSend:(NSInputStream*)payloadStream length:(NSUInteger)streamLength{
	if (StringHasText(tag) == NO || StringHasText(fileType) == NO || payloadStream == nil){
		return;
	}
	
	NSMutableDictionary *	streamHeaderDictionary	=	[NSMutableDictionary dictionary];
	[streamHeaderDictionary setValue:fileType forKey:@"type"];
	[streamHeaderDictionary setValue:tag forKey:@"tag"];
	[streamHeaderDictionary setValue:[NSNumber numberWithUnsignedInt:streamLength] forKey:@"length"];
	
	NSString *	jsonHeaderString	=	[streamHeaderDictionary jsonStringValue];
	NSData	*	jsonHeaderData		=	[jsonHeaderString dataUsingEncoding:NSUTF8StringEncoding];
	NSInputStream * headerStream	=	[NSInputStream inputStreamWithData:jsonHeaderData];
	EXOLog(@"Sending header json: %@", jsonHeaderString);
	
	swypConcatenatedInputStream * concatenatedSendPacket	=	[[swypConcatenatedInputStream alloc] initWithInputStreamArray:[NSArray arrayWithObjects:headerStream,payloadStream]];
	[concatenatedSendPacket setHoldCompletedStreams:TRUE];
	[_sendDataQueueStream addInputStreamToQueue:concatenatedSendPacket];
	SRELS(concatenatedSendPacket);
}

-(void)	beginSendingDataWithTag:(NSString*)tag type:(swypFileTypeString*)type dataForSend:(NSData*)sendData{
	NSUInteger dataLength	=	[sendData length];
	if (dataLength == 0)	return;
	
	NSInputStream * payloadStream	=	[NSInputStream inputStreamWithData:sendData];
	
	[self beginSendingFileStreamWithTag:tag type:type dataStreamForSend:payloadStream length:dataLength];
}


#pragma mark -
#pragma mark NSObject

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


#pragma mark -
#pragma mark private

-(void) _setupStreamPathways{
	//data send queue holds all outgoing streams, transform pathway does encryption (after crypto negotiation) on everything, and connector slaps it to the output
	
	_sendDataQueueStream = [[swypConcatenatedInputStream alloc] init];
	[_sendDataQueueStream setDelegate:self];
	[_sendDataQueueStream setCloseStreamAtQueueEnd:FALSE];
	
	_socketOutputTransformInputStream	= [[swypTransformPathwayInputStream alloc] initWithDataInputStream:_sendDataQueueStream transformStreamArray:nil];
	
	_outputStreamConnector				= [[swypInputToOutputStreamConnector alloc] initWithOutputStream:_socketOutputStream readStream:_socketOutputTransformInputStream];
	
	//Alex: yeah, we're at the HNL
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

#pragma mark swypConcatenatedInputStreamDelegate
-(void) didFinishAllQueuedStreamsWithConcatenatedInputStream:(swypConcatenatedInputStream*)concatenatedStream{
	
}
-(void) didCompleteInputStream:(NSInputStream*)stream withConcatenatedInputStream:(swypConcatenatedInputStream*)concatenatedStream{
	NSInputStream * notifyStream = nil;
	if ([stream isKindOfClass:[swypConcatenatedInputStream class]]){
		NSArray * completedStreams = [(swypConcatenatedInputStream *)stream completedStreams];
		if ([completedStreams count] == 2){
			//certainly a user packet
			notifyStream	=	[completedStreams objectAtIndex:1];
		}
	}
	
	if (notifyStream == nil)
		notifyStream = stream;
	
	for (id<swypConnectionSessionDataDelegate> delegate in _dataDelegates){
		if ([delegate respondsToSelector:@selector(completedSendingStream:connectionSession:)])
			[delegate completedSendingStream:notifyStream connectionSession:self];
	}
	
}
-(void) didBeginInputStream:(NSInputStream*)stream withConcatenatedInputStream:(swypConcatenatedInputStream*)concatenatedStream{
	
}
-(bool) shouldContinueAfterFailingStream:(NSInputStream*)stream withError:(NSError*)error withConcatenatedInputStream:(swypConcatenatedInputStream*)concatenatedStream{
	/*
		Returning NO will close the stream and invalidate the session
	 
		if both are still queued in passed input stream, then try to recover, otherwise, die.
	*/
	
	
	NSInputStream * notifyStream = nil;
	if ([stream isKindOfClass:[swypConcatenatedInputStream class]]){
		NSArray * completedStreams = [(swypConcatenatedInputStream *)stream completedStreams];
		if ([completedStreams count] == 2){
			//certainly a user packet
			notifyStream	=	[completedStreams objectAtIndex:1];
		}
	}
	
	if (notifyStream == nil)
		notifyStream = stream;
	
	for (id<swypConnectionSessionDataDelegate> delegate in _dataDelegates){
		if ([delegate respondsToSelector:@selector(failedSendingStream:error:connectionSession:)])
			[delegate failedSendingStream:notifyStream error:nil connectionSession:self];
	}
	
	
	[self invalidate];
	return NO;
}
@end
