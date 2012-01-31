//
//  swypConnectionSession.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import <Foundation/Foundation.h>
#import "swypCandidate.h"
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

///Defines the various connectionStatus states the swypConnectionSession can be in. 
typedef enum {
	///The connection is closed. No data may be sent.
	swypConnectionSessionStatusClosed = -1,
	///The connection is going down.
	swypConnectionSessionStatusWillDie,
	///Indicates that a swypConnectionSession is currently opening via the 'initiate' function
	swypConnectionSessionStatusPreparing,
	///Indicates that a connection is ready for transfers; commonly used by swypHandshakeManager for handshaking connecition, so don't expect a sessionStatusChanged with it. 
	swypConnectionSessionStatusReady
} swypConnectionSessionStatus;

///The protocol for deleages of the swypConnectionSession, which wish to hear about connectivity updates from the session. See addInfoDelegate: of swypConnectionSession.
@protocol swypConnectionSessionInfoDelegate <NSObject>
///Alerts that the session is over. Error is commonly nil because we r lazy.
-(void) sessionDied:			(swypConnectionSession*)session withError:(NSError*)error;

@optional
///Alerts that the session will be dying VERY soon. IE, even including this runlooop.
-(void) sessionWillDie:			(swypConnectionSession*)session;
///Alerts that the status of the connection session changed. Perhaps it's swypConnectionSessionStatusReady
-(void) sessionStatusChanged:	(swypConnectionSessionStatus)status	inSession:(swypConnectionSession*)session;
@end

///How a swypConnectionSession gives away its received data. See addDataDelegate: of swypConnectionSession.
@protocol swypConnectionSessionDataDelegate <NSObject>
@optional

/** swypFileTypeStrings in order of preference where 0 = most preferent
	Use this on your datasource set in swypContentInteractionManager to choose what files your app accepts.
*/
-(NSArray*)	supportedFileTypesForReceipt;


/** A convenience method for delegateWillHandleDiscernedStream:wantsAsData:inConnectionSession:. Return true to accept the enclosed discernedStream as NSData through yieldedData:discernedStream:inConnectionSession: when it's done being received. 
 
 @warning if you want to do anything special with NSStream functionality, don't implement this method on your datasource. 
 
 @param streamType is a shortcut for discernedStream.streamType
 
Though there are several data delegates, only one delegate should handle and return TRUE, all else returning false
Delegates should see if they're interested through discerned stream's properities like 'streamType' and 'streamTag'
If no one handles, an exception is thrown
 
 @return true or false depending on interest in stream. 
 */
-(BOOL) delegateWillReceiveDataFromDiscernedStream:(swypDiscernedInputStream*)discernedStream ofType:(NSString*)streamType inConnectionSession:(swypConnectionSession*)session;

/** See whether delegate will handle data stream.
 
	Though there are several data delegates, only one delegate should handle and return TRUE, all else returning false
		Delegates should see if they're interested through discerned stream's properities like 'streamType' and 'streamTag'
		If no one handles, an exception is thrown
	
	All delegates will be notified using this method, but only one should return TRUE.
	
	discernedStream can be read as an input stream, and attached to output streams using SwypInputToOutput, for example
	Alternatively, 'wantsProvidedAsNSData,' the bool passed as a reference, can be set to true, '*wantsProvidedAsNSData = TRUE;', to have data provided by yieldedData:discernedStream:inConnectionSession:

*/
-(BOOL) delegateWillHandleDiscernedStream:(swypDiscernedInputStream*)discernedStream wantsAsData:(BOOL *)wantsProvidedAsNSData inConnectionSession:(swypConnectionSession*)session;


/**
	The following function is called if 'delegateWillHandleDiscernedStream' returns true and sets 'wantsProvidedAsNSData' to true.
	
	@param discernedStream the stream containing properties like streamType, and streamTag.
	@param streamData Data from the discernedStream.
*/

-(void)	yieldedData:(NSData*)streamData discernedStream:(swypDiscernedInputStream*)discernedStream inConnectionSession:(swypConnectionSession*)session;

/** Upon failing to send data */
-(void)	failedSendingStream:(NSInputStream*)stream error:(NSError*)error connectionSession:(swypConnectionSession*)session;;
/** Upon happily sending data */
-(void) completedSendingStream:(NSInputStream*)stream connectionSession:(swypConnectionSession*)session;


///	Will notify you when the data IN stream is receiving so that UI can be updated accordingly
-(void)	didBeginReceivingDataInConnectionSession:(swypConnectionSession*)session;
///	Will notify you when the data IN stream is DONE receiving so that UI can be updated accordingly
-(void) didFinnishReceivingDataInConnectionSession:(swypConnectionSession*)session;
@end

/** This class represents and manages the connection between this and one other device. 
 
 Use this class to send data, and set data delegates for recieved data. */
@interface swypConnectionSession : NSObject <NSStreamDelegate, swypConcatenatedInputStreamDelegate, swypInputToOutputStreamConnectorDelegate, swypInputStreamDiscernerDelegate, swypInputToDataBridgeDelegate> {
	NSMutableSet *	_dataDelegates;
	NSMutableSet *	_connectionSessionInfoDelegates;
	
	UIColor *		_sessionHueColor;
	
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

///The connection status property contains the current session's state w/ a swypConnectionSessionStatus value.
@property (nonatomic, readonly)	swypConnectionSessionStatus	connectionStatus;
///The hue of swyp workspace background and connection indicators, proving that you're connected to the appropiate individual.
@property (nonatomic, retain)	UIColor*					sessionHueColor;
///The remote candidate that you're communicating with through this connectionSession.
@property (nonatomic, readonly)	swypCandidate *				representedCandidate;

/** swypConnectionSessions are initialized with their candidate, and input and an output stream. 
 
 Connections are opened with the 'inititate' function.
 */
-(id)	initWithSwypCandidate:	(swypCandidate*)candidate inputStream:(NSInputStream*)inputStream outputStream:(NSOutputStream*)outputStream;

/** Start connection; schedule in runloop */
-(void) initiate;
/** Destroy connection; remove from runloop */
-(void)	invalidate;

///For adding a swypConnectionSessionDataDelegate.
-(void)	addDataDelegate:(id<swypConnectionSessionDataDelegate>)delegate;
///For removing a swypConnectionSessionDataDelegate.
-(void)	removeDataDelegate:(id<swypConnectionSessionDataDelegate>)delegate;

///For adding a swypConnectionSessionInfoDelegate.
-(void)	addConnectionSessionInfoDelegate:(id<swypConnectionSessionInfoDelegate>)delegate;
///For removing a swypConnectionSessionInfoDelegate.
-(void)	removeConnectionSessionInfoDelegate:(id<swypConnectionSessionInfoDelegate>)delegate;

/** @name sending data */
/**
	@param length the length of the 'stream' property
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
-(void) _destroyConnectionWithError:(NSError*)error;
@end
