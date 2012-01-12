//
//  swypPairServerInteractionManger.h
//  swyp
//
//  Created by Alexander List on 1/5/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

//this class handles the talking to the cloud swyp pair server

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

@class swypPairServerInteractionManger;
@protocol swypPairServerInteractionMangerDelegate <NSObject>
//swyp adds, updates or status updates return this method when successful 
-(void)swypPairServerInteractionManger:(swypPairServerInteractionManger*)manager didReturnSwypToken:(NSString*)token forSwypRef:(swypInfoRef*)swyp withPeerInfo:(NSDictionary*)peerInfo;

//any failure to reach the server, any "failed" swyp status response, or any failure on the server returns the following
-(void)swypPairServerInteractionManger:(swypPairServerInteractionManger*)manager didFailToGetSwypInfoForSwypRef:(swypInfoRef*)swyp orSwypToken:(NSString*)token;
@end

@interface swypPairServerInteractionManger : NSObject{
	AFHTTPClient *					_httpRequestManager;

}
@property (nonatomic, readonly)	AFHTTPClient *					httpRequestManager;
@property (nonatomic, assign)	id<swypPairServerInteractionMangerDelegate>	delegate;

-(id) initWithDelegate:(id<swypPairServerInteractionMangerDelegate>)delegate;

/*
//user info includes:
	"port"		: local listening port
	"publicKey"	: local public key
	"longitude"	: best guest at current longitude 
	"latitude"	: best guest at current latituted
*/
-(void)postSwypToPairServer:(swypInfoRef*)swyp withUserInfo:(NSDictionary*)contextInfo;
-(void)putSwypUpdateToPairServer:(swypInfoRef*)swyp swypToken:(NSString*)token withUserInfo:(NSDictionary*)contextInfo;
-(void)deleteSwypFromPairServer:(swypInfoRef*)swyp swypToken:(NSString*)token;
-(void)updateSwypPairStatus:(swypInfoRef*)swyp swypToken:(NSString*)token;

//private process
-(void)_processSwypPairResponse:(id)response swypRef:(swypInfoRef*)swyp;
-(void)_processSwypPairConnectionFailureWithResponse:(id)response error:(NSError*)error swypRef:(swypInfoRef*)swyp;
@end
