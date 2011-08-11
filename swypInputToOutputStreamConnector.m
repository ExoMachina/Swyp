//
//  swypInputToOutputStreamConnector.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import "swypInputToOutputStreamConnector.h"


@implementation swypInputToOutputStreamConnector
@synthesize inputStream = _inputStream, outputStream = _outputStream;
@synthesize delegate = _delegate;

#pragma mark -
#pragma mark public 

-(void) setInputStream:(NSInputStream *)stream{
	if (_inputStream != nil){
		EXOLog(@"Teared-down prexisting inputStream");
		if ([_inputStream streamStatus] != NSStreamStatusOpen){
			EXOLog(@"Apparently it wasn't open, though..");
		}
		[self _teardownInputStream:_inputStream];
	}
	
	[self _setupInputStreamForRead:stream];
}

#pragma mark NSObject
-(id)	initWithOutputStream:(NSOutputStream*)outputStream readStream:(NSInputStream*)inStream{
	if (self = [super init]){
		_bufferedData = [[NSMutableData alloc] init];
		
		[self _setupOutputStreamForWrite:outputStream];
		[self setInputStream:inStream];
	}
	return self;
}

-(id) init{
	
	return nil;
}

-(void) dealloc{
	[self _teardownInputStream:_inputStream];
	[self _teardownOutputStream];
	SRELS(_bufferedData);

	[super dealloc];
}

#pragma mark -
#pragma mark private

-(void) _setupOutputStreamForWrite:(NSOutputStream*)output{
	_outputStream = [output retain];
	[_outputStream setDelegate:self];
	[_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_outputStream open];
}

-(void) _teardownOutputStream{
	[_outputStream setDelegate:nil];
	[_outputStream close];
	[_outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	SRELS(_outputStream);
}

-(void) _setupInputStreamForRead:(NSInputStream*)readStream{
	_inputStream = [readStream retain];
	[_inputStream setDelegate:self];
	[_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_inputStream open];
	
}
-(void) _teardownInputStream:(NSInputStream*)stream{
	[stream close];
	[stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	if (stream ==_inputStream)
		SRELS(_inputStream);
}


-(void)	_attemptDataHandoff{
	
	if ([_bufferedData length] < 1024 && [_inputStream hasBytesAvailable]){
		uint8_t readBuffer[1024];
		unsigned int readLength = 0;
		readLength =	[_inputStream read:readBuffer maxLength:1024];
		if(readLength > 0){ 
			[_bufferedData appendBytes:readBuffer length:readLength];
		}
		
	}
	
	NSUInteger bufferedDataLength	=	[_bufferedData length];
	if (bufferedDataLength > 0 && [_outputStream hasSpaceAvailable]){
		
		NSUInteger maxWriteLength = MIN(bufferedDataLength, 1024);
		
		uint8_t writeBuffer[maxWriteLength];
		[_bufferedData getBytes:writeBuffer range:NSMakeRange(0, maxWriteLength)];
		
		unsigned int writeLength = 0;
		writeLength = [_outputStream write:writeBuffer maxLength:maxWriteLength];
		
		[_bufferedData replaceBytesInRange:NSMakeRange(0, writeLength) withBytes:NULL length:0];
	}
	
}


#pragma mark NSStreamDelegate
- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode{
	
	if (stream == _inputStream){
		if (eventCode == NSStreamEventOpenCompleted){
			
		}else if (eventCode == NSStreamEventHasBytesAvailable){
			[self _attemptDataHandoff];
		}else if (eventCode == NSStreamEventEndEncountered){
			[_delegate completedInputStream:_inputStream forOutputStream:_outputStream withInputToOutputConnector:self];
		}else if (eventCode == NSStreamEventErrorOccurred){
			[_delegate encounteredErrorInInputStream:_inputStream withInputToOutputConnector:self];
		}
	}else if (stream == _outputStream){
		if (eventCode == NSStreamEventOpenCompleted){

		}else if (eventCode == NSStreamEventHasSpaceAvailable){
			[self _attemptDataHandoff];
		}else if (eventCode == NSStreamEventEndEncountered){
			EXOLog(@"End encountered for output stream in inputOutputConnector?");
		}else if (eventCode == NSStreamEventErrorOccurred){
			[_delegate encounteredErrorInOutputStream:_outputStream withInputToOutputConnector:self];
		}
	}
	
}


@end
