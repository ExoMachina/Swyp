//
//  swypConcatenatedInputStream.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

//provides one output stream from collection of input streams, immediately switching at end of each stream  

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
-(bool) shouldContinueAfterFailingStream:(NSInputStream*)stream withError:(NSError*)error withConcatenatedInputStream:(swypConcatenatedInputStream*)concatenatedStream;
@end


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

	//--THE DATA
	NSMutableData *			_dataOutBuffer;
	NSUInteger				_lastReadDataOutputIndex;
}

@property (nonatomic, readonly) NSArray *								queuedStreams;
@property (nonatomic, assign) BOOL										closeStreamAtQueueEnd;
@property (nonatomic, assign) BOOL										holdCompletedStreams;
@property (nonatomic, readonly) NSArray *								completedStreams; //only non-nil if above is YES
@property (nonatomic, assign) id<swypConcatenatedInputStreamDelegate>	infoDelegate;

//NSInputStream array
-(id)	initWithInputStreamArray:	(NSArray*)inputStreams; 


-(void)	addInputStreamToQueue:		(NSInputStream*)input;
-(void)	addInputStreamsToQueue:		(NSArray*)inputStreams;

/*
	Clears queue of any stream not running now.
	Streams don't give notifications
	Streams don't get added to completedStreams
	Eg. This should used when invalidating a stream --> afterwards pass the goodbye packet to the session
*/
-(void)	removelAllQueuedStreamsAfterCurrent;

/*
	if delegate is set, the following function will give an update each time bytes are read from the stream
	'queuedStream' is a stream already queued
	'lengthToTrack' is the length that a given stream has
*/
-(void)			setLengthToTrack:	(NSUInteger)lengthToTrack	forQueuedStream: (NSInputStream*)queuedStream;
/*
	The following function returns 0 if queued stream is finished or if it is not queued
	Passing an NSUInteger by reference to 'refForTotalBytes' has the total placed into it.. 
		It's value is non-zero if 'holdCompletedStreams' is YES, and length to track was set on it in the past
*/
-(NSUInteger)	remainingByteCountForQueuedStream:	(NSInputStream*)queuedStream withTotalLength:(NSUInteger *)refForTotalBytes;

//
//private
-(void) _setupInputStreamForRead:	(NSInputStream*)readStream;
-(void) _teardownInputStream:		(NSInputStream*)stream;
-(BOOL)	_queueNextInputStream; 

-(void) _didReadByteCount:(NSUInteger)bytes inStream:(NSInputStream*)stream;

@end
