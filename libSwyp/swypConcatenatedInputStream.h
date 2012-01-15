//
//  swypConcatenatedInputStream.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import <Foundation/Foundation.h>

@class swypConcatenatedInputStream;

@protocol swypConcatenatedInputStreamDelegate <NSObject>
@optional
-(void) didFinishAllQueuedStreamsWithConcatenatedInputStream:(swypConcatenatedInputStream*)concatenatedStream;
-(void) didCompleteInputStream:(NSInputStream*)stream withConcatenatedInputStream:(swypConcatenatedInputStream*)concatenatedStream;
-(void) didBeginInputStream:(NSInputStream*)stream withConcatenatedInputStream:(swypConcatenatedInputStream*)concatenatedStream;
-(void) streamDidWriteByteNumber:(NSUInteger)byteNumber ofTotalLength:(NSUInteger)totalLength forInputStream:(NSInputStream*)inputStream withConcatenatedInputStream:(swypConcatenatedInputStream*)concatenatedStream;
/*
	Returning NO will close the stream
*/
-(BOOL) shouldContinueAfterFailingStream:(NSInputStream*)stream withError:(NSError*)error withConcatenatedInputStream:(swypConcatenatedInputStream*)concatenatedStream;
@end

/** Provides one input stream from collection of input streams, immediately switching at end of each stream  
 
 I can make one big stream out of a bunch of small ones now. Only encapsulating stream.*/
@interface swypConcatenatedInputStream : NSInputStream <NSStreamDelegate> {
	NSMutableArray *		_queuedStreams;
	NSInputStream *			_currentInputStream;
	
	BOOL					_closeStreamAtQueueEnd;

	//nil unless delegate && lengths are tracked
	NSMutableDictionary*	_streamLengthsRemaining;
	NSMutableDictionary*	_streamLengths;
	
	BOOL					_holdCompletedStreams;
	NSMutableArray *		_completedStreams;

	id<swypConcatenatedInputStreamDelegate>		_infoDelegate;
	id<NSStreamDelegate>						_delegate;
	NSTimer	*									_runloopTimer;

	
	NSStreamStatus			_streamStatus;
	
	
	//--THE DATA
	NSMutableData *			_dataOutBuffer;
	NSUInteger				_nextDataOutputIndex;
}
/** Provides array of all currently queud streams */
@property (nonatomic, readonly) NSArray *								queuedStreams;

/** Defines behavior when all queued streams are finished being read.
 
 When TRUE, triggers NSStreamStatusAtEnd
 when FALSE, the stream conveys that no data is available currently, but that the stream is still open

 @warning default is YES;
 */
@property (nonatomic, assign) BOOL										closeStreamAtQueueEnd; 

/** Allow access through completedStreams property to all streams past through completedStreams property. 
 
 @warning the default value is NO;
 */
@property (nonatomic, assign) BOOL										holdCompletedStreams; 
/** Only non-nil if holdCompletedStreams is YES; otherwise streams are deleted */
@property (nonatomic, readonly) NSArray *								completedStreams; 
///the delegate for non-NSStreamDelegate updates
@property (nonatomic, assign) id<swypConcatenatedInputStreamDelegate>	infoDelegate;
///the delegate for NSStreamDelegate updates
@property (nonatomic, assign) id<NSStreamDelegate>						delegate;

///NSInputStream array
-(id)	initWithInputStreamArray:	(NSArray*)inputStreams; 

///add NSInputStream
-(void)	addInputStreamToQueue:		(NSInputStream*)input;
///NSInputStream array
-(void)	addInputStreamsToQueue:		(NSArray*)inputStreams;


-(BOOL)	finishedRelayingAllQueuedStreamData;

/**
	Clears queue of any stream not running now.
	Streams don't give notifications
	Streams don't get added to completedStreams
	Eg. This should used when invalidating a stream --> afterwards pass the goodbye packet to the session
*/
-(void)	removeAllQueuedStreamsAfterCurrent;

/**
	if delegate is set, the following function will give an update each time bytes are read from the stream
	'queuedStream' is a stream already queued
	'lengthToTrack' is the length that a given stream has
*/
-(void)	setLengthToTrack:	(NSUInteger)lengthToTrack	forQueuedStream: (NSInputStream*)queuedStream;
/**
	The following function returns 0 if queued stream is finished or if it is not queued
	Passing an NSUInteger by reference to 'refForTotalBytes' has the total placed into it.. 
		Its value is non-zero if 'holdCompletedStreams' is YES, and length to track was set on it in the past
*/
-(NSUInteger)	remainingByteCountForQueuedStream:	(NSInputStream*)queuedStream withTotalLength:(NSUInteger *)refForTotalBytes;

//
//private
-(void) _setupInputStreamForRead:	(NSInputStream*)readStream;
-(void) _teardownInputStream:		(NSInputStream*)stream;
-(BOOL)	_queueNextInputStream; 

-(void) _didReadByteCount:(NSUInteger)bytes inStream:(NSInputStream*)stream;

@end
