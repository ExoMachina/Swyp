//
//  swypInputStreamDiscerner.h
//  swyp
//
//  Created by Alexander List on 8/8/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "swypDiscernedInputStream.h"


@class swypInputStreamDiscerner;
@protocol swypInputDiscernerDelegate <NSObject>

-(void)	discernedStream:(swypDiscernedInputStream*)discernedStream withDiscerner:(swypInputStreamDiscerner*)discerner;
-(void)	inputStreamDiscernerFailedWithError:(NSError*)error withDiscerner:(swypInputStreamDiscerner*)discerner;

@end


@interface swypInputStreamDiscerner : NSObject <NSStreamDelegate, swypDiscernedInputStreamDataSource>{
	
	NSInputStream*					_discernmentStream;
	
	//holds last KB of read data, plus 1 kb of new data!
	NSMutableData*					_bufferedData;
	NSUInteger						_bufferedDataNextReadIndex;; 
	
	swypDiscernedInputStream*		_lastYieldedStream;
	
	id<swypInputDiscernerDelegate>	_delegate;

}
@property (nonatomic, readonly) NSInputStream *					discernmentStream;
@property (nonatomic, assign)	id<swypInputDiscernerDelegate>	delegate;

-(id)	initWithInputStream:(NSInputStream*)discernmentStream discernerDelegate:(id<swypInputDiscernerDelegate>)delegate;

//
//private

/*	
	called if _lastYieldedStream == nil
	reads for header at this location in buffer, handles if it exists, does nothing if it doesn't
	Resets _bufferedDataNextReadIndex; to zero
	Removes header from buffer, calls _generateDiscernedStream
*/
-(void)	_handleHeaderPacketFromCurrentBufferLocation:(NSUInteger)		location; 

-(void)	_generateDiscernedStreamWithHeaderDictionary:(NSDictionary*) headerDictionary payloadLength: (NSUInteger)length;

-(void) _handleInputDataRead;


-(void) _setupInputStreamForRead:	(NSInputStream*)readStream;
-(void) _teardownInputStream;
@end
