//
//  swypInputToOutputStreamConnector.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

//doesn't close output stream, allows new streams to be set for input, these get pulled as soon as ready 

#import <Foundation/Foundation.h>


@interface swypInputToOutputStreamConnector : NSObject <NSStreamDelegate>  {
	NSOutputStream *	_outputStream;
	NSInputStream*		_inputStream;
}
@property (nonatomic, readonly)	NSOutputStream *	outputStream;
@property (nonatomic, retain)	NSInputStream*		inputStream;

-(id)	initWithOutputStream:(NSOutputStream*)outputStream readStream:(NSInputStream*)inputStream; 

@end
