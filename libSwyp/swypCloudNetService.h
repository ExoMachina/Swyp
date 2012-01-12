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

//returned peer info in this case will be the same as that which is sent by 'beginConnectionToPeerWithInfo:'
-(void)cloudNetService:(swypCloudNetService*)service didCreateInputStream:(NSInputStream*)inputStream outputStream:(NSOutputStream*)outputStream withPeerFromInfo:(NSDictionary*)peerInfo;

/*
 In this circumstance peerinfo could either be:
 
	//in the case of xmpp, where the user is guaranteed to exact
		the same as that which is sent by 'beginConnectionToPeerWithInfo:'
	
	//in the case of standard IP
	//when no connections have been added
		a new peer info dict containing the 'standard fare' of available information about the peer
		this dict may or may not be value-wise identical, but it will be a seperate object from any prexeisting dict
		
*/
-(void)cloudNetService:(swypCloudNetService*)service didReceiveInputStream:(NSInputStream*)inputStream outputStream:(NSOutputStream*)outputStream withPeerFromInfo:(NSDictionary*)peerInfo;
-(void)cloudNetService:(swypCloudNetService*)service didFailToCreateConnectionWithPeerFromInfo:(NSDictionary*)peerInfo;
@end

@interface swypCloudNetService : NSObject{
	CFSocketRef _ipv4socket;
	CFSocketRef _ipv6socket;
	
	id<swypCloudNetServiceDelegate>		_delegate;
}
@property (nonatomic, assign)	id<swypCloudNetServiceDelegate>	delegate; 
@property (nonatomic, readonly)	NSUInteger	portNumber;

@property (nonatomic, readonly)	CFSocketRef ipv4socket;
@property (nonatomic, readonly)	CFSocketRef ipv6socket;

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

//	stops advertising and disables sockets
//		for when device is going to sleep
-(void)	suspendNetworkActivity;

//	re-enables sockets for resuming active
-(void)	resumeNetworkActivity;

//
//private socket stuff
-(void) _setupServerSockets;
-(void) _teardownServerSockets;

-(void) _connectToServerWithIP:(NSString*)ip port:(NSUInteger)port info:(NSDictionary*)peerInfo;

static void _swypServerAcceptConnectionCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info); //CFSocketCallBack	



@end
