//
//  swypInputStreamDiscerner.m
//  swyp
//
//  Created by Alexander List on 8/8/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//


static NSUInteger const memoryPageSize	=	4096;

#import "swypInputStreamDiscerner.h"
#import "swypFileTypeString.h"

@implementation swypInputStreamDiscerner
@synthesize discernmentStream = _discernmentStream, delegate = _delegate;
#pragma mark -
#pragma mark public

#pragma mark -
#pragma mark NSObject
-(id)	initWithInputStream:(NSInputStream*)discernmentStream discernerDelegate:(id<swypInputStreamDiscernerDelegate>)delegate{
	if (self = [super init]){
		_bufferedData = [[NSMutableData alloc] init];
		[self _setupInputStreamForRead:discernmentStream];
		[self setDelegate:delegate];
	}
	
	return self;
}

- (id)	init
{
    return nil;
}

-(void)	dealloc{
	[self _teardownInputStream];
	SRELS(_discernmentStream);
	[super dealloc];
}



#pragma mark -
#pragma mark private

#pragma mark swypDiscernedInputStreamDataSource
-(void)		discernedStreamEndedAtStreamByteIndex:(NSUInteger)endByteIndex discernedInputStream:(swypDiscernedInputStream*)inputStream{
	
	if (endByteIndex < _bufferedDatasZeroIndexByteLocationInYieldedStream)  {
		[NSException raise:@"swypDiscernedInputStreamException" format:@"endByteIndex '%i' is less than lowest index cached by bufferedData '%i'",endByteIndex,_bufferedDatasZeroIndexByteLocationInYieldedStream];
	}
	 
	
	NSUInteger endOfStreamIndexInBuffer	=	endByteIndex - _bufferedDatasZeroIndexByteLocationInYieldedStream;
	
	if (endOfStreamIndexInBuffer < [_bufferedData length]){ //if the end of the stream is inside the buffer
		[_bufferedData replaceBytesInRange:NSMakeRange(0, endOfStreamIndexInBuffer + 1) withBytes:NULL length:0];//move the entire buffer back to the beginning of the next stream; index is zero-delimited whilst range length is 1, so add one
		[self _cleanupForNextDiscernmentCycle];
		
	}else{
		EXOLog(@"Endbyte index %i is in the future somewhere....",endByteIndex);
	}
	
}

-(NSData*)	pullDataWithLength:(NSUInteger)maxLength	discernedInputStream:(swypDiscernedInputStream*)inputStream{
	NSUInteger maxReadLength	=	MIN(maxLength, memoryPageSize);
	NSUInteger	readLength		=	MIN(maxReadLength, [_bufferedData length]-_bufferedDataNextReadIndex);
	NSRange	readRange			=	NSMakeRange(_bufferedDataNextReadIndex, readLength);
	NSData*	returnData			=	[_bufferedData subdataWithRange:readRange];
	
	_bufferedDataNextReadIndex += readLength;
	
	//the bellow section gets rid of old data in the moving frame, but it won't get rid of data from the recent cycle
	if (_bufferedDataNextReadIndex > memoryPageSize){
		NSUInteger usedDataOverReserve	=	_bufferedDataNextReadIndex - memoryPageSize;
		[_bufferedData replaceBytesInRange:NSMakeRange(0, usedDataOverReserve) withBytes:NULL length:0];
		_bufferedDataNextReadIndex		-= usedDataOverReserve;
		
		//the location on the yielded stream at the zero index of bufferedData will only change when we expire some of the used buffered data
		_bufferedDatasZeroIndexByteLocationInYieldedStream	+= usedDataOverReserve;
	}
		
	return returnData;
}

#pragma mark swypInputStreamDiscerner
-(void) _cleanupForNextDiscernmentCycle{
	_bufferedDatasZeroIndexByteLocationInYieldedStream	= 0;
	_bufferedDataNextReadIndex							= 0;
	[_lastYieldedStream setDataSource:nil];
	SRELS(_lastYieldedStream);
}

