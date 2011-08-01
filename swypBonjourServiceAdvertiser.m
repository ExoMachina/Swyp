//
//  swypBonjourServiceAdvertiser.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import "swypBonjourServiceAdvertiser.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#import <arpa/inet.h>
#include <CFNetwork/CFSocketStream.h>


static NSString * const swypBonjourServiceAdvertiserErrorDomain = @"swypBonjourServiceAdvertiserErrorDomain";

@implementation swypBonjourServiceAdvertiser
@synthesize delegate = _delegate;

#pragma mark -
#pragma mark public
-(BOOL)	isAdvertising{
	
	return FALSE;
}
-(void)	setAdvertising:(BOOL)advertisingEnabled{
	
}


#pragma mark NSObject


#pragma mark -
#pragma mark private
-(void)	_setupBonjourAdvertising{
	
	if (_ipv4socket != NULL){
		uint16_t chosenV4Port = 0;
		struct sockaddr_in v4ServerAddress;
		NSData * v4Addr = [(NSData *)CFSocketCopyAddress(_ipv4socket) autorelease];
		memcpy(&v4ServerAddress, [v4Addr bytes], [v4Addr length]);
		chosenV4Port = ntohs(v4ServerAddress.sin_port); 
		EXOLog(@"Setting up advertising on v4 with port: %i",chosenV4Port);
		
		
	}
	
	if (_ipv6socket != NULL){
		uint16_t chosenV6Port = 0;
		struct sockaddr_in6 v6ServerAddress;	
		NSData * v6Addr = [(NSData *)CFSocketCopyAddress(_ipv6socket) autorelease];
		memcpy(&v6ServerAddress, [v6Addr bytes], [v6Addr length]);
		chosenV6Port = ntohs(v6ServerAddress.sin6_port);
		EXOLog(@"Setting up advertising on v6 with port: %i",chosenV6Port);
		
		NSNetService * v6AdvertiserService	= [[NSNetService alloc] initWithDomain:@"" type:@"_swyp._tcp." name:[[UIDevice currentDevice] name] port:chosenV6Port];
	}
	
}
-(void) _teardownBonjourAdvertising{
	
}
-(void) _setupServerSockets{	
	if (_ipv4socket != NULL){
		EXOLog(@"Socket already running for v4!");
	}else {
		struct sockaddr_in v4ServerAddress;
		socklen_t nameLen = 0;
		nameLen = sizeof(v4ServerAddress);		
		
		CFSocketContext socketCtxt = {0, self, NULL, NULL, NULL};
		_ipv4socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, (CFSocketCallBack)&_swypServerAcceptConnectionCallBack, &socketCtxt);
		
		if (!_ipv4socket) {
			NSError * error = [NSError errorWithDomain:swypBonjourServiceAdvertiserErrorDomain code:swypBonjourServiceAdvertiserNoSocketsAvailableError userInfo:nil];
			EXOLog(@"No sockets in ipv4 %@", [error description]); //would this occur for v6 too?
		}
		
		int yes = 1;
		setsockopt(CFSocketGetNative(_ipv4socket), SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes));
		
		// set up the IPv4 endpoint; use port 0, so the kernel will choose an arbitrary port for us, which will be advertised using Bonjour
		memset(&v4ServerAddress, 0, sizeof(v4ServerAddress));
		v4ServerAddress.sin_len = nameLen;
		v4ServerAddress.sin_family = AF_INET;
		v4ServerAddress.sin_port = 0;
		v4ServerAddress.sin_addr.s_addr = htonl(INADDR_ANY);
		NSData * address4 = [NSData dataWithBytes:&v4ServerAddress length:nameLen];
		
		if (kCFSocketSuccess != CFSocketSetAddress(_ipv4socket, (CFDataRef)address4)) {
			NSError *error = [[NSError alloc] initWithDomain:swypBonjourServiceAdvertiserErrorDomain code:swypBonjourServiceAdvertiserCouldNotBindToIPv4AddressError userInfo:nil];
			EXOLog(@"Could not bind to ipv4 socket %@", [error description]); 
			
			if (_ipv4socket) 
				CFRelease(_ipv4socket);

			_ipv4socket = NULL;
		}
				
		// set up the run loop sources for the sockets
		CFRunLoopRef cfrl = CFRunLoopGetCurrent();
		CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _ipv4socket, 0);
		CFRunLoopAddSource(cfrl, source, kCFRunLoopCommonModes);
		CFRelease(source);
		
	}
	
	if (_ipv6socket != NULL){
		EXOLog(@"Socket already running for v6!");
	}else {
		struct sockaddr_in6 v6ServerAddress;
		socklen_t nameLen = 0;
		nameLen = sizeof(v6ServerAddress);		
		
		CFSocketContext socketCtxt = {0, self, NULL, NULL, NULL};
		_ipv6socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, (CFSocketCallBack)&_swypServerAcceptConnectionCallBack, &socketCtxt);
		
		if (!_ipv6socket) {
			NSError * error = [NSError errorWithDomain:swypBonjourServiceAdvertiserErrorDomain code:swypBonjourServiceAdvertiserNoSocketsAvailableError userInfo:nil];
			EXOLog(@"No sockets in ipv6 %@", [error description]); //would this occur for v6 too?
		}
		
		int yes = 1;
		setsockopt(CFSocketGetNative(_ipv6socket), SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes));
		
		// set up the IPv4 endpoint; use port 0, so the kernel will choose an arbitrary port for us, which will be advertised using Bonjour
		memset(&v6ServerAddress, 0, sizeof(v6ServerAddress));
		v6ServerAddress.sin6_len = nameLen;
		v6ServerAddress.sin6_family = AF_INET6;
		v6ServerAddress.sin6_port = 0;
		v6ServerAddress.sin6_addr = in6addr_any;
		NSData * address4 = [NSData dataWithBytes:&v6ServerAddress length:nameLen];
		
		if (kCFSocketSuccess != CFSocketSetAddress(_ipv6socket, (CFDataRef)address4)) {
			NSError *error = [[NSError alloc] initWithDomain:swypBonjourServiceAdvertiserErrorDomain code:swypBonjourServiceAdvertiserCouldNotBindToIPv6AddressError userInfo:nil];
			EXOLog(@"Could not bind to ipv6 socket %@", [error description]); 
			
			if (_ipv6socket) 
				CFRelease(_ipv6socket);
			
			_ipv6socket = NULL;
		}
		
		// set up the run loop sources for the sockets
		CFRunLoopRef cfrl = CFRunLoopGetCurrent();
		CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _ipv6socket, 0);
		CFRunLoopAddSource(cfrl, source, kCFRunLoopCommonModes);
		CFRelease(source);		
	}

	
}
-(void) _teardownServerSockets{
	
}

#pragma mark CFSocketCallBack
static void _swypServerAcceptConnectionCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
	
	
}

#pragma mark NSNetServiceDelegate
- (void)netServiceDidPublish:(NSNetService *)sender{
	
}
- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict{
	
}

@end
