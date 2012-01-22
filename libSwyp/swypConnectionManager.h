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
	///no preferrence; automatically selected through availability 
	swypConnectionClassNone,			
	swypConnectionClassWifiAndCloud,
	swypConnectionClassBluetooth
} swypConnectionClass;


///protocol between swypConnectionManager to swypWorkspaceViewController
@protocol swypConnectionManagerDelegate <NSObject>
///Session was created, please handle display
-(void)	swypConnectionSessionWasCreated:(swypConnectionSession*)session		withConnectionManager:(swypConnectionManager*)manager;
///Session was invalidated, please remove
-(void)	swypConnectionSessionWasInvalidated:(swypConnectionSession*)session	withConnectionManager:(swypConnectionManager*)manager error:(NSError*)error;

/**
 An update letting the swypWorkspaceViewController know that available connection methods have changed.
 */
-(void) swypConnectionMethodsUpdated:(swypConnectionMethod)availableMethods withConnectionManager:(swypConnectionManager*)manager;

/** 
 This lets swypWorkspaceViewController know that an interface is on or offline so it can adjust its UI accordingly.
 */
-(void) swypConnectionMethod:(swypConnectionMethod)method setReadyStatus:(BOOL)isReady withConnectionManager:(swypConnectionManager*)manager;


@end

/**
 This class orchistrates the establishment of connections between devices. 
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

/// device supported
@property (nonatomic, readonly)	swypConnectionMethod	supportedConnectionMethods; 

///currently usable per reachability
@property (nonatomic, readonly)	swypConnectionMethod	availableConnectionMethods; 

/// user or implicitly authorized methods through activeConnectionClass
@property (nonatomic, readonly)	swypConnectionMethod	enabledConnectionMethods;	
///intersect of enabled and available
@property (nonatomic, readonly)	swypConnectionMethod	activeConnectionMethods;	

///the preferred class that the UI reflects
@property (nonatomic, assign)	swypConnectionClass	userPreferedConnectionClass; 

///on-the-fly generated connection class based on user pref & availability; IE, the one you usin'
@property (nonatomic, readonly) swypConnectionClass	activeConnectionClass;	



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
-(void)_activeConnectionInterfacesChanged;
@end
