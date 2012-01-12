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


@class swypCloudPairManager;
@protocol swypCloudPairManagerDelegate <NSObject>
-(void)swypCloudPairManager:(swypCloudPairManager*)manager didReceiveSwypConnectionFromClient:(swypClientCandidate*)clientCandidate withStreamIn:(NSInputStream*)inputStream streamOut:(NSOutputStream*)outputStream;
-(void)swypCloudPairManager:(swypCloudPairManager*)manager didCreateSwypConnectionToServer:(swypServerCandidate*)serverCandidate withStreamIn:(NSInputStream*)inputStream streamOut:(NSOutputStream*)outputStream;
@end

@interface swypCloudPairManager : NSObject <swypCloudNetServiceDelegate, swypPairServerInteractionMangerDelegate>{
	swypCloudNetService*			_cloudService;
	swypPairServerInteractionManger*_pairServerManager;
	
	id<swypCloudPairManagerDelegate> _delegate;
	
	NSMutableDictionary	*			_swypTokenBySwypRef;	//stored when swypToken given for swyp
	NSMutableDictionary *			_swypRefByPeerInfo;		//stored when peer retreived from cloud
	
	NSMutableSet *					_cloudPairPendingSwypRefs; //stored before cloud access, removed afterwards
}
@property (nonatomic, readonly)	swypCloudNetService*			cloudService;
@property (nonatomic, readonly)	swypPairServerInteractionManger*pairServerManager;
@property (nonatomic, assign)	id<swypCloudPairManagerDelegate> delegate;


-(id)initWithSwypCloudPairManagerDelegate:(id<swypCloudPairManagerDelegate>) delegate;

-(void)swypOutBegan:	(swypInfoRef*)swyp;
-(void)swypOutCompleted:(swypInfoRef*)swyp;
-(void)swypOutFailed:	(swypInfoRef*)swyp;

-(void)swypInCompleted:	(swypInfoRef*)swyp;

-(void)	suspendNetworkActivity;
-(void)	resumeNetworkActivity;

//private
-(NSDictionary*)_userInfoDictionary;
-(void)	_invalidateSwypRef:(swypInfoRef*)swyp;

@end
