//
//  swypDiscernedInputStream.m
//  swyp
//
//  Created by Alexander List on 8/9/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import "swypDiscernedInputStream.h"

@implementation swypDiscernedInputStream
@synthesize isIndefinite = _isIndefinite, streamLength = _streamLength, streamTag = _streamTag, streamType = _streamType,lastProvidedByteIndex = _lastProvidedByteIndex, streamEndByteIndex=_streamEndByteIndex;
@synthesize dataSource = _dataSource, delegate = _delegate;


#pragma mark -
#pragma mark public
-(id)	initWithStreamDataSource:(id<swypDiscernedInputStreamDataSource>)source type:(NSString*)type tag:(NSString*)tag length:(NSUInteger)streamLength{
	if (self = [super init]){
		_dataSource = source;
		_streamTag	= [tag retain];
		_streamType	= [type retain];

		_pulledDataBuffer =	[[NSMutableData alloc] init];
							 
		if (streamLength == 0){
			_isIndefinite		= TRUE;
		}else{
			_isIndefinite		= FALSE;
			_streamLength		= streamLength;
			_streamEndByteIndex	= streamLength - 1;
		}
		
	}
	return  self;
}

-(void) endIndefiniteStreamAtByteIndex:(NSUInteger)byteIndex{
	_streamEndByteIndex	=	byteIndex;
	_streamLength		= 	_streamEndByteIndex + 1;
	_isIndefinite		=	FALSE;
	
	NSInteger endStreamOffset	=	_lastPulledByteIndex - byteIndex;
	if (endStreamOffset < 1024 && endStreamOffset > 0){
		[_dataSource discernedStreamEndedAtStreamByteIndex:_streamEndByteIndex discernedInputStream:self];
	}else if (endStreamOffset > 1024){
		[NSException raise:@"swypDiscernedInputStreamIndefiniteStreamException" format:@"The last pulled byte from data source '%i' was '%i' bytes in past.. You must calculate stream end before next stream read.",_lastPulledByteIndex,endStreamOffset];
	}
	
	//if (endStreamOffset < 0){ //you're in the future, just hang out until ready to end
}


-(void)	shouldPullData{
	[self _handlePullFromDataSource];
	if ([self hasBytesAvailable]){
		[_delegate stream:self handleEvent:NSStreamEventHasBytesAvailable];
	}
}

#pragma mark NSObject
- (id)init
{
	return nil;
}

-(void)dealloc{
	
	[self removeFromRunLoop:nil forMode:nil];
	SRELS(_pulledDataBuffer);
	SRELS(_streamType);
	SRELS(_streamTag);
	
	[super dealloc];
}

#pragma mark NSInputStream
-(void)	open{
	_streamStatus = NSStreamStatusOpen;
	[[self delegate] stream:self handleEvent:NSStreamEventOpenCompleted];
}

-(void) close{
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
	[self shouldPullData];
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

- (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)len{
	return NO; //doesn't matter, honestly..
}
-(NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)maxLength{
	NSUInteger readableBytes = [_pulledDataBuffer length];
	if (readableBytes == 0)
		return 0;
	
	NSUInteger bytesToRead	= MIN (maxLength -1, readableBytes); //need to null terminate the last byte, and this gets put into the range...
	NSRange readRange		= NSMakeRange(0, bytesToRead);
	
	[_pulledDataBuffer getBytes:buffer range:readRange];
	buffer[readRange.location + readRange.length]	=	0x00;

	_lastProvidedByteIndex	+= bytesToRead;
	
	[_pulledDataBuffer replaceBytesInRange:readRange withBytes:NULL length:0];
	
	return bytesToRead;
}
-(BOOL)	hasBytesAvailable{
	if ([_pulledDataBuffer length] > 0){
		return TRUE;
	}else if ([self isIndefinite] == NO && _lastPulledByteIndex >  _streamEndByteIndex){
		_streamStatus = NSStreamStatusAtEnd;
		[[self delegate] stream:self handleEvent:NSStreamEventEndEncountered];
	}
	
	return FALSE; 
}



#pragma mark -
#pragma mark private
-(void)	_handlePullFromDataSource{
	static NSUInteger memPageLength	=	4096;
	
	NSInteger	neededDataQuantity	=	memPageLength - [_pulledDataBuffer length];
	
	if ([self isIndefinite] == NO){
		NSInteger	lengthToStreamEnd	= _streamLength - _lastPulledByteIndex;
		neededDataQuantity	=	MIN(neededDataQuantity, lengthToStreamEnd);
	}
	
	if (neededDataQuantity > 0){
		NSData * newData =  [_dataSource pullDataWithLength:neededDataQuantity discernedInputStream:self];
		
		if ([newData length] >0){
			_lastPulledByteIndex += [newData length];
			[_pulledDataBuffer appendData:newData];
		}
		
		
		NSInteger	remainingLengthToStreamEnd	= _streamLength - _lastPulledByteIndex;
		if (remainingLengthToStreamEnd <= 0){
			[_dataSource discernedStreamEndedAtStreamByteIndex:_streamEndByteIndex discernedInputStream:self];
		}
	}
	

}

@end
