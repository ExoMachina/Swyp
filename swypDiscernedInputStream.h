//
//  swypDiscernedInputStream.h
//  swyp
//
//  Created by Alexander List on 8/9/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "swypFileTypeString.h"

@class swypDiscernedInputStream;

@protocol swypDiscernedInputStreamSimpleDataDelegate <NSObject>
-(void)	yieldedData:(NSData*)data forDiscernedInputStream:(swypDiscernedInputStream*)inputStream;
@end

@protocol swypDiscernedInputStreamDataSource <NSObject>

-(void)		discernedStreamEndedAtStreamByteIndex:(NSUInteger)endByteIndex discernedInputStream:(swypDiscernedInputStream*)inputStream;
-(NSData*)	pullDataFromIndex:(NSUInteger)lastReadPoint	discernedInputStream:(swypDiscernedInputStream*)inputStream;

@end

@interface swypDiscernedInputStream : NSInputStream <NSStreamDelegate>{
	BOOL					_isIndefinite;
	NSUInteger				_streamLength;
	NSString*				_streamTag;
	swypFileTypeString*		_streamType;
	NSUInteger				_lastProvidedByteIndex;
	NSUInteger				_streamEndByteIndex;
	
	id<swypDiscernedInputStreamDataSource>			_dataSource;
	id<swypDiscernedInputStreamSimpleDataDelegate>	_simpleDelegate;
	
	id<NSStreamDelegate>				_delegate;
	NSTimer	*							_runloopTimer;
	NSStreamStatus						_streamStatus;

	
	//internals
	NSMutableData *			_providerDataBuffer;
	NSMutableData *			_pulledDataBuffer;
	NSUInteger				_lastPulledByteIndex;
}


//stream info
@property (nonatomic, readonly)	BOOL					isIndefinite;
@property (nonatomic, readonly)	NSUInteger				streamLength;
@property (nonatomic, readonly) NSString*				streamTag;
@property (nonatomic, readonly)	swypFileTypeString*		streamType;
@property (nonatomic, readonly)	NSUInteger				lastProvidedByteIndex;

@property (nonatomic, readonly) id<swypDiscernedInputStreamDataSource>			dataSource;
@property (nonatomic, assign)	id<NSStreamDelegate>							delegate;

/*
	Setting this property allows buffering of all data in an _isIndefinite == NO stream, and passing a yieldedData:: message of all data when done buffering
	This functionality cannot be used in conjunction with NSInputStream support -- such will result in exception raising
		Internally, this property sets the stream delegate to self
*/
@property (nonatomic, assign)	id<swypDiscernedInputStreamSimpleDataDelegate>	simpleDelegate;


-(id)	initWithStreamDataSource:(id<swypDiscernedInputStreamDataSource>)dataSource type:(swypFileTypeString*)type tag:(NSString*)tag length:(NSUInteger)streamLength;

/*
	This method enables the next input stream to queued out of data already consumed by reading this object's NSStream
	byteIndex must exist within the most recent read, or in the future
		eg, it can't be from two stream reads back
*/
-(void) endIndefiniteStreamAtByteIndex:(NSUInteger)byteIndex;


//
//private
-(void)	_handlePullFromDataSource;


@end