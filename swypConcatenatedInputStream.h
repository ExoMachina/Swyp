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
-(void) didFinishAllQueuedStreamsWithConcatenatedInputStream:(swypConcatenatedInputStream*)concatenatedStream;
-(void) didCompleteInputStream:(NSInputStream*)stream withConcatenatedInputStream:(swypConcatenatedInputStream*)concatenatedStream;
-(void) didBeginInputStream:(NSInputStream*)stream withConcatenatedInputStream:(swypConcatenatedInputStream*)concatenatedStream;
-(bool) shouldContinueAfterFailingStream:(NSInputStream*)stream withError:(NSError*)error withConcatenatedInputStream:(swypConcatenatedInputStream*)concatenatedStream;
@end


@interface swypConcatenatedInputStream : NSInputStream <NSStreamDelegate> {
	NSMutableArray *	_queuedStreams;
	BOOL				closeStreamAtQueueEnd;

	id<swypConcatenatedInputStreamDelegate>		_delegate;
}

@property (nonatomic, readonly) NSArray *								queuedStreams;
@property (nonatomic, assign) BOOL										closeStreamAtQueueEnd;
@property (nonatomic, assign) id<swypConcatenatedInputStreamDelegate>	delegate;

//NSInputStream array
-(id)	initWithInputStreamArray:	(NSArray*)inputStreams; 

-(void)	addInputStreamToQueue:		(NSInputStream*)input;
-(void)	addInputStreamsToQueue:		(NSArray*)inputStreams;

//
//privates
-(void) _setupInputStreamForRead:	(NSInputStream*)readStream;
-(void) _teardownInputStream:		(NSInputStream*)stream;
-(BOOL)	_queueNextInputStream; 

@end
