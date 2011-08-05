//
//  swypTransformInputStream.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import "swypTransformInputStream.h"


@implementation swypTransformInputStream
@synthesize inputStream = _inputStream;
@synthesize delegate = _delegate;
#pragma mark -
#pragma mark public 


-(void)	reset{
	[self setInputStream:nil];
	_inputStreamIsFinished	= NO;
	SRELS(_transformedData);
	SRELS(_untransformedData);
	_transformedData	=	[[NSMutableData alloc] init];
	_untransformedData	=	[[NSMutableData alloc] init];		
}

-(void)setInputStream:(NSInputStream *)stream{
	if (_inputStream != nil){
		EXOLog(@"Cutting existing stream with end message -- wasn't finished");
		[[self delegate] stream:_inputStream handleEvent:NSStreamEventEndEncountered];
		[self _teardownInputStream:_inputStream];
		[self reset];
		if ([self streamStatus] == NSStreamStatusOpen){
			[self close];
		}			
		[self _setupInputStreamForRead:stream];
	}else {
		[self _teardownInputStream:_inputStream];
	}

}

-(BOOL)			isFinnishedTransformingData{
	if ([_untransformedData length] == 0 && [self inputStreamIsFinished] == YES)
		return YES;
	
	return NO;
}
-(BOOL)			allTransformedDataIsRead{
	if ([self isFinnishedTransformingData] && [_transformedData length] == 0)
		return YES;
	
	return NO;
}

-(BOOL)			inputStreamIsFinished{
	
	return _inputStreamIsFinished;
	
}


#pragma mark -
#pragma mark subclasses
//always subclass this method
-(void) transformData:(NSData*)sourceData inRange:(NSRange)range{
	
	//if doing crypto, for example, you may want to check if [self inputStreamIsFinished] to enact padding on sourceData in range
	
	[self didYeildTransformedData:[sourceData subdataWithRange:range] fromSource:sourceData withRange:range];
}

-(BOOL)			waitsForAllInput{
	
	return NO;
}

-(NSUInteger)	transformationChunkSize{
	return 0; //again, 0 is continuous operation, while any other size waits for that value
}



//you'll probably not subclass this one, but we leave it public for you
-(void) didYeildTransformedData:(NSData*)transformedData fromSource:(NSData*)sourceData withRange:(NSRange)range{
	
	[_transformedData appendBytes:[transformedData bytes] length:range.length];
	if (sourceData == _untransformedData){
		_untransformedNextByteIndex += range.length;
		[_untransformedData replaceBytesInRange:range withBytes:NULL length:0]; 
		_untransformedNextByteIndex -= range.length;
	}
	
	if (range.length > 0){
		[[self delegate] stream:self handleEvent:NSStreamEventHasBytesAvailable];
	}
	
	[self _handleAvailableUntransformedData];
}

#pragma mark NSInputStream

-(void) open{	
	[_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_inputStream open];
	_streamStatus = NSStreamStatusOpening;
}

-(void) close{
	[self reset];
	[self removeFromRunLoop:nil forMode:nil];
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

#pragma mark -
#pragma mark NSObject
-(id)	initWithInputStream:(NSInputStream*)stream{
	if (self = [self init]){
		[self setInputStream:stream];
	}
	return self;
}

-(id) init{
	if (self = [super init]){
		_transformedData	=	[[NSMutableData alloc] init];
		_untransformedData	=	[[NSMutableData alloc] init];		
		
	}
	return self;
}

-(void)	dealloc{
	[self close];
	SRELS(_transformedData);
	SRELS(_untransformedData);
	
	[super dealloc];
}


#pragma mark -
#pragma mark private 
-(void) _setupInputStreamForRead:(NSInputStream*)readStream{
	_inputStream = [readStream retain];
	[_inputStream setDelegate:self];	
}
-(void) _teardownInputStream:(NSInputStream*)stream{
	[stream close];
	[stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	if (stream == _inputStream)
		SRELS(_inputStream);
}

-(void)	_handleAvailableUntransformedData{
	NSUInteger chunkSize	=	[self transformationChunkSize];
	if ([_untransformedData length] > chunkSize && [self waitsForAllInput] == NO){
		if (chunkSize == 0){
			NSUInteger lengthAvailable	=  [_untransformedData length];
			[self transformData:_untransformedData inRange:NSMakeRange(_untransformedNextByteIndex, lengthAvailable-_untransformedNextByteIndex)];
		}else {
			[self transformData:_untransformedData inRange:NSMakeRange(_untransformedNextByteIndex, chunkSize)];
		}

	}else if ([self inputStreamIsFinished]) {
		NSUInteger lengthAvailable	=  [_untransformedData length];
		[self transformData:_untransformedData inRange:NSMakeRange(_untransformedNextByteIndex, lengthAvailable-_untransformedNextByteIndex)];
	}

}

#pragma mark NSStreamDelegate
- (void)stream:(NSInputStream *)stream handleEvent:(NSStreamEvent)eventCode{
	if (eventCode == NSStreamEventOpenCompleted){
		EXOLog(@"Opened stream in transformInput");
		if (_streamStatus == NSStreamStatusOpening){
			_streamStatus = NSStreamStatusOpen;
			[[self delegate] stream:self handleEvent:NSStreamEventOpenCompleted];
		}		
	}else if (eventCode == NSStreamEventHasBytesAvailable){
		uint8_t readBuffer[1024];
		unsigned int readLength = 0;
		readLength = [stream read:readBuffer maxLength:1024];
		if(!readLength){ 
			return;
		}
		[_untransformedData appendBytes:readBuffer length:readLength];
		[self _handleAvailableUntransformedData];
	}else if (eventCode == NSStreamEventEndEncountered){
		EXOLog(@"Ended stream in transformInput");

		_inputStreamIsFinished	= YES;
		
		[self _teardownInputStream:stream];
		
	}else if (eventCode == NSStreamEventErrorOccurred){
		_streamStatus = NSStreamStatusError;
		[[self delegate] stream:self handleEvent:NSStreamEventErrorOccurred];
	}
}

#pragma mark NSInputStream subclass

- (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)len{
	return NO; //doesn't matter, honestly..
}
-(NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)maxLength{
	NSUInteger readableBytes = [_transformedData length] - _untransformedNextByteIndex;
	if (readableBytes == 0)
		return 0;
	
	NSUInteger bytesToRead	= MIN (maxLength, readableBytes);
	NSRange readRange		= NSMakeRange(_untransformedNextByteIndex, bytesToRead);
	
	[_transformedData getBytes:buffer range:readRange];
	
	_untransformedNextByteIndex += bytesToRead;
	[_transformedData replaceBytesInRange:readRange withBytes:NULL length:0];
	_untransformedNextByteIndex -= bytesToRead; //cleared out now-useless data
	
	return bytesToRead;
}
-(BOOL)	hasBytesAvailable{
	NSUInteger outputDataBytes	=	[_transformedData length] -  _transformedNextByteIndex;
	
	if (outputDataBytes > 0){
		return TRUE;
	}else if ([self allTransformedDataIsRead]) {
		EXOLog(@"Ended transformInputStream");
		_streamStatus = NSStreamStatusAtEnd;
		[[self delegate] stream:self handleEvent:NSStreamEventEndEncountered];		
	}

	return FALSE; 
}



@end
