//
//  swypTransformPathwayInputStream.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

//passes data from dataInStream through each of the transformStreams, beginning at index zero
//exposes the last transform stream as the NSInputStream this object represents

#import <Foundation/Foundation.h>
#import "swypTransformInputStream.h"

@interface swypTransformPathwayInputStream : NSInputStream <NSStreamDelegate>  {
	NSArray	*					_orderedTransformPathwayStreams;
	NSInputStream *				_dataInputStream;
	
	swypTransformInputStream *	_lastTransformStream;
	
	id<NSStreamDelegate>		_delegate;
	NSStreamStatus				_streamStatus;
}
@property (nonatomic, readonly) NSInputStream *		dataInputStream;
@property (nonatomic, readonly) NSArray	*			transformStreams;
@property (nonatomic, assign) id<NSStreamDelegate>	delegate;

//array of swypTransformInputStreams
-(id)	initWithDataInputStream:	(NSInputStream*)dataInStream transformStreamArray:(NSArray*)transformStreams; 


//array of swypTransformInputStreams
-(void)	setTransformStreamArray:	(NSArray*)transformStreams;
-(void)	setDataInputStream:			(NSInputStream*)dataInStream;

//
//private
-(void) _setupLastTransformStreamForRead:	(NSInputStream*)readStream;
-(void) _teardownInputStream:	(NSInputStream*)stream;
-(void)	_connectTransformPathway;
@end
