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
#import  <arpa/inet.h>
#include <CFNetwork/CFSocketStream.h>


static NSString * const swypBonjourServiceAdvertiserErrorDomain = @"swypBonjourServiceAdvertiserErrorDomain";

@implementation swypBonjourServiceAdvertiser
@synthesize delegate = _delegate, ipv4socket = _ipv4socket, ipv6socket = _ipv6socket;

#pragma mark -
#pragma mark public
-(BOOL)	isAdvertising{
	
	return _isPublished;
}
-(void)	setAdvertising:(BOOL)advertisingEnabled{
	if( advertisingEnabled == _isPublished && advertisingEnabled == TRUE)
		return;
	
	if (advertisingEnabled == YES){
		EXOLog(@"Began advertisment publish at time %@",[[NSDate date] description]);
		[self _setupBonjourAdvertising];
	}else {
		EXOLog(@"Tore-down advertisement at time %@",[[NSDate date] description]);
		[self _teardownBonjourAdvertising:nil];
	}

}


#pragma mark NSObject
-(void)	dealloc{
	[self _teardownBonjourAdvertising:nil]; //this should handle both bonjour and sockets
	
	[super dealloc];
}


#pragma mark -
#pragma mark private
-(void)	_setupBonjourAdvertising{
	
	if (_ipv4socket == NULL && _ipv6socket == NULL){
		[self _setupServerSockets];
	}
	
	if (_ipv4socket != NULL){
		uint16_t chosenV4Port = 0;
		struct sockaddr_in v4ServerAddress;
		NSData * v4Addr = [(NSData *)CFSocketCopyAddress(_ipv4socket) autorelease];
		memcpy(&v4ServerAddress, [v4Addr bytes], [v4Addr length]);
		chosenV4Port = ntohs(v4ServerAddress.sin_port); 
		EXOLog(@"Setting up advertising on v4 with port: %i",chosenV4Port);

		if (_v4AdvertiserService != nil){
			[self _teardownBonjourAdvertising:_v4AdvertiserService];
		}
		
		_v4AdvertiserService	= [[NSNetService alloc] initWithDomain:@"" type:@"_swyp._tcp." name:def_bonjourHostName port:chosenV4Port];
		[_v4AdvertiserService setDelegate:self];
		[_v4AdvertiserService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
		[_v4AdvertiserService publishWithOptions:0];
		
	}
	
	if (_ipv6socket != NULL){
		uint16_t chosenV6Port = 0;
		struct sockaddr_in6 v6ServerAddress;	
		NSData * v6Addr = [(NSData *)CFSocketCopyAddress(_ipv6socket) autorelease];
		memcpy(&v6ServerAddress, [v6Addr bytes], [v6Addr length]);
		chosenV6Port = ntohs(v6ServerAddress.sin6_port);
		EXOLog(@"Setting up advertising on v6 with port: %i",chosenV6Port);
		
		if (_v6AdvertiserService != nil){
			[self _teardownBonjourAdvertising:_v6AdvertiserService];
		}

		_v6AdvertiserService	= [[NSNetService alloc] initWithDomain:@"" type:@"_swyp._tcp." name:def_bonjourHostName port:chosenV6Port];
		[_v6AdvertiserService setDelegate:self];
		[_v6AdvertiserService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
		[_v6AdvertiserService publishWithOptions:0];

	}
	
	if (_v6AdvertiserService == nil && _v4AdvertiserService == nil){
		[_delegate bonjourServiceAdvertiserFailedAdvertisingWithError:[NSError errorWithDomain:swypBonjourServiceAdvertiserErrorDomain code:swypBonjourServiceAdvertiserFailedNetServicePublicationError userInfo:nil] serviceAdvertiser:self];
		_isPublished = FALSE;
	}
	
}
-(void) _teardownBonjourAdvertising:(NSNetService*)specificOrNil{
	if (_v6AdvertiserService != nil && (_v6AdvertiserService == specificOrNil || specificOrNil == nil)){
		[_v6AdvertiserService setDelegate:nil];
		[_v6AdvertiserService stop];
		[_v6AdvertiserService removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
		SRELS(_v6AdvertiserService);
	}	
	
	if (_v4AdvertiserService != nil && (_v4AdvertiserService == specificOrNil || specificOrNil == nil)){
		[_v4AdvertiserService setDelegate:nil];
		[_v4AdvertiserService stop];
		[_v4AdvertiserService removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
		SRELS(_v4AdvertiserService);	
	}
	
		_isPublished = FALSE;
	
//	if (_v6AdvertiserService == nil && _v4AdvertiserService == nil){
//		_isPublished = FALSE;
//		[self _teardownServerSockets];
//	}
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
				
		if (_ipv4socket != NULL){
			// set up the run loop sources for the sockets
			CFRunLoopRef cfrl = CFRunLoopGetCurrent();
			CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _ipv4socket, 0);
			CFRunLoopAddSource(cfrl, source, kCFRunLoopCommonModes);
			CFRelease(source);
		}
		
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
//			NSError *error = [[NSError alloc] initWithDomain:swypBonjourServiceAdvertiserErrorDomain code:swypBonjourServiceAdvertiserCouldNotBindToIPv6AddressError userInfo:nil];
			EXOLog(@"Could not bind to ipv6 socket"); 
			
			if (_ipv6socket) 
				CFRelease(_ipv6socket);
			
			_ipv6socket = NULL;
		}
		
		
		if (_ipv6socket != NULL){
			// set up the run loop sources for the sockets
			CFRunLoopRef cfrl = CFRunLoopGetCurrent();
			CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _ipv6socket, 0);
			CFRunLoopAddSource(cfrl, source, kCFRunLoopCommonModes);
			CFRelease(source);	
		}
	}

	
}
-(void) _teardownServerSockets{
	if (_ipv4socket) {
		CFSocketInvalidate(_ipv4socket);
		CFRelease(_ipv4socket);
		_ipv4socket =	NULL;
	}

	if (_ipv6socket){
		CFSocketInvalidate(_ipv6socket);
		CFRelease(_ipv6socket);
		_ipv6socket	=	NULL;
	}
}

