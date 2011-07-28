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

@class swypConnectionManagerDelegate;

@protocol swypConnectionManagerDelegate <NSObject>
-(void)	swypConnectionSessionWasCreated:(swypConnectionSession*)session		withConnectionManager:(swypConnectionManager*)manager;
-(void)	swypConnectionSessionWasInvalidated:(swypConnectionSession*)session	withConnectionManager:(swypConnectionManager*)manager error:(NSError*)error;
@end


@interface swypConnectionManager : NSObject <swypBonjourServiceListenerDelegate, swypBonjourServiceAdvertiserDelegate, swypHandshakeManagerDelegate> {
	NSMutableSet *					_activeConnectionSessions;

	swypBonjourServiceListener *	_bonjourListener;
	swypBonjourServiceAdvertiser *	_bonjourAdvertiser;
	
	swypHandshakeManager *			_handshakeManager;
	
	//swypInfoRefs
	NSMutableSet *			_swypIns;
	NSMutableSet *			_swypOuts;	
	
	
	id<swypConnectionManagerDelegate>	_delegate;
}
@property (nonatomic, readonly) NSSet *								activeConnectionSessions;
@property (nonatomic, assign)	id<swypConnectionManagerDelegate>	delegate;


@end
