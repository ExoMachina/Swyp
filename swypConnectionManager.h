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

@class swypConnectionManager;

@protocol swypConnectionManagerDelegate <NSObject>
-(void)	swypConnectionSessionWasCreated:(swypConnectionSession*)session		withConnectionManager:(swypConnectionManager*)manager;
-(void)	swypConnectionSessionWasInvalidated:(swypConnectionSession*)session	withConnectionManager:(swypConnectionManager*)manager error:(NSError*)error;
@end


@interface swypConnectionManager : NSObject <swypBonjourServiceListenerDelegate,swypConnectionSessionInfoDelegate,swypConnectionSessionDataDelegate, swypBonjourServiceAdvertiserDelegate, swypHandshakeManagerDelegate, swypInputToDataBridgeDelegate> {
	NSMutableSet *					_activeConnectionSessions;

	swypBonjourServiceListener *	_bonjourListener;
	swypBonjourServiceAdvertiser *	_bonjourAdvertiser;
	
	swypHandshakeManager *			_handshakeManager;
	
	//swypInfoRefs
	NSMutableSet *			_swypIns;
	NSMutableSet *			_swypOuts;	
	NSMutableSet *			_swypOutTimeouts;
	NSMutableSet *			_swypInTimeouts;
	
	id<swypConnectionManagerDelegate>	_delegate;
}
@property (nonatomic, readonly) NSSet *								activeConnectionSessions;
@property (nonatomic, assign)	id<swypConnectionManagerDelegate>	delegate;


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
@end
