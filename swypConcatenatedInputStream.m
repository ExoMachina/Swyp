//
//  swypConcatenatedInputStream.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import "swypConcatenatedInputStream.h"


@implementation swypConcatenatedInputStream
@synthesize delegate = _delegate, infoDelegate = _infoDelegate, closeStreamAtQueueEnd = _closeStreamAtQueueEnd, holdCompletedStreams = _holdCompletedStreams, completedStreams = _completedStreams, queuedStreams = _queuedStreams;

#pragma mark -
#pragma mark public
-(void)	addInputStreamsToQueue:		(NSArray*)inputStreams{
	for (NSInputStream * inputStream in inputStreams){
		[self addInputStreamToQueue:inputStream];
	}
}

-(void)	addInputStreamToQueue:		(NSInputStream*)input{
	[_queuedStreams addObject:input];
	if (_currentInputStream == nil && [self streamStatus]== NSStreamStatusOpen)
		[self _queueNextInputStream]; 
}


-(void)	removeAllQueuedStreamsAfterCurrent{
	
	if ([_queuedStreams count] <= 1)
		return;
	
	if (_currentInputStream == nil){
		[_queuedStreams removeAllObjects];
		return;
	}
	
	NSInteger startIndex = [_queuedStreams indexOfObject:_currentInputStream] +1;
	if (startIndex >= [_queuedStreams count])
		return;
	
	[_queuedStreams removeObjectsInRange:NSMakeRange(startIndex, [_queuedStreams count]-startIndex)];
}

-(BOOL)	finishedRelayingAllQueuedStreamData{
	if ([_queuedStreams count] == 0 && [_dataOutBuffer length] == 0){
		return TRUE;
	}
	return NO;
}

#pragma mark NSInputStream
- (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)len{
	return NO; //doesn't matter, honestly..
}
-(NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)maxLength{
	NSUInteger readableBytes = [_dataOutBuffer length] - _nextDataOutputIndex;
	if (readableBytes == 0)
		return 0;
	
	NSUInteger bytesToRead	= MIN (maxLength -1, readableBytes); //null termination is necessary on last byte
	NSRange readRange		= NSMakeRange(_nextDataOutputIndex, bytesToRead);
	
	[_dataOutBuffer getBytes:buffer range:readRange];
	buffer[readRange.location + readRange.length]	=	0x00;
	
	_nextDataOutputIndex += bytesToRead;
	[_dataOutBuffer replaceBytesInRange:readRange withBytes:NULL length:0];
	_nextDataOutputIndex -= bytesToRead; //cleared out now-useless data
	
	return bytesToRead;
}
-(BOOL)	hasBytesAvailable{
	if (_nextDataOutputIndex < [_dataOutBuffer length]){
		return TRUE;
	}else if ([self finishedRelayingAllQueuedStreamData]){
		if ([self closeStreamAtQueueEnd]){
			_streamStatus = NSStreamStatusAtEnd;
			[[self delegate] stream:self handleEvent:NSStreamEventEndEncountered];
		}
	}
	
	
	return FALSE; 
}

-(void)	open{
	_streamStatus = NSStreamStatusOpen;
	[self _queueNextInputStream];
	[[self delegate] stream:self handleEvent:NSStreamEventOpenCompleted];
}

-(void) close{
	[self removeFromRunLoop:nil forMode:nil];
	[self removeAllQueuedStreamsAfterCurrent];
	[self _teardownInputStream:_currentInputStream];
	_streamStatus = NSStreamStatusClosed;
}

-(NSStreamStatus) streamStatus{
	return _streamStatus;
}

- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
	if (_runloopTimer != nil){
		[self removeFromRunLoop:aRunLoop forMode:mode];
	}
	
	_runloopTimer = [[NSTimer timerWithTimeInterval:0.001 target:self selector:@selector(runloopTimerFired:) userInfo:nil repeats:YES] retain];
	[aRunLoop addTimer:_runloopTimer forMode:mode]; 
}

- (void)removeFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
	[_runloopTimer invalidate];
	SRELS(_runloopTimer);
}

