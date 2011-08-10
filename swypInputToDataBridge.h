//
//  swypInputToDataBridge.h
//  swyp
//
//  Created by Alexander List on 8/10/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

//Simply turns an NSInputStream into NSData by reading in
//The delegate methods can be used for notification of completion
//Yielded data != nil once successfully completed

#import <Foundation/Foundation.h>
#import "swypInputToOutputStreamConnector.h"


static NSString * const swypInputToOutputStreamConnectorErrorDomain = @"swypInputToOutputStreamConnectorErrorDomain";
typedef enum{
	swypInputToOutputStreamConnectorErrorInputFailed,
	swypInputToOutputStreamConnectorErrorOutputFailed,
	swypInputToOutputStreamConnectorErrorUnknown
}swypInputToOutputStreamConnectorError;

@class swypInputToDataBridge;

@protocol swypInputToDataBridgeDelegate <NSObject>

-(void)	dataBridgeYieldedData:(NSData*) yieldedData fromInputStream:(NSInputStream*) inputStream withInputToDataBridge:(swypInputToDataBridge*)bridge;

-(void)	dataBridgeFailedYieldingDataFromInputStream:(NSInputStream*) inputStream withError: (NSError*) error inInputToDataBridge:(swypInputToDataBridge*)bridge;

@end

@interface swypInputToDataBridge : NSObject <swypInputToOutputStreamConnectorDelegate> {
	swypInputToOutputStreamConnector *	_streamConnector;
	NSInputStream*	_inputStream;
	NSOutputStream*	_outputStream;
	NSData *		_yieldedData;
	
	id<swypInputToDataBridgeDelegate>	_delegate;
}
@property (nonatomic, readonly) NSInputStream * inputStream;
@property (nonatomic, readonly) NSData *		yieldedData;

@property (nonatomic, assign)	id<swypInputToDataBridgeDelegate> delegate;

-(id)	initWithInputStream:(NSInputStream*)inputStream dataBrdigeDelegate: (id<swypInputToDataBridgeDelegate>)delegate;

//
//private
-(void)	_setupInputToOutputConnection;

@end
