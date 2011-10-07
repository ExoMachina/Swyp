//
//  swypDiscernedInputStream.h
//  swyp
//
//  Created by Alexander List on 8/9/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "swypFileTypeString.h"
#import "swypInputToDataBridge.h"

@class swypDiscernedInputStream;

@protocol swypDiscernedInputStreamDataSource <NSObject>

-(void)		discernedStreamEndedAtStreamByteIndex:(NSUInteger)endByteIndex  discernedInputStream:(swypDiscernedInputStream*)inputStream;
-(NSData*)	pullDataWithLength:(NSUInteger)maxLength discernedInputStream:(swypDiscernedInputStream*)inputStream;

@end

@interface swypDiscernedInputStream : NSInputStream <NSStreamDelegate>{
	BOOL					_isIndefinite;
	NSUInteger				_streamLength;
	NSString*				_streamTag;
	NSString*				_streamType;
	NSUInteger				_lastProvidedByteIndex;
	NSUInteger				_streamEndByteIndex;
	
	id<swypDiscernedInputStreamDataSource>			_dataSource;
	
	id<NSStreamDelegate>				_delegate;
	NSTimer	*							_runloopTimer;
	NSStreamStatus						_streamStatus;

	
	//internals
	NSMutableData *			_pulledDataBuffer;
	NSUInteger				_lastPulledByteIndex;
	
}


//stream info
/*
	Indefinite streams occur when both endpoints support the same proprietary protocol, and set stream payload length to 0
	When the indefinite stream is to be ended, endIndefiniteStreamAtByteIndex: must be called referencing a byte that has either not yet been read, or has been read in the last read cycle 
*/
@property (nonatomic, readonly)	BOOL					isIndefinite;
@property (nonatomic, readonly)	NSUInteger				streamLength;
@property (nonatomic, readonly) NSString*				streamTag;
@property (nonatomic, readonly)	NSString*				streamType;
@property (nonatomic, readonly)	NSUInteger				lastProvidedByteIndex;
@property (nonatomic, readonly)	NSUInteger				streamEndByteIndex;

@property (nonatomic, assign)	id<swypDiscernedInputStreamDataSource>			dataSource;
@property (nonatomic, assign)	id<NSStreamDelegate>							delegate;


-(id)	initWithStreamDataSource:(id<swypDiscernedInputStreamDataSource>)dataSource type:(NSString*)type tag:(NSString*)tag length:(NSUInteger)streamLength;

/*
	This method enables the next input stream to be queued out of data already consumed by reading this object's NSStream
	byteIndex must exist within the most recent read, or in the future
		eg, it can't be from two stream reads back
	Calling this method on a discernedInputStream makes it become definite
*/
-(void) endIndefiniteStreamAtByteIndex:(NSUInteger)byteIndex;


//this method tells the discernedInputStream that there is data available, and that it should pull it!
-(void)	shouldPullData;

//
//private
-(void)	_handlePullFromDataSource;


@end