-(void) runloopTimerFired:(id)sender{	
	if ([self hasBytesAvailable]){
		[_delegate stream:self handleEvent:NSStreamEventHasBytesAvailable];
	}
}

- (id)propertyForKey:(NSString *)key {
    return nil;
}

- (BOOL)setProperty:(id)property forKey:(NSString *)key {
    return NO;
}

- (NSError *)streamError {
    return nil;
}

#pragma mark NSObject
-(id)initWithInputStreamArray:(NSArray *)inputStreams{
	if (self = [self init]){
		[self addInputStreamsToQueue:inputStreams];
	}
	return self;
}

-(id)	init{
	if (self = [super init]){
		_dataOutBuffer	=	[[NSMutableData alloc] init];
		_streamStatus	= NSStreamStatusNotOpen;
		_queuedStreams	=	[[NSMutableArray alloc] init];
	}
	return self;
}

-(void)	dealloc{
	if ([self finishedRelayingAllQueuedStreamData]){
		if ([self closeStreamAtQueueEnd] == NO)
			[[self delegate] stream:self handleEvent:NSStreamEventEndEncountered];
	}else {
		[[self delegate] stream:self handleEvent:NSStreamEventErrorOccurred];
	}

	[self _teardownInputStream:_currentInputStream];
	
	SRELS(_queuedStreams);
	SRELS(_completedStreams);
	
	
	SRELS(_streamLengthsRemaining);
	SRELS(_streamLengths);
	
	SRELS(_dataOutBuffer);
	
	[super dealloc];
}



-(void)		setLengthToTrack:	(NSUInteger)lengthToTrack	forQueuedStream: (NSInputStream*)queuedStream{
	if (_streamLengths == nil){
		_streamLengths			= [[NSMutableDictionary alloc] init];
		_streamLengthsRemaining	= [[NSMutableDictionary alloc] init];
	}
	NSNumber *	value	=	[NSNumber numberWithInt:lengthToTrack];
	NSValue	*	key		=	[NSValue valueWithNonretainedObject:queuedStream];
	
	[_streamLengths setObject:value forKey:key];
	[_streamLengthsRemaining setObject:value forKey:key];
}

-(NSUInteger)	remainingByteCountForQueuedStream:	(NSInputStream*)queuedStream withTotalLength:(NSUInteger *)refForTotalBytes{
	NSValue	*	key						=	[NSValue valueWithNonretainedObject:queuedStream];
	NSNumber * remainingBytesForStream	=	[_streamLengthsRemaining objectForKey:key];
	
	if (remainingBytesForStream == nil){
		return 0;
	}
	
	NSInteger remainingBytes			=	[remainingBytesForStream intValue];
	
	if (refForTotalBytes != NULL){
		NSInteger totalBytes			=	[[_streamLengths objectForKey:key] intValue];
		*refForTotalBytes				=	totalBytes;
	}
	
	return remainingBytes;
}


