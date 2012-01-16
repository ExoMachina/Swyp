//
//  swypInputToDataBridge.m
//  swyp
//
//  Created by Alexander List on 8/10/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import "swypInputToDataBridge.h"


@implementation swypInputToDataBridge
@synthesize  yieldedData = _yieldedData, inputStream = _inputStream, delegate = _delegate;

#pragma mark -
#pragma mark public

-(id)	initWithInputStream:(NSInputStream*)inputStream dataBrdigeDelegate: (id<swypInputToDataBridgeDelegate>)connectorDelegate{
	if (self = [super init]){
		_inputStream	= [inputStream retain];
		_delegate		= connectorDelegate;
		[self _setupInputToOutputConnection];
	}
	
	return self;
	
}
#pragma mark NSObject
- (id)init
{
	return nil;
}

-(void) dealloc{
	_delegate = nil;
	[_streamConnector setDelegate:nil];
	SRELS(_streamConnector);
	SRELS(_outputStream);
	SRELS(_inputStream);
	SRELS(_yieldedData);
	
	[super dealloc];
}

#pragma mark -
#pragma mark private
-(void)	_setupInputToOutputConnection{
	_outputStream		= [[NSOutputStream alloc] initToMemory];
	_streamConnector	= [[swypInputToOutputStreamConnector alloc] initWithOutputStream:_outputStream readStream:_inputStream];
	[_streamConnector setDelegate:self];
	
}
#pragma mark swypInputToOutputStreamConnectorDelegate
-(void) encounteredErrorInInputStream: (NSInputStream*)stream withInputToOutputConnector:(swypInputToOutputStreamConnector*)connector{
	[_delegate dataBridgeFailedYieldingDataFromInputStream:_inputStream withError:[NSError errorWithDomain:swypInputToOutputStreamConnectorErrorDomain code:swypInputToOutputStreamConnectorErrorInputFailed userInfo:nil] inInputToDataBridge:self];
}
-(void) encounteredErrorInOutputStream: (NSOutputStream*)stream withInputToOutputConnector:(swypInputToOutputStreamConnector*)connector{
	[_delegate dataBridgeFailedYieldingDataFromInputStream:_inputStream withError:[NSError errorWithDomain:swypInputToOutputStreamConnectorErrorDomain code:swypInputToOutputStreamConnectorErrorOutputFailed userInfo:nil] inInputToDataBridge:self];
}

-(void) completedInputStream: (NSInputStream*)stream forOutputStream:(NSOutputStream*)outputStream withInputToOutputConnector:(swypInputToOutputStreamConnector*)connector{
	NSData * yield = [outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
	if (yield){
		_yieldedData = [yield retain];
		[_delegate dataBridgeYieldedData:_yieldedData fromInputStream:_inputStream withInputToDataBridge:self];

		//no longer need these
		[_streamConnector setDelegate:nil];
		SRELS(_streamConnector);
		SRELS(_outputStream);
	}else{
		[_delegate dataBridgeFailedYieldingDataFromInputStream:_inputStream withError:[NSError errorWithDomain:swypInputToOutputStreamConnectorErrorDomain code:swypInputToOutputStreamConnectorErrorUnknown userInfo:nil] inInputToDataBridge:self];
	}
}


@end
