//
//  swypConnectionSession.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- check online.
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

@class swypConnectionSession;

typedef enum {
	swypConnectionSessionStatusNotReady,
	swypConnectionSessionStatusPreparing,
	swypConnectionSessionStatusReady
} swypConnectionSessionStatus;

@protocol swypConnectionSessionDelegate <NSObject>
-(void) sessionStatusChanged:	(swypConnectionSessionStatus)status	inSession:(swypConnectionSession*)session;
-(void) sessionWillDie:			(swypConnectionSession*)session;
-(void) sessionDied:			(swypConnectionSession*)session withError:(NSError*)error;
@end

@protocol swypConnectionSessionDataDelegate <NSObject>
-(NSOutputStream*) streamToWriteReceivedDataWithTag:(NSString*)tag type:(swypFileTypeString*)type length:(NSUInteger)streamLength connectionSession:(swypConnectionSession*)session;
-(void) finishedReceivingDataWithOutputStream:(NSOutputStream*)stream error:(NSError*)error tag:(NSString*)tag type:(swypFileTypeString*)type connectionSession:(swypConnectionSession*)session;
@end


@interface swypConnectionSession : NSObject {
	NSMutableSet *	_dataDelegates;
	NSMutableSet *	_connectionSessionDelegates;
	
	UIColor *		_sessionHueColor;
	
	swypCryptoSession *		_cryptoSession;
	swypCandidate *			_swypCandidate;
	
	swypConnectionSessionStatus			_connectionStatus;
	
	swypConcatenatedInputStream *		_sendDataQueueStream;				//setCloseWhenFinished:NO 
	swypTransformPathwayInputStream *	_socketOutputTransformInputStream;	//initWithDataInputStream:_sendDataQueueStream transformStreamArray:nil 
	swypInputToOutputStreamConnector *	_outputStreamConnector;				//initWithOutputStream:_socketOutputStream readStream:_socketOutputTransformInputStream
	
	NSInputStream *			_socketInputStream;
	NSOutputStream *		_socketOutputStream;
}
@property (nonatomic, readonly)	swypConnectionSessionStatus	connectionStatus;
@property (nonatomic, retain)	UIColor*					sessionHueColor;

-(void)	addDataDelegate:(id<swypConnectionSessionDataDelegate>)delegate;
-(void)	removeDataDelegate:(id<swypConnectionSessionDataDelegate>)delegate;

-(void)	addConnectionSessionDelegate:(id<swypConnectionSessionDelegate>)delegate;
-(void)	removeConnectionSessionDelegate:(id<swypConnectionSessionDelegate>)delegate;

//sending data
/*
	length: the length of the 'stream' property
		if length is specified as 0, the entire stream will be read to memory before any of it can be written (to allow packet size conveyance)
		if length is specified as NSUIntegerMax (UIn!), the stream will be written without a length specifier, to allow devs to do fun stuff
	if there is already a stream sending, this stream will be queued
*/
-(void)	beginSendingFileStreamWithTag:(NSString*)tag  type:(swypFileTypeString*)fileType dataStreamForSend:(NSInputStream*)stream length:(NSUInteger)streamLength;
/* same as above, a convinience method for those who wish to use data already in-memory */
-(void)	beginSendingDataWithTag:(NSString*)tag type:(swypContentTypeString:NSString*)type dataForSend:(NSData*)sendData; 

@end
