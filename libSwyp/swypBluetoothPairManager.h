//
//  swypBluetoothPairManager.h
//  swyp
//
//  Created by Alexander List on 1/14/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "swypInfoRef.h"
#import "swypInterfaceManager.h"
#import "swypGKPeerAbstractedStreamSet.h"

@interface swypBluetoothPairManager : NSObject <swypInterfaceManager,GKSessionDelegate, GKPeerPickerControllerDelegate, swypGKPeerAbstractedStreamSetDelegate>{
	id<swypInterfaceManagerDelegate>	_delegate;
		
	NSMutableDictionary *				_swypOutTimeoutTimerBySwypInfoRef;
	NSMutableSet		*				_validSwypOutsForConnectionReceipt;
	
	NSMutableDictionary *				_swypInTimeoutTimerBySwypInfoRef;
	NSMutableSet		*				_validSwypInForConnectionCreation;
	
	
	BOOL								_bluetoothEnabled;
	BOOL								_interfaceReady;
	
	//game kit
	GKSession *				_gameKitPeerSession;	

	NSMutableDictionary *	_activeAbstractedStreamSetsByPeerName;
	
	NSTimer	*				_connectabilityTimer; //timer to see if BT is enabled...
	GKPeerPickerController*	_bluetoothPromptController;
	
}
///when paired by peer; defined in swypInterfaceManager
@property (nonatomic, readonly) BOOL interfaceReady;

//private
-(void) _createSessionsIfNeeded;
-(void) _restartBluetooth;

-(void)	_launchBluetoothPromptPeerPicker;
-(BOOL)_peerIsInConnection:(NSString*)peerID;
@end