#pragma mark CFSocketCallBack
static void _swypServerAcceptConnectionCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
	EXOLog(@"Accepted connection callback at time %@",[[NSDate date] description]);
	swypBonjourServiceAdvertiser * advertisingSelf	=	(swypBonjourServiceAdvertiser*)info;
	
	if (type == kCFSocketAcceptCallBack) { 
		
        CFSocketNativeHandle nativeSocketHandle = *(CFSocketNativeHandle *)data;

		CFReadStreamRef		readStream		= NULL;
		CFWriteStreamRef	writeStream		= NULL;
		
		NSString *			clientIPAddress	= nil;
		NSUInteger			adrBufferLength	= 50;
		
		if (socket == advertisingSelf.ipv4socket){
			struct sockaddr_in peerAddress;
			socklen_t peerLen = sizeof(peerAddress);
			char		addressBuffer[adrBufferLength];
			
			if (getpeername(nativeSocketHandle, (struct sockaddr *)&peerAddress, (socklen_t *)&peerLen) == 0) {
				if (inet_ntop(AF_INET,&peerAddress,addressBuffer,adrBufferLength) != NULL)
					clientIPAddress	=	[NSString stringWithUTF8String:addressBuffer];
			}
		}else if (socket == advertisingSelf.ipv6socket){
			struct		sockaddr_in6 peerAddress;
			socklen_t	peerLen = sizeof(peerAddress);
			char		addressBuffer[adrBufferLength];
			
			if (getpeername(nativeSocketHandle, (struct sockaddr *)&peerAddress, (socklen_t *)&peerLen) == 0) {
				if (inet_ntop(AF_INET6,&peerAddress,addressBuffer,adrBufferLength) != NULL)
					clientIPAddress	=	[NSString stringWithUTF8String:addressBuffer];
			}			
		}
		
		CFStreamCreatePairWithSocket(kCFAllocatorDefault, nativeSocketHandle, &readStream, &writeStream);
				
        if (readStream && writeStream) {
            CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
            CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
			EXOLog(@"Created a successful socket connection at date: %@; with peer at address: %@",[[NSDate date]description],clientIPAddress);
			[[advertisingSelf delegate] bonjourServiceAdvertiserReceivedConnectionFromSwypClientCandidate:[[[swypClientCandidate alloc] init] autorelease] withStreamIn:(NSInputStream *)readStream streamOut:(NSOutputStream *)writeStream serviceAdvertiser:advertisingSelf];
        } else {
			EXOLog(@"Failed creating socket connection at time: %@", [[NSDate date] description]);
            // on any failure, need to destroy the CFSocketNativeHandle 
            // since we are not going to use it any more
            close(nativeSocketHandle);
        }
		
        if (readStream) 
			CFRelease(readStream);
        if (writeStream) 
			CFRelease(writeStream);

		
        // for an AcceptCallBack, the data parameter is a pointer to a CFSocketNativeHandle
    }
	
}

#pragma mark NSNetServiceDelegate
-(void)netServiceWillPublish:(NSNetService *)sender{
	_isPublished = TRUE;	
}

- (void)netServiceDidPublish:(NSNetService *)sender{
	EXOLog(@"Published bonjour on ip at time %@",[[NSDate date] description]);
}
- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict{
	if (sender == _v6AdvertiserService){
		EXOLog(@"Failed publishing v6 at time %@",[[NSDate date] description]);
		[self _teardownBonjourAdvertising:_v6AdvertiserService];
		if (_v4AdvertiserService == nil){
			[_delegate bonjourServiceAdvertiserFailedAdvertisingWithError:[NSError errorWithDomain:swypBonjourServiceAdvertiserErrorDomain code:swypBonjourServiceAdvertiserFailedNetServicePublicationError userInfo:errorDict] serviceAdvertiser:self];
		}

	}else if (sender == _v4AdvertiserService){
		EXOLog(@"Failed publishing v4 at time %@",[[NSDate date] description]);
		[self _teardownBonjourAdvertising:_v4AdvertiserService];
		if (_v6AdvertiserService == nil){
			[_delegate bonjourServiceAdvertiserFailedAdvertisingWithError:[NSError errorWithDomain:swypBonjourServiceAdvertiserErrorDomain code:swypBonjourServiceAdvertiserFailedNetServicePublicationError userInfo:errorDict] serviceAdvertiser:self];
		}
	}
}

@end
