//
//  swypConnectionManager.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- check online.
//

#import <Foundation/Foundation.h>
#import "swypConnectionSession.h"
#import "swypBonjourServiceListener.h"
#import "swypBonjourServiceAdvertiser.h"

@class swypConnectionManagerDelegate;

@protocol swypConnectionManagerDelegate <NSObject>

@end


@interface swypConnectionManager : NSObject <swypBonjourServiceListenerDelegate, swypBonjourServiceAdvertiserDelegate> {
	NSMutableSet *					_activeConnectionSessions;

	swypBonjourServiceListener *	_bonjourListener;
	swypBonjourServiceAdvertiser *	_bonjourAdvertiser;
	
	//swypInfoRefs
	NSMutableSet *			_swypIns;
	NSMutableSet *			_swypOuts;	
	
	
	id<swypConnectionManagerDelegate>	_delegate;
}
@property (nonatomic, readonly) NSSet *								activeConnectionSessions;
@property (nonatomic, assign)	id<swypConnectionManagerDelegate>	delegate;


@end
