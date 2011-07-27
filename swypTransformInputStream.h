//
//  swypTransformInputStream.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

//makes a transformation on input data, is a stream itself that can be read and passed down

#import <Foundation/Foundation.h>


@interface swypTransformInputStream : NSInputStream <NSStreamDelegate> {
	NSMutableData*		_transformedData;
	NSMutableData*		_untransformedData;
	
	NSInputStream*		_inputStream;
}
@property (nonatomic, readonly) BOOL			waitsForAllInput;
@property (nonatomic, readonly) BOOL			inputStreamIsFinished; 
@property (nonatomic, retain)	NSInputStream*	inputStream;

-(id)	initWithInputStream:(NSInputStream*)stream;

// brings back to state before inputStream was set
-(void)	reset;

//
//privates
-(void) _transformData:(NSData*)sourceData inRange:(NSRange)range;
-(void) _didYeildTransformedData:(NSData)transformedData fromSource:(NSData*)sourceData withRange:(NSRange)range;

// these are just scratch-pads, know your stuff before modifying them 
-(NSMutableData*) __transformedData;
-(NSMutableData*) __untransformedData;


@end