#pragma mark -
#pragma mark private 
#pragma mark NSStreamDelegate
/*
	need to pretend we're open even before we get streams to concatenate
	A sort of parallel to CloseStreamAtEndOfQueue
*/
- (void)stream:(NSInputStream *)stream handleEvent:(NSStreamEvent)eventCode{
	if (eventCode == NSStreamEventOpenCompleted){
	}else if (eventCode == NSStreamEventHasBytesAvailable){
		uint8_t readBuffer[1024];
		unsigned int readLength = 0;
		readLength = [stream read:readBuffer maxLength:1024];
		if(!readLength){ 
			return;
		}
		[_dataOutBuffer appendBytes:readBuffer length:readLength];
		
		if (_streamLengths != nil)
			[self _didReadByteCount:readLength inStream:stream];

		[[self delegate] stream:self handleEvent:NSStreamEventHasBytesAvailable];
	}else if (eventCode == NSStreamEventEndEncountered){
		if ([_infoDelegate respondsToSelector:@selector(didCompleteInputStream:withConcatenatedInputStream:)])
			[_infoDelegate didCompleteInputStream:stream withConcatenatedInputStream:self];
		
		if( [self _queueNextInputStream] == NO){
			if ([_infoDelegate respondsToSelector:@selector(didFinishAllQueuedStreamsWithConcatenatedInputStream:)])
				[_infoDelegate didFinishAllQueuedStreamsWithConcatenatedInputStream:self];
		}
	}else if (eventCode == NSStreamEventErrorOccurred){
		EXOLog(@"Stream error occured in concatenatedInputStream");
		
		if ([_infoDelegate respondsToSelector:@selector(shouldContinueAfterFailingStream:withError:withConcatenatedInputStream:)]){
			if ([_infoDelegate shouldContinueAfterFailingStream:stream withError:nil withConcatenatedInputStream:self]){
				EXOLog(@"We'll continue through stream error that occured in concatenatedInputStream");
				
				[self _queueNextInputStream];
			}else {
				_streamStatus = NSStreamStatusError;
				[[self delegate] stream:self handleEvent:NSStreamEventErrorOccurred];
			}

		}else {
			_streamStatus = NSStreamStatusError;
			[[self delegate] stream:self handleEvent:NSStreamEventErrorOccurred];
		}
	}
}

#pragma mark concatStream
-(void) _didReadByteCount:(NSUInteger)bytes inStream:(NSInputStream*)stream{

	NSValue	*	key		=	[NSValue valueWithNonretainedObject:stream];
	
	NSNumber * remainingBytesForStream	=	[_streamLengthsRemaining objectForKey:key];
	if (remainingBytesForStream == nil)
		return;
	
	NSNumber * newValue					=	[NSNumber numberWithInt:[remainingBytesForStream intValue] - bytes];
	
	[_streamLengthsRemaining setObject:newValue forKey:key];
	
	NSUInteger totalLength	= [[_streamLengths objectForKey:key] intValue];
	NSInteger byteNumber 	= totalLength - [newValue intValue];
	EXOLog(@"Read byte #:%i of total:%i",byteNumber, totalLength);
	
	if ([_infoDelegate respondsToSelector:@selector(streamDidWriteByteNumber:ofTotalLength:forInputStream:withConcatenatedInputStream:)]){
		[_infoDelegate streamDidWriteByteNumber:byteNumber ofTotalLength:totalLength forInputStream:stream withConcatenatedInputStream:self];	
	}
}

-(BOOL)_queueNextInputStream{
	//perhaps we'll need to be alerting to finished streams here
	if (_currentInputStream != nil){
		NSInteger currentIndex = [_queuedStreams indexOfObject:_currentInputStream];
		
		if (_holdCompletedStreams){
			if (_completedStreams == nil){
				_completedStreams = [[NSMutableArray alloc] init];
			}
			[_completedStreams addObject:_currentInputStream];
		}
		
		if (_streamLengths != nil){
			NSValue	*	key		=	[NSValue valueWithNonretainedObject:_currentInputStream];
			[_streamLengths removeObjectForKey:key];
			[_streamLengthsRemaining removeObjectForKey:key];
		}

		[self	_teardownInputStream:_currentInputStream];//_current is nil
		[_queuedStreams removeObjectAtIndex:currentIndex];
	}
	
	if ([_queuedStreams count] > 0){
		NSInputStream* nextInputStream	= [_queuedStreams objectAtIndex:0];
		[self _setupInputStreamForRead:nextInputStream];
		return YES;
	}else{
		return NO;
	}
}



-(void) _setupInputStreamForRead:(NSInputStream*)readStream{
	_currentInputStream = [readStream retain];
	[_currentInputStream setDelegate:self];
	[_currentInputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_currentInputStream open];
	
	if ([_infoDelegate respondsToSelector:@selector(didBeginInputStream:withConcatenatedInputStream:)]){
		[_infoDelegate didBeginInputStream:(NSInputStream*)readStream withConcatenatedInputStream:self];
	}
}
-(void) _teardownInputStream:(NSInputStream*)stream{
	[stream close];
	[stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	if (stream == _currentInputStream)
		SRELS(_currentInputStream);
}


@end
