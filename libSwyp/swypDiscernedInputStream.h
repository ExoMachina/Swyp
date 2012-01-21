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

/** dataSource of a swypDiscernedInputStream must conform to two methods */
@protocol swypDiscernedInputStreamDataSource <NSObject>
/** See discussion of endIndefiniteStreamAtByteIndex in swypDiscernedInputStream.
 
 This tells the datasource that discerning a particular object from the datasource completed at a certain byte index. */
-(void)		discernedStreamEndedAtStreamByteIndex:(NSUInteger)endByteIndex  discernedInputStream:(swypDiscernedInputStream*)inputStream;
/** How the discernedInputStream retrieves data */
-(NSData*)	pullDataWithLength:(NSUInteger)maxLength discernedInputStream:(swypDiscernedInputStream*)inputStream;

@end

/** This class allows discrete files to be removed from a flowing NSInputStream.
 
 This class creates an input stream from an input dataSource, making the stream only have as much data as is authorized by the init function, and notifying the swypInputStreamDiscerner when completed.

 */
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
/**
	Indefinite streams occur when both endpoints support the same proprietary protocol, and set stream payload length to 0
	When the indefinite stream is to be ended, endIndefiniteStreamAtByteIndex: must be called referencing a byte that has either not yet been read, or has been read in the last read cycle.
*/
@property (nonatomic, readonly)	BOOL					isIndefinite;
///Length of stream, if known
@property (nonatomic, readonly)	NSUInteger				streamLength;
///Tag for the stream
@property (nonatomic, readonly) NSString*				streamTag;
///The swypFileTypeString for the stream type
@property (nonatomic, readonly)	NSString*				streamType;
///last read byte in stream... Ideal for key-value observing progress.
@property (nonatomic, readonly)	NSUInteger				lastProvidedByteIndex;
///Last byte in stream streamEndByteIndex - lastProvidedByteIndex = remaining bytes.
@property (nonatomic, readonly)	NSUInteger				streamEndByteIndex;


/** This is for swypInputStreamDiscerner, which will notify you if you are a swypConnectionSessionDataDelegate, don't worry about this.
 
	Instead of directly manipulating delegation of this class, use a model in swypContentInteractionManager, or set yourself as swypConnectionSessionDataDelegate on swypConnectionSession.
 */
@property (nonatomic, assign)	id<swypDiscernedInputStreamDataSource>			dataSource;

//Input streams need a delegate, don't worry about this. 
@property (nonatomic, assign)	id<NSStreamDelegate>							delegate;

///the primary init function
-(id)	initWithStreamDataSource:(id<swypDiscernedInputStreamDataSource>)dataSource type:(NSString*)type tag:(NSString*)tag length:(NSUInteger)streamLength;

/**
	This method enables the next input stream to be queued out of data already consumed by reading this object's NSStream
	byteIndex must exist within the most recent read, or in the future
		eg, it can't be from two stream reads back
	Calling this method on a discernedInputStream makes it become definite
*/
-(void) endIndefiniteStreamAtByteIndex:(NSUInteger)byteIndex;


///this method tells the discernedInputStream that there is data available, and that it should pull it!
-(void)	shouldPullData;

//
//private
-(void)	_handlePullFromDataSource;


@end