-(void) _setupInputStreamForRead:(NSInputStream*)readStream{
	if (_discernmentStream != nil){
		[self _teardownInputStream];
	}
	
	_discernmentStream = [readStream retain];
	[_discernmentStream setDelegate:self];
	
	if ([_discernmentStream streamStatus] == NSStreamStatusOpen){
		EXOLog(@"Discernment stream already open");
	}else{
		[_discernmentStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		[_discernmentStream open];	
	}
}
-(void) _teardownInputStream{
	[_discernmentStream close];
	[_discernmentStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	SRELS(_discernmentStream);
}

-(void) _handleInputDataRead{
	//the goal is to not slow down the consumption of on-wire data too much
	
	if ([_bufferedData length] > memoryPageSize * 10){ //40k seems to be a good arbitrary max
		return;
	}

	static NSUInteger readLength	=	1024;
	
	uint8_t readBuffer[readLength];
	NSUInteger readByteCount = 0;
	readByteCount	= [_discernmentStream read:readBuffer maxLength:readLength];
	
	if(!readByteCount){ 
		return;
	}
	
	[_bufferedData appendBytes:readBuffer length:readByteCount];
	
	if (_lastYieldedStream == nil){
		[self _handleHeaderPacketFromCurrentBufferLocation:_bufferedDataNextReadIndex];
	}
}
-(void)	_handleHeaderPacketFromCurrentBufferLocation:(NSUInteger)	location{
	NSRange		relevantSearchSpace		=	NSMakeRange(location, [_bufferedData length] - location);
	NSData*		relevantData			=	[_bufferedData subdataWithRange:relevantSearchSpace];
	NSString*	headerCandidateString	=	[NSString stringWithUTF8String:[relevantData bytes]];

	NSRange		firstSemicolonRange		=	[headerCandidateString rangeOfString:@";" options:0];	
	if (firstSemicolonRange.location == NSNotFound)
		return;
	
	NSString*	packetLengthString		=	[headerCandidateString substringToIndex:firstSemicolonRange.location];
	NSUInteger	packetLength			=	[packetLengthString intValue];
	
	NSString*	remainingHeaderString	=	[headerCandidateString substringFromIndex:firstSemicolonRange.location + firstSemicolonRange.length];
	
	NSRange		secondSemicolonRange	=	[remainingHeaderString rangeOfString:@";" options:0];	
	if (secondSemicolonRange.location == NSNotFound)
		return;
	
	NSString * 	headerLengthString		=	[remainingHeaderString substringToIndex:secondSemicolonRange.location];
	NSUInteger	headerLength			=	[headerLengthString intValue];
	
	if (headerLength > ([remainingHeaderString length] - (secondSemicolonRange.location + secondSemicolonRange.length)))
		return;
	
	NSString *	packetHeaderString		=	[remainingHeaderString substringWithRange:NSMakeRange(secondSemicolonRange.location + secondSemicolonRange.length, headerLength)];	
	
	NSDictionary * headerDictionary		=	[NSDictionary dictionaryWithJSONString:packetHeaderString];
	
	NSUInteger	prePayloadLength		=	 headerLength + (firstSemicolonRange.location + firstSemicolonRange.length) + (secondSemicolonRange.location + secondSemicolonRange.length);

	
	//reset data buffer indexes
	[_bufferedData replaceBytesInRange:NSMakeRange(0, location + prePayloadLength) withBytes:NULL length:0];
	_bufferedDataNextReadIndex = 0;
	
	NSUInteger payloadLength	=	0;
	if (packetLength > 0){
		payloadLength	=	(packetLength + [packetLengthString length] +1)  - prePayloadLength; //payload length begins after first semicolon
	}
	EXOLog(@"Extracted header with payloadLength %i, packet length %i, headerLength %i, value: %@",payloadLength,packetLength,headerLength, packetHeaderString);
	[self _generateDiscernedStreamWithHeaderDictionary:headerDictionary payloadLength:payloadLength];
}

-(void)	_generateDiscernedStreamWithHeaderDictionary:(NSDictionary*)	headerDictionary payloadLength: (NSUInteger)length{

	NSString * typeString	=	[headerDictionary valueForKey:@"type"];
	NSString * tagString	=	[headerDictionary valueForKey:@"tag"];
	NSNumber * lengthNumber	=	[headerDictionary valueForKey:@"length"];
	
	if (lengthNumber != nil && [lengthNumber intValue] != length){
		EXOLog(@"Payload mismatch with header %i and packet %i",[lengthNumber intValue],length);
	}
	
	if (StringHasText(typeString) && StringHasText(tagString)){
		EXOLog(@"Tag :%@ ; Type :%@ ;",tagString,typeString);
		SRELS( _lastYieldedStream);
		_lastYieldedStream =	[[swypDiscernedInputStream alloc] initWithStreamDataSource:self type:typeString tag:tagString length:[lengthNumber intValue]];
		[[self delegate] discernedStream:_lastYieldedStream withDiscerner:self];
	}else{
		EXOLog(@"Tag or type are missing");
	}
}


#pragma mark NSStreamDelegate
#pragma mark -
- (void)stream:(NSInputStream *)stream handleEvent:(NSStreamEvent)eventCode{
	if (eventCode == NSStreamEventOpenCompleted){
		EXOLog(@"Opened stream for swypInputStreamDiscerner");
	}else if (eventCode == NSStreamEventHasBytesAvailable){
		[self _handleInputDataRead];
		
	}else if (eventCode == NSStreamEventEndEncountered){
		EXOLog(@"Received stream end event in swypInputStreamDiscerner")
	}else if (eventCode == NSStreamEventErrorOccurred){
		EXOLog(@"Stream error occured in swypInputStreamDiscerner");
	}
}
@end
