//
//  swypBonjourServiceAdvertiser.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import <Foundation/Foundation.h>
#import "swypClientCandidate.h"


static NSString * const swypBonjourServiceAdvertiserErrorDomain;

typedef enum {
	swypBonjourServiceAdvertiserNoSocketsAvailableError,
	swypBonjourServiceAdvertiserCouldNotBindToIPv4AddressError,
	swypBonjourServiceAdvertiserCouldNotBindToIPv6AddressError
}swypBonjourServiceAdvertiserError;

@class swypBonjourServiceAdvertiser;

@protocol swypBonjourServiceAdvertiserDelegate <NSObject>
-(void)	bonjourServiceAdvertiserReceivedConnectionFromSwypClientCandidate:(swypClientCandidate*)clientCandidate withStreamIn:(NSInputStream*)inputStream streamOut:(NSOutputStream*)outputStream; 
@end


@interface swypBonjourServiceAdvertiser : NSObject <NSNetServiceDelegate>  {

	CFSocketRef _ipv4socket;
	CFSocketRef _ipv6socket;
	
	id<swypBonjourServiceAdvertiserDelegate>	_delegate;
}
@property (nonatomic, assign) id<swypBonjourServiceAdvertiserDelegate>	delegate;

-(BOOL)	isAdvertising;
-(void)	setAdvertising:(BOOL)advertisingEnabled;


//
//private
-(void)	_setupBonjourAdvertising;
-(void) _teardownBonjourAdvertising;
-(void) _setupServerSockets;
-(void) _teardownServerSockets;


//CFSocketCallBack
static void _swypServerAcceptConnectionCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);

@end
