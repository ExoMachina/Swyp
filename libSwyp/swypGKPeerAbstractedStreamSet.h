//
//  swypGKPeerAbstractedStreamSet.h
//  swyp
//
//  Created by Alexander List on 1/15/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "swypConcatenatedInputStream.h"
#import "swypOutputToDataStream.h"

@class swypGKPeerAbstractedStreamSet;

/** The delegate protocol basically is intended to allow all actual peer sending to be done by the GKSession. swypBluetoothPairManager holds all all of these objects and the GKSession. */
@protocol swypGKPeerAbstractedStreamSetDelegate <NSObject>
///Gotta send data somehow.
-(void)	peerAbstractedStreamSet:(swypGKPeerAbstractedStreamSet*)peerAbstraction wantsDataSent:(NSData*)sendData toPeerNamed:(NSString*)peerName;
///Need to notify 
-(void)	peerAbstractedStreamSetDidClose:(swypGKPeerAbstractedStreamSet*)peerAbstraction withPeerNamed:(NSString*)peerName;
@end

/** The purpose of this class is to encapsulate an input and output stream for a gamekit peer while forwarding all data through one delegate. */
@interface swypGKPeerAbstractedStreamSet : NSObject <swypConcatenatedInputStreamDelegate, swypOutputToDataStreamDataDelegate>{
	id<swypGKPeerAbstractedStreamSetDelegate>	_delegate;
	
	swypConcatenatedInputStream *	_peerReadStream;
	swypOutputToDataStream *		_peerWriteStream;
	NSString *						_peerName;
}
@property (nonatomic, readonly)	NSInputStream *		peerReadStream;
@property (nonatomic, readonly)	NSOutputStream *	peerWriteStream;
@property (nonatomic, readonly) NSString *			peerName;
@property (nonatomic, assign)	id<swypGKPeerAbstractedStreamSetDelegate>	delegate;

/** Main init function.
 After init, both peerReadStream and peerWriteStream will be available for use.
 @param peerName is unique from GKSession
 @param delegate is manditory swypGKPeerAbstractedStreamSetDelegate
*/
-(id)initWithPeerName:(NSString*)peerName streamSetDelegate:(id<swypGKPeerAbstractedStreamSetDelegate>)delegate;

///Add data to peerReadStream as acquired from GKSession
-(void) addDataToPeerReadStream:(NSData*)addedData;

///Invalidates both streams, notifies delegate with peerAbstractedStreamSetDidClose:withPeerNamed:
-(void) invalidateStreamSet;

///Invalidates both streams, without notifying delegate;
-(void) invalidateFromManager;

@end
