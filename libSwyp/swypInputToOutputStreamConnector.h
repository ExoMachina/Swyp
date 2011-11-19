//
//  swypInputToOutputStreamConnector.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

//doesn't close output stream, allows new streams to be set for input, these get pulled as soon as ready 

#import <Foundation/Foundation.h>
@class swypInputToOutputStreamConnector;

@protocol swypInputToOutputStreamConnectorDelegate <NSObject>
-(void) encounteredErrorInInputStream: (NSInputStream*)stream withInputToOutputConnector:(swypInputToOutputStreamConnector*)connector;
-(void) encounteredErrorInOutputStream: (NSOutputStream*)stream withInputToOutputConnector:(swypInputToOutputStreamConnector*)connector;

-(void) completedInputStream: (NSInputStream*)stream forOutputStream:(NSOutputStream*)outputStream withInputToOutputConnector:(swypInputToOutputStreamConnector*)connector;

@end


@interface swypInputToOutputStreamConnector : NSObject <NSStreamDelegate>  {
	NSOutputStream *	_outputStream;
	NSInputStream*		_inputStream;
	
	
	NSMutableData*		_bufferedData;
	
	
	id<swypInputToOutputStreamConnectorDelegate>	_delegate;
}
@property (nonatomic, readonly)	NSOutputStream *	outputStream;
@property (nonatomic, retain)	NSInputStream*		inputStream;
@property (nonatomic, assign) 	id<swypInputToOutputStreamConnectorDelegate>	delegate;

-(id)	initWithOutputStream:(NSOutputStream*)outputStream readStream:(NSInputStream*)inStream; 

//
//private
-(void) _setupOutputStreamForWrite:(NSOutputStream*)output;
-(void) _teardownOutputStream;

-(void) _setupInputStreamForRead:	(NSInputStream*)readStream;
-(void) _teardownInputStream:		(NSInputStream*)stream;

@end
