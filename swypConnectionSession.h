//
//  swypConnectionSession.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import <Foundation/Foundation.h>
#import "swypCandidate.h"
#import "swypCryptoSession.h"
#import "swypInfoRef.h"
#import "swypFileTypeString.h"
#import "swypConcatenatedInputStream.h"
#import "swypTransformPathwayInputStream.h"
#import "swypInputToOutputStreamConnector.h"
#import "swypFileTypeString.h"
#import "swypInputStreamDiscerner.h"
#import "swypDiscernedInputStream.h"

static NSString * const swypConnectionSessionErrorDomain;
typedef enum {
	swypConnectionSessionSocketError,
	swypConnectionSessionStreamError
}	swypConnectionSessionErrorCode;


@class swypConnectionSession;

typedef enum {
	swypConnectionSessionStatusClosed = -1,
	swypConnectionSessionStatusNotReady = 0,
	swypConnectionSessionStatusWillDie,
	swypConnectionSessionStatusPreparing,
	swypConnectionSessionStatusReady
} swypConnectionSessionStatus;

@protocol swypConnectionSessionInfoDelegate <NSObject>
-(void) sessionDied:			(swypConnectionSession*)session withError:(NSError*)error;

@optional
-(void) sessionWillDie:			(swypConnectionSession*)session;
-(void) sessionStatusChanged:	(swypConnectionSessionStatus)status	inSession:(swypConnectionSession*)session;
@end

@protocol swypConnectionSessionDataDelegate <NSObject>
@optional
/*
	Though there are several data delegates, only one delegate should handle and return TRUE, all else returning false
	If no one handles, an exception is thrown
*/
-(BOOL) delegateWillHandleDiscernedStream:(swypDiscernedInputStream*)stream inConnectionSession:(swypConnectionSession*)session;
-(void) connectionFailedWithError:(NSError*)connectionError	inConnectionSession:(swypConnectionSession*)session;

-(void)	failedSendingStream:(NSInputStream*)stream error:(NSError*)error connectionSession:(swypConnectionSession*)session;;
-(void) completedSendingStream:(NSInputStream*)stream connectionSession:(swypConnectionSession*)session;
@end


@interface swypConnectionSession : NSObject <NSStreamDelegate, swypConcatenatedInputStreamDelegate, swypInputToOutputStreamConnectorDelegate, swypInputStreamDiscernerDelegate> {
	NSMutableSet *	_dataDelegates;
	NSMutableSet *	_connectionSessionInfoDelegates;
	
	UIColor *		_sessionHueColor;
	
	swypCryptoSession *		_cryptoSession;
	swypCandidate *			_representedCandidate;
	
	swypConnectionSessionStatus			_connectionStatus;
	
	swypConcatenatedInputStream *		_sendDataQueueStream;				//setCloseWhenFinished:NO 
	swypTransformPathwayInputStream *	_socketOutputTransformInputStream;	//initWithDataInputStream:_sendDataQueueStream transformStreamArray:nil 
	swypInputToOutputStreamConnector *	_outputStreamConnector;				//initWithOutputStream:_socketOutputStream readStream:_socketOutputTransformInputStream
	
	swypInputStreamDiscerner *			_inputStreamDiscerner;				//splits up input data
	
	NSInputStream *			_socketInputStream;
	NSOutputStream *		_socketOutputStream;
}
@property (nonatomic, readonly)	swypConnectionSessionStatus	connectionStatus;
@property (nonatomic, retain)	UIColor*					sessionHueColor;
@property (nonatomic, readonly)	swypCandidate *				representedCandidate;

-(id)	initWithSwypCandidate:	(swypCandidate*)candidate inputStream:(NSInputStream*)inputStream outputStream:(NSOutputStream*)outputStream;

-(void)	invalidate;

-(void)	addDataDelegate:(id<swypConnectionSessionDataDelegate>)delegate;
-(void)	removeDataDelegate:(id<swypConnectionSessionDataDelegate>)delegate;

-(void)	addConnectionSessionInfoDelegate:(id<swypConnectionSessionInfoDelegate>)delegate;
-(void)	removeConnectionSessionInfoDelegate:(id<swypConnectionSessionInfoDelegate>)delegate;

//sending data
/*
	length: the length of the 'stream' property
		if length is specified as 0, the stream will be written without a length specifier, to allow devs to do fun stuff
		be aware, some malicious endpoints will try to overload the length of a stream to cause buffer overruns 
			1) Don't rely on length parameter for buffer sizes without validity checks 2) Don't execute recieved data!
	if there is already a stream sending, this stream will be queued
*/
-(swypConcatenatedInputStream*)	beginSendingFileStreamWithTag:(NSString*)tag  type:(swypFileTypeString*)fileType dataStreamForSend:(NSInputStream*)stream length:(NSUInteger)streamLength;
/* same as above, a convinience method for those who wish to use data already in-memory */
-(swypConcatenatedInputStream*)	beginSendingDataWithTag:(NSString*)tag type:(swypFileTypeString*)type dataForSend:(NSData*)sendData; 


//
//private
-(void)	_changeStatus:	(swypConnectionSessionStatus)status;
-(void) _teardownConnection;
-(void) _setupStreamPathways;
-(void)	_handleSocketInputData;

@end
