//
//  swypConnectionSession.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import "swypConnectionSession.h"


static NSString * const swypConnectionSessionErrorDomain = @"swypConnectionSessionErrorDomain";

@implementation swypConnectionSession
@synthesize representedCandidate = _representedCandidate, connectionStatus = _connectionStatus, sessionHueColor	= _sessionHueColor;

#pragma mark -
#pragma mark public
#pragma mark send data

-(swypConcatenatedInputStream*)	beginSendingFileStreamWithTag:(NSString*)tag  type:(swypFileTypeString*)fileType dataStreamForSend:(NSInputStream*)payloadStream length:(NSUInteger)streamLength{
	if (StringHasText(tag) == NO || StringHasText(fileType) == NO || payloadStream == nil){
		return nil;
	}
	
	NSMutableDictionary *	streamHeaderDictionary	=	[NSMutableDictionary dictionary];
	[streamHeaderDictionary setValue:fileType forKey:@"type"];
	[streamHeaderDictionary setValue:tag forKey:@"tag"];
	[streamHeaderDictionary setValue:[NSNumber numberWithUnsignedInt:streamLength] forKey:@"length"];
	
	NSString *	jsonHeaderString	=	[streamHeaderDictionary jsonStringValue];
	NSData	*	jsonHeaderData		=	[jsonHeaderString dataUsingEncoding:NSUTF8StringEncoding];
    NSUInteger  jsonHeaderLength    =   [jsonHeaderData length];
	
	NSString *  headerLengthString	=   [NSString stringWithFormat:@"%i;",jsonHeaderLength];
	NSData *	headerLengthData	=	[headerLengthString dataUsingEncoding:NSUTF8StringEncoding];

	NSInteger	overallPacketLength	=	jsonHeaderLength + [headerLengthData length];

	// If streamLength is zero, this will be handled specially by recipient
	if (streamLength > 0 ){
		overallPacketLength		+=	streamLength;
	}else{
		overallPacketLength		= 0;
	}
	
	NSString *	packetLengthString			=	[NSString stringWithFormat:@"%i;",overallPacketLength];
	NSData *	overallPacketLengthData		=	[packetLengthString dataUsingEncoding:NSUTF8StringEncoding];

	NSMutableData *	concatenatedHeaderData	=	[NSMutableData dataWithData:overallPacketLengthData];
	[concatenatedHeaderData appendData:headerLengthData];
	[concatenatedHeaderData	appendData:jsonHeaderData];

	
	NSInputStream * headerStream	=	[NSInputStream inputStreamWithData:concatenatedHeaderData];
	EXOLog(@"Sending header json: %@", jsonHeaderString);
	
	swypConcatenatedInputStream * concatenatedSendPacket	=	[[swypConcatenatedInputStream alloc] initWithInputStreamArray:[NSArray arrayWithObjects:headerStream,payloadStream,nil]];
	[concatenatedSendPacket setHoldCompletedStreams:TRUE];
	[_sendDataQueueStream addInputStreamToQueue:concatenatedSendPacket];
	return [concatenatedSendPacket autorelease];
}

-(swypConcatenatedInputStream*)	beginSendingDataWithTag:(NSString*)tag type:(swypFileTypeString*)type dataForSend:(NSData*)sendData{
	NSUInteger dataLength	=	[sendData length];
	if (dataLength == 0)	return nil;
	
	NSInputStream * payloadStream	=	[NSInputStream inputStreamWithData:sendData];
	
	return [self beginSendingFileStreamWithTag:tag type:type dataStreamForSend:payloadStream length:dataLength];
}

-(void)	invalidate{
	// 1) tell delegates everything will die 2) change status to closing 3) add goodbye packet to queue
	// 4) reason only is only for debugging purposes
	
	for (NSValue * delegateValue in _connectionSessionInfoDelegates){
		id<swypConnectionSessionInfoDelegate> delegate	= [delegateValue nonretainedObjectValue];
		if ([delegate respondsToSelector:@selector(sessionWillDie:)])
			[delegate sessionWillDie:self];
	}
	[self _changeStatus:swypConnectionSessionStatusWillDie];
	
	[_sendDataQueueStream removeAllQueuedStreamsAfterCurrent];
	
	NSData	* sendDictionaryData = [[[NSDictionary dictionaryWithObject:@"hangup" forKey:@"reason"] jsonStringValue] dataUsingEncoding:NSUTF8StringEncoding];
	[self beginSendingDataWithTag:@"goodbye" type:[swypFileTypeString swypControlPacketFileType] dataForSend:sendDictionaryData];
}

