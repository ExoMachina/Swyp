//
//  swypConnectionManager.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import <Foundation/Foundation.h>
#import "swypConnectionSession.h"
#import "swypHandshakeManager.h"
#import "swypInputToDataBridge.h"
#import "swypNetworkAccessMonitor.h"

#import "swypCloudPairManager.h"
#import "swypBonjourPairManager.h"
#import "swypBluetoothPairManager.h"
#import "swypInterfaceManager.h"
#import "swypPendingConnectionManager.h"


@class swypConnectionManager;

typedef enum {
	swypConnectionClassNone,			//no preferrence; automatically selected through availability 
	swypConnectionClassWifiAndCloud,
	swypConnectionClassBluetooth
} swypConnectionClass;


@protocol swypConnectionManagerDelegate <NSObject>
-(void)	swypConnectionSessionWasCreated:(swypConnectionSession*)session		withConnectionManager:(swypConnectionManager*)manager;
-(void)	swypConnectionSessionWasInvalidated:(swypConnectionSession*)session	withConnectionManager:(swypConnectionManager*)manager error:(NSError*)error;

-(void) swypConnectionMethodsUpdated:(swypConnectionMethod)availableMethods withConnectionManager:(swypConnectionManager*)manager;
@end

/**
 This guy does orchistrates the whole gig to get connections between devices established. 
 */
@interface swypConnectionManager : NSObject <swypPendingConnectionManagerDelegate, swypInterfaceManagerDelegate,
swypConnectionSessionInfoDelegate,swypConnectionSessionDataDelegate, swypHandshakeManagerDelegate,
swypNetworkAccessMonitorDelegate, swypInputToDataBridgeDelegate> {
	NSMutableSet *					_activeConnectionSessions;

	swypBonjourPairManager *		_bonjourPairManager;
	swypCloudPairManager *			_cloudPairManager;
	swypBluetoothPairManager*		_bluetoothPairManager;
	
	swypHandshakeManager *			_handshakeManager;
	
	swypPendingConnectionManager *	_pendingSwypInConnections; 

	swypConnectionMethod			_supportedConnectionMethods;	//device supported
	swypConnectionMethod			_availableConnectionMethods; //currently available per reachability
	
	swypConnectionClass				_userPreferedConnectionClass;	//NONE by default
	

	id<swypConnectionManagerDelegate>	_delegate;
}
@property (nonatomic, readonly) NSSet *								activeConnectionSessions;
@property (nonatomic, assign)	id<swypConnectionManagerDelegate>	delegate;

@property (nonatomic, readonly)	swypConnectionMethod	supportedConnectionMethods; /// device supported

@property (nonatomic, readonly)	swypConnectionMethod	availableConnectionMethods; ///currently usable per reachability
@property (nonatomic, readonly)	swypConnectionMethod	enabledConnectionMethods;	/// user or implicitly authorized methods through activeConnectionClass
@property (nonatomic, readonly)	swypConnectionMethod	activeConnectionMethods;	///intersect of enabled and available

@property (nonatomic, assign)	swypConnectionClass	userPreferedConnectionClass; ///the preferred class that the UI reflects
@property (nonatomic, readonly) swypConnectionClass	activeConnectionClass;	///on-the-fly generated connection class based on user pref & availability



/**
	Begin listening, allow new connections, etc. 

	EG: called when swyp workspace has been opened.
*/
-(void)	startServices;

/**
	Stop listening, disallow new connections, terminate existing swypConnectionSessions, etc. 
	Probably the swyp workspace, or the app has been closed.
*/
-(void)	stopServices;

-(void) swypInCompletedWithSwypInfoRef:	(swypInfoRef*)inInfo;
-(void)	swypOutStartedWithSwypInfoRef:	(swypInfoRef*)outInfo;
-(void)	swypOutCompletedWithSwypInfoRef:(swypInfoRef*)outInfo; 
-(void)	swypOutFailedWithSwypInfoRef:	(swypInfoRef*)outInfo;

-(void)dropSwypOutSwypInfoRefFromAdvertisers:(swypInfoRef*)outInfo;

-(void)updateNetworkAvailability;
//private 
-(void)_setupNetworking;
@end
