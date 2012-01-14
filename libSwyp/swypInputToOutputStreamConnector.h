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
///error in the input
-(void) encounteredErrorInInputStream: (NSInputStream*)stream withInputToOutputConnector:(swypInputToOutputStreamConnector*)connector;
///error in the output
-(void) encounteredErrorInOutputStream: (NSOutputStream*)stream withInputToOutputConnector:(swypInputToOutputStreamConnector*)connector;

///we're done
-(void) completedInputStream: (NSInputStream*)stream forOutputStream:(NSOutputStream*)outputStream withInputToOutputConnector:(swypInputToOutputStreamConnector*)connector;

@end

/** This class was written to address the need of sending NSInputStream data over socket NSOutputStreams. 
 
 
 Eg, NSInputStream's init with data methods need to be sent over sockets, or written to disk sometimes. 
 */
@interface swypInputToOutputStreamConnector : NSObject <NSStreamDelegate>  {
	NSOutputStream *	_outputStream;
	NSInputStream*		_inputStream;
	
	
	NSMutableData*		_bufferedData;
	
	
	id<swypInputToOutputStreamConnectorDelegate>	_delegate;
}
@property (nonatomic, readonly)	NSOutputStream *	outputStream;
@property (nonatomic, retain)	NSInputStream*		inputStream;
@property (nonatomic, assign) 	id<swypInputToOutputStreamConnectorDelegate>	delegate; ///this protocol will let you know about encountered errors

/** the main init function which sets up streams as open, and begins sending any available inStream data over any available space in outputStream.
 
 @warning neither stream should be open yet.
 */
-(id)	initWithOutputStream:(NSOutputStream*)outputStream readStream:(NSInputStream*)inStream; 

//
//private
-(void) _setupOutputStreamForWrite:(NSOutputStream*)output;
-(void) _teardownOutputStream;

-(void) _setupInputStreamForRead:	(NSInputStream*)readStream;
-(void) _teardownInputStream:		(NSInputStream*)stream;

@end
