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
#import "swypCloudPairManager.h"


@class swypConnectionManager;

typedef enum {
	swypConnectionMethodNone = 0,
	swypConnectionMethodWifiLoc		= 1 << 1,
	swypConnectionMethodWifiCloud	= 1 << 2,
	swypConnectionMethodWWANCloud	= 1 << 3,
	swypConnectionMethodBluetooth	= 1 << 4
} swypConnectionMethod;

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

@interface swypConnectionManager : NSObject 
<swypBonjourServiceListenerDelegate, swypBonjourServiceAdvertiserDelegate, swypCloudPairManagerDelegate,
swypConnectionSessionInfoDelegate,swypConnectionSessionDataDelegate, swypHandshakeManagerDelegate,
swypNetworkAccessMonitorDelegate, swypInputToDataBridgeDelegate> {
	NSMutableSet *					_activeConnectionSessions;

	swypBonjourServiceListener *	_bonjourListener;
	swypBonjourServiceAdvertiser *	_bonjourAdvertiser;
	
	swypCloudPairManager *			_cloudPairManager;
	swypHandshakeManager *			_handshakeManager;
	

	swypConnectionMethod			_supportedConnectionMethods;	//device supported
	swypConnectionMethod			_availableConnectionMethods;	//currently usable per reachability
	
	swypConnectionClass				_userPreferedConnectionClass;	//NONE by default
	swypConnectionClass				_activeConnectionClass;			//wifi&cloud by default
	
	//swypInfoRefs
	NSMutableSet *			_swypIns;
	NSMutableSet *			_swypOuts;	
	NSMutableSet *			_swypOutTimeouts;
	NSMutableSet *			_swypInTimeouts;
	
	id<swypConnectionManagerDelegate>	_delegate;
}
@property (nonatomic, readonly) NSSet *								activeConnectionSessions;
@property (nonatomic, assign)	id<swypConnectionManagerDelegate>	delegate;

@property (nonatomic, readonly)	swypConnectionMethod	availableConnectionMethods;
@property (nonatomic, readonly)	swypConnectionMethod	enabledConnectionMethods;	//user/implicitly authorized
@property (nonatomic, readonly)	swypConnectionMethod	activeConnectionMethods;	//intersect of enabled and available

@property (nonatomic, readonly) swypConnectionClass		userPreferedConnectionClass;
@property (nonatomic, readonly) swypConnectionClass		activeConnectionClass;



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
-(void)_setupNetworking;
@end