#pragma mark delegatation
-(void)	addDataDelegate:(id<swypConnectionSessionDataDelegate>)delegate{
	[_dataDelegates addObject:[NSValue valueWithNonretainedObject:delegate]];
}
-(void)	removeDataDelegate:(id<swypConnectionSessionDataDelegate>)delegate{
	[_dataDelegates removeObject:[NSValue valueWithNonretainedObject:delegate]];
}

-(void)	addConnectionSessionInfoDelegate:(id<swypConnectionSessionInfoDelegate>)delegate{
	[_connectionSessionInfoDelegates addObject:[NSValue valueWithNonretainedObject:delegate]];
}
-(void)	removeConnectionSessionInfoDelegate:(id<swypConnectionSessionInfoDelegate>)delegate{
    [_connectionSessionInfoDelegates removeObject:[NSValue valueWithNonretainedObject:delegate]];
}


#pragma mark -
#pragma mark NSObject

-(id)initWithSwypCandidate:(swypCandidate *)candidate inputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream{
	if (self = [super init]){
		_representedCandidate	=	[candidate retain];
		
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
		
		_dataDelegates						=	[[NSMutableSet alloc] init];
		_connectionSessionInfoDelegates		=	[[NSMutableSet alloc] init];
		[self _changeStatus:swypConnectionSessionStatusPreparing];
		
	}
	
	return self;
}

-(void)	dealloc{
	[self _teardownConnection];
	SRELS(_dataDelegates);					
	SRELS(_connectionSessionInfoDelegates);	
	
	SRELS(_outputStreamConnector);
	SRELS(_socketOutputTransformInputStream);
	SRELS(_sendDataQueueStream);
	
	SRELS(_representedCandidate);
	
	[super dealloc];
}


#pragma mark -
#pragma mark private
-(void) _teardownConnection{
	[_socketInputStream		setDelegate:nil];
	[_socketOutputStream	setDelegate:nil];
	SRELS(_socketInputStream);
	SRELS(_socketOutputStream);	
}

-(void) _setupStreamPathways{
	//data send queue holds all outgoing streams, transform pathway does encryption (after crypto negotiation) on everything, and connector slaps it to the output
	
	_sendDataQueueStream = [[swypConcatenatedInputStream alloc] init];
	[_sendDataQueueStream setInfoDelegate:self];
	[_sendDataQueueStream setCloseStreamAtQueueEnd:FALSE];
	
	_socketOutputTransformInputStream	= [[swypTransformPathwayInputStream alloc] initWithDataInputStream:_sendDataQueueStream transformStreamArray:nil];
	
	_outputStreamConnector				= [[swypInputToOutputStreamConnector alloc] initWithOutputStream:_socketOutputStream readStream:_socketOutputTransformInputStream];
	[_outputStreamConnector setDelegate:self];
	
	//Alex: yeah, we're at the HNL
}

-(void)	_changeStatus:	(swypConnectionSessionStatus)status{
	if (_connectionStatus != status){
		_connectionStatus = status;
		for (NSValue * delegateValue in _connectionSessionInfoDelegates){
			id<swypConnectionSessionInfoDelegate> delegate	= [delegateValue nonretainedObjectValue];
			if ([delegate respondsToSelector:@selector(sessionStatusChanged:inSession:)])
				[delegate sessionStatusChanged:status inSession:self];
		}
	}
}

-(void)	_handleSocketInputData{
	if (_socketInputStream != nil){
		uint8_t readBuffer[1024];
		unsigned int readLength = 0;
		readLength = [_socketInputStream read:readBuffer maxLength:1024];
		
		if (readLength > 0){
			EXOLog(@"Read %i# bytes of data data from socket input stream: %s", readLength, readBuffer);
		}
	}
}

