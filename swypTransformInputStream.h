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
	NSMutableData*		_transformedData;
	NSMutableData*		_untransformedData;
	
	NSInputStream*		_inputStream;
}
@property (nonatomic, readonly) BOOL			waitsForAllInput;
@property (nonatomic, readonly) BOOL			inputStreamIsFinished; 
@property (nonatomic, readonly) NSUInteger		transformationChunkSize; //0 if chunk size is irrelevant
@property (nonatomic, retain)	NSInputStream*	inputStream;

-(id)	initWithInputStream:(NSInputStream*)stream;

// brings back to state before inputStream was set
-(void)	reset;

//
//to subclass 

/*
	if waitsForAllInput == NO, data will be passed in quantities of transformationChunkSize, until inputStreamIsFinished == YES
*/
-(void) transformData:(NSData*)sourceData inRange:(NSRange)range;

/*
	don't need to transform all data passed in transformData:inRange:
	if bytes remaining >transformationChunkSize, or if inputStreamIsFinished == YES, transformData:: will be called until all bytes are transformed
*/
-(void) didYeildTransformedData:(NSData*)transformedData fromSource:(NSData*)sourceData withRange:(NSRange)range;

//
// these are just scratch-pads, know your stuff before modifying them 
-(NSMutableData*) __transformedData;
-(NSMutableData*) __untransformedData;


@end
