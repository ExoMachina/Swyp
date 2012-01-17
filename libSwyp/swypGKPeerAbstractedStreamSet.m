//
//  swypGKPeerAbstractedStreamSet.m
//  swyp
//
//  Created by Alexander List on 1/15/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import "swypGKPeerAbstractedStreamSet.h"

@implementation swypGKPeerAbstractedStreamSet
@synthesize peerReadStream = _peerReadStream, peerWriteStream = _peerWriteStream, peerName = _peerName, delegate = _delegate;


-(id)initWithPeerName:(NSString*)peerName streamSetDelegate:(id<swypGKPeerAbstractedStreamSetDelegate>)delegate{
	if (self = [super init]){
		_delegate = delegate;
		_peerName = [peerName retain];

		_peerReadStream		= [[swypConcatenatedInputStream alloc] init];
		[_peerReadStream setInfoDelegate:self];
		[_peerReadStream setCloseStreamAtQueueEnd:FALSE];
		
		_peerWriteStream	= [[swypOutputToDataStream alloc] initWithDataDelegate:self];
	}
	return self;
}

-(void) addDataToPeerReadStream:(NSData*)addedData{
	NSInputStream * addStream = [NSInputStream inputStreamWithData:addedData];
	[_peerReadStream addInputStreamToQueue:addStream];
}

-(void) invalidateStreamSet{
	[_peerWriteStream invalidateByError]; //the only command really needed to push errors up the chain-- why stream is closing..
	[_peerWriteStream setDataDelegate:nil];
	[_delegate peerAbstractedStreamSetDidClose:self withPeerNamed:_peerName];

}


#pragma mark - delegation 
#pragma mark swypConcatenatedInputStreamDelegate
-(BOOL) shouldContinueAfterFailingStream:(NSInputStream*)stream withError:(NSError*)error withConcatenatedInputStream:(swypConcatenatedInputStream*)concatenatedStream{
	EXOLog(@"Error after failing stream in swypGKPeerAbstractedStreamSet: %@", [error description]);
	[self invalidateStreamSet];
	return NO;
}

#pragma mark swypOutputToDataStreamDataDelegate
-(void)outputToDataStream:(swypOutputToDataStream*)stream wantsProvideData:(NSData*)data{
	[_delegate peerAbstractedStreamSet:self wantsDataSent:data toPeerNamed:_peerName];
}

-(void)outputToDataStreamWasClosed:(swypOutputToDataStream *)stream{
	[self invalidateStreamSet];
}

#pragma mark NSObject
-(void) dealloc{
	_delegate = nil;
	SRELS(_peerName);
	
	SRELS(_peerReadStream);
	SRELS(_peerWriteStream);
	
	[super dealloc];
}

@end
