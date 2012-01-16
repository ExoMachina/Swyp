//
//  swypOutputToDataStream.m
//  swyp
//
//  Created by Alexander List on 1/15/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import "swypOutputToDataStream.h"

@implementation swypOutputToDataStream
@synthesize dataDelegate = _dataDelegate, delegate = _delegate;

#pragma mark - streams
-(void)invalidateByError{
	_streamStatus = NSStreamStatusError;
	if ([_delegate respondsToSelector:@selector(stream:handleEvent:)]){
		[_delegate stream:self handleEvent:NSStreamEventErrorOccurred];
	}
	
}

#pragma mark NSOutputStream
-(NSInteger)write:(const uint8_t *)buffer maxLength:(NSUInteger)len{
	NSData * relayData	=	[NSData dataWithBytes:(void*)buffer length:len];
	[_dataDelegate outputToDataStream:self wantsProvideData:relayData];
	return len;
}
- (BOOL)hasSpaceAvailable{
	return TRUE;
}


#pragma mark NSStream
-(void)	open{
	_streamStatus = NSStreamStatusOpen;
	
	if ([_delegate respondsToSelector:@selector(stream:handleEvent:)]){
		[_delegate stream:self handleEvent:NSStreamEventOpenCompleted];
		[_delegate stream:self handleEvent:NSStreamEventHasSpaceAvailable];
	}
}

-(void)	close{	
	_streamStatus = NSStreamStatusClosed;
	[_dataDelegate outputToDataStreamWasClosed:self];
	
	if ([_delegate respondsToSelector:@selector(stream:handleEvent:)]){
		[_delegate stream:self handleEvent:NSStreamEventEndEncountered];
	}
}

-(NSStreamStatus) streamStatus{
	return _streamStatus;
}

- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {

}

- (void)removeFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {

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



#pragma mark - NSObject

-(id) initWithDataDelegate:(id <swypOutputToDataStreamDataDelegate>)delegate{
	if (self =[super init]){
		_dataDelegate	=	delegate;
	}
	return self;
}

-(void)dealloc{
	if (_streamStatus == NSStreamStatusOpen){
		[self close];
	}
	_dataDelegate	= nil;
	_delegate		= nil;
	[super dealloc];
}
@end
