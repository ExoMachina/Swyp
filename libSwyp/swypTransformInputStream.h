//
//  swypTransformInputStream.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

//makes a transformation on input data; is a stream itself that can be read and passed down a pathway

#import <Foundation/Foundation.h>


@interface swypTransformInputStream : NSInputStream <NSStreamDelegate> {
	
	NSInputStream*			_inputStream;
	BOOL					_inputStreamIsFinished;
	
	NSStreamStatus			_streamStatus;
	
	id<NSStreamDelegate>	_delegate;
	NSTimer	*				_runloopTimer;
	
	//#
	// these are just scratch-pads, know your stuff before modifying them 
	NSMutableData*		_transformedData;
	NSUInteger			_transformedNextByteIndex;
	NSMutableData*		_untransformedData;
	NSUInteger			_untransformedNextByteIndex;
	//#	
}
/* 
	view the implementation of this property before overwriting an existing inputStream 
		the current stream ended and self is reset
*/
@property (nonatomic, retain)	NSInputStream*			inputStream; 
@property (nonatomic, assign) 	id<NSStreamDelegate>	delegate;

-(id)	initWithInputStream:(NSInputStream*)stream;

/* 
	Brings back to state before inputStream was set
*/
-(void)	reset;

/*
	In subclassing, this method can be used to see whether the input stream did give the end event
*/
-(BOOL)			inputStreamIsFinished; 
-(BOOL)			isFinnishedTransformingData;

/*
	If this method returns true, then isFinnishedTransformingData is also true
	Externally, this method can be used to tell when "reset" is appropiate
*/
-(BOOL)			allTransformedDataIsRead;

//
//to subclass 
/*
	if waitsForAllInput == NO, data will be passed in quantities of transformationChunkSize, until inputStreamIsFinished == YES
*/
-(void) transformData:(NSData*)sourceData inRange:(NSRange)range;

/*
	If so, we wait until inputStream sends the end event before beginning transformations
*/
-(BOOL)			waitsForAllInput;	

/*
	If non-zero, transformData:inRange: is called when available untransformedData's length exceeds this quantity
		when inputStreamIsFinnished transformData:inRange: is called until no more untransformed data exists, regardless of chunkSize
	If zero, chunk size is irrelevant and transformData is continuously run with full range of the remaining untransformedData
*/
-(NSUInteger)	transformationChunkSize; 

//
//to probably not subclass, but appreciate and understand
/*
	don't need to transform all data passed in transformData:inRange:
	if bytes remaining >transformationChunkSize, or if inputStreamIsFinished == YES, transformData:: will be called until all bytes are transformed
*/
-(void) didYieldTransformedData:(NSData*)transformedData fromSource:(NSData*)sourceData withRange:(NSRange)range;



//
//private
-(void) _setupInputStreamForRead:	(NSInputStream*)readStream;
-(void) _teardownInputStream:		(NSInputStream*)stream;
-(void)	_handleAvailableUntransformedData;

@end