#pragma mark -
#pragma mark NSStreamDelegate
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode{
	if (eventCode == NSStreamEventOpenCompleted){
		if ([_socketInputStream streamStatus] >= NSStreamStatusOpen && [_socketOutputStream streamStatus] >= NSStreamStatusOpen){
			EXOLog(@"Stream open occured in connection session w/ appear date: %@", [[_representedCandidate appearanceDate] description]);
			[self _setupStreamPathways];
			[self _changeStatus:swypConnectionSessionStatusReady];
		}
	}else if (eventCode == NSStreamEventErrorOccurred){
		EXOLog(@"Stream error occured in connection session w/ appear date: %@", [[_representedCandidate appearanceDate] description]);
		[self _teardownConnection];
		[self _changeStatus:swypConnectionSessionStatusClosed];

		NSError *error = [NSError errorWithDomain:swypConnectionSessionErrorDomain code:swypConnectionSessionSocketError userInfo:nil];
		for (NSValue * delegateValue in _connectionSessionInfoDelegates){
			id<swypConnectionSessionInfoDelegate> delegate	= [delegateValue nonretainedObjectValue];
			if ([delegate respondsToSelector:@selector(sessionDied:withError:)])
				[delegate sessionDied:self withError:error];
		}
		
	}else if (eventCode == NSStreamEventEndEncountered){
		EXOLog(@"Stream end encountered in connection session with represented candidate w/ appear date: %@", [[_representedCandidate appearanceDate] description]);
		[self _teardownConnection];
		[self _changeStatus:swypConnectionSessionStatusClosed];
	}else if (eventCode == NSStreamEventHasBytesAvailable){
		if (aStream == _socketInputStream){
			[self _handleSocketInputData];
		}
	}
}

#pragma mark swypConcatenatedInputStreamDelegate
-(void) didFinishAllQueuedStreamsWithConcatenatedInputStream:(swypConcatenatedInputStream*)concatenatedStream{
	if ([self connectionStatus] == swypConnectionSessionStatusWillDie){
		[self _teardownConnection];
		for (NSValue * delegateValue in _connectionSessionInfoDelegates){
			id<swypConnectionSessionInfoDelegate> delegate	= [delegateValue nonretainedObjectValue];
			if ([delegate respondsToSelector:@selector(sessionDied:withError:)])
				[delegate sessionDied:self withError:nil];
		}
		[self _changeStatus:swypConnectionSessionStatusClosed];
	}
}
-(void) didCompleteInputStream:(NSInputStream*)stream withConcatenatedInputStream:(swypConcatenatedInputStream*)concatenatedStream{	
	for (NSValue * delegateValue in _dataDelegates){
		id<swypConnectionSessionDataDelegate> delegate	= [delegateValue nonretainedObjectValue];
		if ([delegate respondsToSelector:@selector(completedSendingStream:connectionSession:)])
			[delegate completedSendingStream:stream connectionSession:self];
	}
	
}
-(void) didBeginInputStream:(NSInputStream*)stream withConcatenatedInputStream:(swypConcatenatedInputStream*)concatenatedStream{
	
}
-(bool) shouldContinueAfterFailingStream:(NSInputStream*)stream withError:(NSError*)error withConcatenatedInputStream:(swypConcatenatedInputStream*)concatenatedStream{
	/*
		Returning NO will close the stream and invalidate the session
	 
		Seeing as though the stream sender can become delegates of lengths and errors, just return NO and kill the session
	*/	
	for (NSValue * delegateValue in _dataDelegates){
		id<swypConnectionSessionDataDelegate> delegate	= [delegateValue nonretainedObjectValue];
		if ([delegate respondsToSelector:@selector(failedSendingStream:error:connectionSession:)])
			[delegate failedSendingStream:stream error:(error != nil)?[NSError errorWithDomain:swypConnectionSessionErrorDomain code:swypConnectionSessionStreamError userInfo:[NSDictionary dictionaryWithObject:error forKey:@"originalError"]]:nil connectionSession:self];
	}
	
	
	[self invalidate];
	return NO;
}

#pragma mark swypInputToOutputStreamConnectorDelegate
-(void) encounteredErrorInInputStream: (NSInputStream*)stream withInputToOutputConnector:(swypInputToOutputStreamConnector*)connector{
	EXOLog(@"encounteredErrorInInputStream withInputToOutputConnector");
}
-(void) encounteredErrorInOutputStream: (NSOutputStream*)stream withInputToOutputConnector:(swypInputToOutputStreamConnector*)connector{
	EXOLog(@"encounteredErrorInOutputStream withInputToOutputConnector");
}

-(void) completedInputStream: (NSInputStream*)stream withInputToOutputConnector:(swypInputToOutputStreamConnector*)connector{
//@"Shouldn't always need to be a delegate of the connector"
	
	EXOLog(@"Completed inputStream withInputToOutputConnector");
}

@end
