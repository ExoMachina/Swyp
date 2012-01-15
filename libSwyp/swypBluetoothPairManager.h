//
//  swypBluetoothPairManager.h
//  swyp
//
//  Created by Alexander List on 1/14/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "swypInfoRef.h"
#import "swypInterfaceManager.h"
#import <GameKit/GameKit.h>

@interface swypBluetoothPairManager : NSObject <swypInterfaceManager,
GKSessionDelegate>{
	id<swypInterfaceManagerDelegate>	_delegate;
		
	NSMutableDictionary *				_swypOutTimeoutTimerBySwypInfoRef;
	NSMutableSet		*				_validSwypOutsForConnectionReceipt;
	
	NSMutableDictionary *				_swypInTimeoutTimerBySwypInfoRef;
	NSMutableSet		*				_validSwypInForConnectionCreation;

	
	//game kit
	GKSession *		_gameKitPeerSession;
	NSMutableSet *	_pendingGKPeerServerConnections;
	NSMutableSet *	_pendingGKPeerClientConnections;

}

//private
-(void)	_updateInterfaceActivity;
@end
