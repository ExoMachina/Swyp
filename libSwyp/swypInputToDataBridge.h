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

/** Data Recipient for stream soakage */
@protocol swypInputToDataBridgeDelegate <NSObject>
/** Data retrieved notification */
-(void)	dataBridgeYieldedData:(NSData*) yieldedData fromInputStream:(NSInputStream*) inputStream withInputToDataBridge:(swypInputToDataBridge*)bridge;
/** Data failed notfication... Sorry. */
-(void)	dataBridgeFailedYieldingDataFromInputStream:(NSInputStream*) inputStream withError: (NSError*) error inInputToDataBridge:(swypInputToDataBridge*)bridge;

@end


/** This class(y) class written by alex soaks an NSInputStream into NSData
 
 Set an input within init and set a delegate. Be notified when the stream is at end and data is ready.
 */
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

/** Set NSInputStream and your delegate 
 
 @param inputStream Stream should not be yet opened or attached to any runloop.
 */
-(id)	initWithInputStream:(NSInputStream*)inputStream dataBrdigeDelegate: (id<swypInputToDataBridgeDelegate>)delegate;

//
//private
-(void)	_setupInputToOutputConnection;

@end
