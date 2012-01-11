//
//  swypCloudNetService.h
//  swyp
//
//  Created by Alexander List on 1/4/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import <Foundation/Foundation.h>

@class swypCloudNetService;
@protocol swypCloudNetServiceDelegate <NSObject>
-(void)cloudNetService:(swypCloudNetService*)service didCreateInputStream:(NSInputStream*)inputStream outputStream:(NSOutputStream*)outputStream withPeerAtAddress:(NSString*)address socket:(NSUInteger)portNumber;
-(void)cloudNetService:(swypCloudNetService*)service didReceiveInputStream:(NSInputStream*)inputStream outputStream:(NSOutputStream*)outputStream withPeerAtAddress:(NSString*)address socket:(NSUInteger)portNumber;
-(void)cloudNetService:(swypCloudNetService*)service didFailToCreateConnectionWithPeerAtAddress:(NSString*)address socket:(NSUInteger)portNumber;
@end

@interface swypCloudNetService : NSObject{
	//sockets, etc
	
	id<swypCloudNetServiceDelegate>		_delegate;
}
-(id)initWithDelegate:(id<swypCloudNetServiceDelegate>)delegate;

-(void)beginConnectionToPeerAtAddress:(NSString*)address socket:(NSUInteger)portNumber;

/* //To Jingle
 
-(void)beginConnectionToSmppPeer:(NSString*)peer;
*/

@end
