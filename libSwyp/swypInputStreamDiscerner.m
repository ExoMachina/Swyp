//
//  swypInputStreamDiscerner.m
//  swyp
//
//  Created by Alexander List on 8/8/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import "swypInputStreamDiscerner.h"
#import "swypFileTypeString.h"

static unsigned int const memoryPageSize	=	4096;

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
	[self _cleanupForNextDiscernmentCycle];
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
		EXOLog(@"Indefinite: Endbyte index %i is in the future somewhere....",endByteIndex);
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
	
	
	//here's a test to see whether we can startup the transfer again once our buffers are free
	if ([_bufferedData length] < memoryPageSize * 10 && [_discernmentStream hasBytesAvailable]){ //40k seems to be a good arbitrary max
		[self _handleInputDataRead];
	}
	
	
	return returnData;
}

#pragma mark swypInputStreamDiscerner
-(void) _cleanupForNextDiscernmentCycle{
	[_delegate concludedDiscernedStream:_lastYieldedStream withDiscerner:self];
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
	
	//the swyp discerned stream is slow on the read
	if ([_bufferedData length] > memoryPageSize * 10){ //40k seems to be a good arbitrary max
		[_lastYieldedStream shouldPullData];
		return;
	}

	static NSUInteger readLength	=	1024;
	
	uint8_t readBuffer[readLength];
	NSInteger readByteCount = 0;
	readByteCount	= [_discernmentStream read:readBuffer maxLength:readLength];
	
	if(readByteCount <= 0){ 
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
	
	//let's do this to find the second semi-colon, with which we can use to parse just what we need into string
	NSRange		semicolonRange	=	NSMakeRange(NSNotFound, 0);

	char *		relevantBytes			=	(char *)[relevantData bytes];
	for (NSUInteger i = 0; i < [relevantData length]; i ++){
		if (relevantBytes[i] == ';'){
			semicolonRange		=	NSMakeRange(i, 1);
			break;
		}
	}
	
	if (semicolonRange.location == NSNotFound){
		return;
	}
	
	
	NSString*	headerLengthStr		=	[[NSString alloc]	initWithBytes:relevantBytes length:semicolonRange.location + semicolonRange.length encoding:NSUTF8StringEncoding];	
	if (StringHasText(headerLengthStr) == NO){
		return;
	}
		
	NSString * 	headerLengthStringWOSemi=	[headerLengthStr substringWithRange:NSMakeRange(0, semicolonRange.location)]; //to before second semicolon
	NSUInteger	headerLength			=	[headerLengthStringWOSemi intValue];
	
	
	if (headerLength > ([relevantData length] - (semicolonRange.location + semicolonRange.length))){
		//if there's a bigger header than we have currently cached data; we can't do anything yet
		return;
	}//otherwise....
	//now we know that we have a header, and that it's inside our currently avaiable, "relevant," data 
	
	NSData *	headerData				=	[relevantData subdataWithRange:NSMakeRange(semicolonRange.location + semicolonRange.length, headerLength)];
	NSString*	packetHeaderString	=	[[[NSString alloc]  initWithBytes:(char *)[headerData bytes] length:[headerData length] encoding: NSUTF8StringEncoding] autorelease]; //this is MUCH safer against non-null-termed strings
		
		
	NSDictionary * headerDictionary		=	[NSDictionary dictionaryWithJSONString:packetHeaderString];
	if (headerDictionary == nil){
		return;
	}

	NSUInteger	packetPayloadLength		=	0;
	NSNumber *	packetLengthNumber		=	[headerDictionary valueForKey:@"length"];
	if ([packetLengthNumber isKindOfClass:[NSNumber class]]) {
		packetPayloadLength	=	[packetLengthNumber unsignedIntValue];
	}else{
		return;
	}
	
	NSUInteger	prePayloadLength		=	 semicolonRange.location + semicolonRange.length + [headerData length];
	
	//reset data buffer indexes
	[_bufferedData replaceBytesInRange:NSMakeRange(0, location + prePayloadLength) withBytes:NULL length:0];
	_bufferedDataNextReadIndex = 0;
	
	[self _generateDiscernedStreamWithHeaderDictionary:headerDictionary payloadLength:packetPayloadLength];
}

-(void)	_generateDiscernedStreamWithHeaderDictionary:(NSDictionary*)	headerDictionary payloadLength: (NSUInteger)length{

	NSString * typeString	=	[headerDictionary valueForKey:@"type"];
	NSString * tagString	=	[headerDictionary valueForKey:@"tag"];
	NSNumber * lengthNumber	=	[headerDictionary valueForKey:@"length"];
	
	if (lengthNumber != nil && [lengthNumber intValue] != length){
		EXOLog(@"Payload mismatch with header %i and packet %i",[lengthNumber intValue],length);
		return;
	}
	
	if (StringHasText(typeString) && StringHasText(tagString)){
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
	}else if (eventCode == NSStreamEventHasBytesAvailable){
		[self _handleInputDataRead];
		
	}else if (eventCode == NSStreamEventEndEncountered){
		EXOLog(@"Received stream end event in swypInputStreamDiscerner");
		[_delegate inputStreamDiscernerFinishedWithError:nil withDiscerner:self];
	}else if (eventCode == NSStreamEventErrorOccurred){
		EXOLog(@"Stream error occured in swypInputStreamDiscerner");
	}
}
@end
