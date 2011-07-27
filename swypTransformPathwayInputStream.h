//
//  swypTransformPathwayInputStream.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- check online.
//

//passes data from dataInStream through each of the transformStreams, beginning at index zero
//exposes the last transform stream as the NSInputStream this object represents

#import <Foundation/Foundation.h>
#import "swypTransformInputStream.h"

@interface swypTransformPathwayInputStream : NSInputStream <NSStreamDelegate>  {
	
}
//array of swypTransformInputStreams
-(id)	initWithDataInputStream:	(NSInputStream*)dataInStream transformStreamArray:(NSArray*)transformStreams; 


//array of swypTransformInputStreams
-(void)	setTransformStreamArray:	(NSArray*)transformStreams;
-(void)	setDataInputStream:			(NSInputStream*)dataInStream;

//
//privates
-(void) _setupLastStepStreamForRead:	(NSInputStream*)readStream;
-(void) _tearDownLastStepInputStream:	(NSInputStream*)stream;
-(void)	_connectTransformPathway;
@end
