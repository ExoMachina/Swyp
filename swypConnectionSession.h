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
#import "swypInputToDataBridge.h"

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
		Delegates should see if they're interested through discerned stream's properities like 'streamType' and 'streamTag'
		If no one handles, an exception is thrown
	
	discernedStream can be read as an input stream, and attached to output streams using SwypInputToOutput, for example
	Alternatively, 'wantsProvidedAsNSData,' the bool passed as a reference, can be set to true, *wantsProvidedAsNSData = TRUE;, to have data provided in a method bellow
*/
-(BOOL) delegateWillHandleDiscernedStream:(swypDiscernedInputStream*)discernedStream wantsAsData:(BOOL *)wantsProvidedAsNSData inConnectionSession:(swypConnectionSession*)session;
/*
	The following function is called if 'delegateWillHandleDiscernedStream' returns true and sets 'wantsProvidedAsNSData' to true.
*/

-(void)	yieldedData:(NSData*)streamData discernedStream:(swypDiscernedInputStream*)discernedStream inConnectionSession:(swypConnectionSession*)session;


-(void)	failedSendingStream:(NSInputStream*)stream error:(NSError*)error connectionSession:(swypConnectionSession*)session;;
-(void) completedSendingStream:(NSInputStream*)stream connectionSession:(swypConnectionSession*)session;
@end


@interface swypConnectionSession : NSObject <NSStreamDelegate, swypConcatenatedInputStreamDelegate, swypInputToOutputStreamConnectorDelegate, swypInputStreamDiscernerDelegate, swypInputToDataBridgeDelegate> {
	NSMutableSet *	_dataDelegates;
	NSMutableSet *	_connectionSessionInfoDelegates;
	
	UIColor *		_sessionHueColor;
	
	swypCryptoSession *		_cryptoSession;
	swypCandidate *			_representedCandidate;
	
	swypConnectionSessionStatus			_connectionStatus;
	
	swypConcatenatedInputStream *		_sendDataQueueStream;
	swypTransformPathwayInputStream *	_socketOutputTransformInputStream;	 
	swypInputToOutputStreamConnector *	_outputStreamConnector;
	
	swypTransformPathwayInputStream *	_socketInputTransformInputStream;
	swypInputStreamDiscerner *			_inputStreamDiscerner;				//splits up input data

	//for NSData-wanting delegates
	NSMutableDictionary	*				_delegatesForPendingInputBridges;
	NSMutableSet *						_pendingInputBridges;
	
	
	NSInputStream *			_socketInputStream;
	NSOutputStream *		_socketOutputStream;
}
@property (nonatomic, readonly)	swypConnectionSessionStatus	connectionStatus;
@property (nonatomic, retain)	UIColor*					sessionHueColor;
@property (nonatomic, readonly)	swypCandidate *				representedCandidate;
@property (nonatomic, retain)	swypCryptoSession *			cryptoSession;
@property (nonatomic, readonly)	swypTransformPathwayInputStream	*	socketInputTransformStream;
@property (nonatomic, readonly)	swypTransformPathwayInputStream	*	socketOutputTransformStream;

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
-(swypConcatenatedInputStream*)	beginSendingFileStreamWithTag:(NSString*)tag  type:(NSString*)fileType dataStreamForSend:(NSInputStream*)stream length:(NSUInteger)streamLength;
/* same as above, a convinience method for those who wish to use data already in-memory */
-(swypConcatenatedInputStream*)	beginSendingDataWithTag:(NSString*)tag type:(NSString*)type dataForSend:(NSData*)sendData; 


//
//private
-(void)	_changeStatus:	(swypConnectionSessionStatus)status;
-(void) _teardownConnection;
-(void) _setupStreamPathways;
@end
