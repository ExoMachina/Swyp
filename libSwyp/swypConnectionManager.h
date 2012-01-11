//
//  swypConnectionManager.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import <Foundation/Foundation.h>
#import "swypConnectionSession.h"
#import "swypBonjourServiceListener.h"
#import "swypBonjourServiceAdvertiser.h"
#import "swypHandshakeManager.h"
#import "swypInputToDataBridge.h"
#import "swypNetworkAccessMonitor.h"

#ifdef BLUETOOTH_ENABLED
#import <CoreBluetooth/CoreBluetooth.h>
#endif


@class swypConnectionManager;

typedef enum {
	swypAvailableConnectionMethodNone = 0,
	swypAvailableConnectionMethodCloudWAN = 1 << 1,
	swypAvailableConnectionMethodWifi = 1 << 2,
	swypAvailableConnectionMethodBluetooth = 1 <<3
} swypAvailableConnectionMethod;

@protocol swypConnectionManagerDelegate <NSObject>
-(void)	swypConnectionSessionWasCreated:(swypConnectionSession*)session		withConnectionManager:(swypConnectionManager*)manager;
-(void)	swypConnectionSessionWasInvalidated:(swypConnectionSession*)session	withConnectionManager:(swypConnectionManager*)manager error:(NSError*)error;

-(void) swypAvailableConnectionMethodsUpdated:(swypAvailableConnectionMethod)availableMethods withConnectionManager:(swypConnectionManager*)manager;
@end

@interface swypConnectionManager : NSObject <swypBonjourServiceListenerDelegate,swypConnectionSessionInfoDelegate,swypConnectionSessionDataDelegate, swypBonjourServiceAdvertiserDelegate, swypHandshakeManagerDelegate, swypInputToDataBridgeDelegate,swypNetworkAccessMonitorDelegate> {
	NSMutableSet *					_activeConnectionSessions;

	swypBonjourServiceListener *	_bonjourListener;
	swypBonjourServiceAdvertiser *	_bonjourAdvertiser;
	
	swypHandshakeManager *			_handshakeManager;
	
	swypAvailableConnectionMethod	_availableConnectionMethods;

#ifdef BLUETOOTH_ENABLED
	CBCentralManager *				_bluetoothManager;
#else
	id<NSObject>					_bluetoothManager;
#endif
	
	//swypInfoRefs
	NSMutableSet *			_swypIns;
	NSMutableSet *			_swypOuts;	
	NSMutableSet *			_swypOutTimeouts;
	NSMutableSet *			_swypInTimeouts;
	
	id<swypConnectionManagerDelegate>	_delegate;
}
@property (nonatomic, readonly) NSSet *								activeConnectionSessions;
@property (nonatomic, assign)	id<swypConnectionManagerDelegate>	delegate;

@property (nonatomic, readonly)	swypAvailableConnectionMethod	availableConnectionMethods;



/*
	Begin listening, allow new connections, etc. 
	The swyp window has been opened.
*/
-(void)	startServices;
/*
	Stop listening, disallow new connections, terminate existing swypConnectionSessions, etc. 
	The swyp window has probably been closed.
*/
-(void)	stopServices;

-(swypInfoRef*)	oldestSwypInSet:(NSSet*)swypSet;

-(void) swypInCompletedWithSwypInfoRef:	(swypInfoRef*)inInfo;
-(void)	swypOutStartedWithSwypInfoRef:	(swypInfoRef*)outInfo;
-(void)	swypOutCompletedWithSwypInfoRef:(swypInfoRef*)outInfo; 
-(void)	swypOutFailedWithSwypInfoRef:	(swypInfoRef*)outInfo;


-(void)updateNetworkAvailability;
//private 
-(void)_updateBluetoothAvailability;
@end
