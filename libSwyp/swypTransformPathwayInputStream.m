//
//  swypTransformPathwayInputStream.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import "swypTransformPathwayInputStream.h"


@implementation swypTransformPathwayInputStream
@synthesize delegate = _delegate, dataInputStream = _dataInputStream, transformStreams = _orderedTransformPathwayStreams;
#pragma mark -
#pragma mark public
-(void) setDataInputStream:(NSInputStream *)dataInStream{
	if ([self streamStatus] == NSStreamStatusOpen){
		EXOLog(@"error in setDataInputStream because stream already open");
		_streamStatus = NSStreamStatusError;
		[[self delegate] stream:self handleEvent:NSStreamEventErrorOccurred];
	}	
	
	SRELS(_dataInputStream);
	_dataInputStream = [dataInStream retain];
}
-(void)	setTransformStreamArray:	(NSArray*)transformStreams{
	if ([self streamStatus] == NSStreamStatusOpen){
		EXOLog(@"error in setTransformStreamArray because stream already open");
		[[self delegate] stream:self handleEvent:NSStreamEventErrorOccurred];
		_streamStatus = NSStreamStatusError;
	}	
	
	SRELS(_orderedTransformPathwayStreams);
	_orderedTransformPathwayStreams = [transformStreams retain];
}

#pragma mark NSInputStream
-(void)	open{
	_streamStatus = NSStreamStatusOpening;

	[self _connectTransformPathway];
}

-(void)	close{	
	[self _teardownInputStream:_lastTransformStream];
	
	for (int i = 0; i < [_orderedTransformPathwayStreams count]; i++){
		swypTransformInputStream * nextStream = [_orderedTransformPathwayStreams objectAtIndex:i];
		[nextStream reset];
	}
	
	_streamStatus = NSStreamStatusClosed;
}

-(NSStreamStatus) streamStatus{
	if (_lastTransformStream != nil){
		return [_lastTransformStream streamStatus];
	}else {
		return _streamStatus;
	}
}

- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
	//relies on other input streams' updates for moving data
	[_lastTransformStream scheduleInRunLoop:aRunLoop forMode:mode];
}

- (void)removeFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
	[_lastTransformStream removeFromRunLoop:aRunLoop forMode:mode];
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
-(id)	initWithDataInputStream:	(NSInputStream*)dataInStream transformStreamArray:(NSArray*)transformStreams{
	if (self = [self init]){
		[self setDataInputStream:dataInStream];
		[self setTransformStreamArray:transformStreams];
	}
	
	return self;
}

-(id) init{
	if (self = [super init]){
		
	}
	
	return self;
}

-(void)	dealloc{
	[self close];
	
	[super dealloc];
}

#pragma mark -
#pragma mark private 
-(void) _connectTransformPathway{
	if ( [_orderedTransformPathwayStreams count] == 0 && _dataInputStream != nil){
		[self _setupLastTransformStreamForRead:_dataInputStream];
		return;
	}
	
	swypTransformInputStream * nextStream = [_orderedTransformPathwayStreams objectAtIndex:0];
	[nextStream reset];
	[nextStream setInputStream:_dataInputStream];
	
	swypTransformInputStream * previousStream = nextStream;
	for (int i = 1; i < [_orderedTransformPathwayStreams count]; i++){
		nextStream = [_orderedTransformPathwayStreams objectAtIndex:i];
		[nextStream reset];
		[nextStream setInputStream:previousStream];
		previousStream = nextStream;
	}
	[self _setupLastTransformStreamForRead:previousStream]; 
}


-(void) _setupLastTransformStreamForRead:(NSInputStream*)readStream{
	if (_lastTransformStream != nil)
		[self _teardownInputStream:_lastTransformStream];
	_lastTransformStream  = (swypTransformInputStream*) [readStream retain];
	[_lastTransformStream setDelegate:self];
	[_lastTransformStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_lastTransformStream open]; 
}

-(void) _teardownInputStream:(NSInputStream*)stream{
	[stream close];
	[stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	if (stream == _lastTransformStream)
		SRELS(_lastTransformStream);
}


#pragma mark NSStreamDelegate
- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode{
	[[self delegate] stream:self handleEvent:(NSStreamEvent)eventCode];
}
#pragma mark NSInputStream subclass
- (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)len{
	if (_lastTransformStream == nil)
		return NO;
	return [_lastTransformStream getBuffer:buffer length:len];
}
- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len{
	if (_lastTransformStream == nil)
		return 0;
	return [_lastTransformStream read:buffer maxLength:len];
}
- (BOOL)hasBytesAvailable{
	if (_lastTransformStream == nil)
		return NO;
	return [_lastTransformStream hasBytesAvailable]; 
}
@end
