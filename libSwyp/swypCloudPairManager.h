//
//  swypCloudPairManager.h
//  swyp
//
//  Created by Alexander List on 1/4/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

//this class organizes the communications and connections resulting from swypOuts mediated by cloud on WAN

#import <Foundation/Foundation.h>
#import "swypInfoRef.h"
#import "swypCloudNetService.h"
#import "swypPairServerInteractionManger.h"
#import "swypInterfaceManager.h"

/** swypCloudPairManager is a swypInterfaceManager protocol conforming class that handles the swyp cloud interaction. */
@interface swypCloudPairManager : NSObject <swypInterfaceManager, 
	swypCloudNetServiceDelegate, swypPairServerInteractionMangerDelegate>{
		
	swypCloudNetService*			_cloudService;
	swypPairServerInteractionManger*_pairServerManager;
	
	id<swypInterfaceManagerDelegate> _delegate;
	
	NSMutableDictionary	*			_swypTokenBySwypRef;	//stored when swypToken given for swyp
	NSMutableDictionary *			_swypRefByPeerInfo;		//stored when peer retreived from cloud
	
	NSMutableSet *					_cloudPairPendingSwypRefs; //stored before cloud access, removed afterwards
		
	//this stores the set of swypIns that are necessary for a client's connection to the server
	NSMutableSet *					_pendingSwypIns;
}
@property (nonatomic, readonly)	swypCloudNetService*				cloudService;
@property (nonatomic, readonly)	swypPairServerInteractionManger*pairServerManager;
@property (nonatomic, assign)	id<swypInterfaceManagerDelegate> delegate;


//private
-(NSDictionary*)_userInfoDictionary;
-(void)	_invalidateSwypRef:(swypInfoRef*)swyp;

@end
