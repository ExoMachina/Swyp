//
//  swypCloudNetService.h
//  swyp
//
//  Created by Alexander List on 1/4/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

//this class handles the connecting to and serving of connections for cloud-based peers
//it makes abstracts away the addresses and ports, and just takes an endpoint, and returns a stream pair

#import <Foundation/Foundation.h>

@class swypCloudNetService;
@protocol swypCloudNetServiceDelegate <NSObject>
-(void)cloudNetService:(swypCloudNetService*)service didCreateInputStream:(NSInputStream*)inputStream outputStream:(NSOutputStream*)outputStream withPeerFromInfo:(NSDictionary*)peerInfo;
-(void)cloudNetService:(swypCloudNetService*)service didReceiveInputStream:(NSInputStream*)inputStream outputStream:(NSOutputStream*)outputStream withPeerFromInfo:(NSDictionary*)peerInfo;
-(void)cloudNetService:(swypCloudNetService*)service didFailToCreateConnectionWithPeerFromInfo:(NSDictionary*)peerInfo;
@end

@interface swypCloudNetService : NSObject{
	//sockets, etc
	
	id<swypCloudNetServiceDelegate>		_delegate;
}
@property (nonatomic, assign)	id<swypCloudNetServiceDelegate>	delegate; 
@property (nonatomic, readonly)	NSInteger portNumber;

-(id)initWithDelegate:(id<swypCloudNetServiceDelegate>)delegate;

/*
//peer info includes the following
 "port"		: remote listening port
 "address"	: remote ip address
 "publicKey": peer's public key
//To Jingle
 "smppPeer"	: peer's username
*/
-(void)beginConnectionToPeerWithInfo:(NSDictionary*)peerInfo;


@end
