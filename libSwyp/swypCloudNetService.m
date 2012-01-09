//
//  swypCloudNetService.m
//  swyp
//
//  Created by Alexander List on 1/4/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import "swypCloudNetService.h"

@implementation swypCloudNetService
@synthesize delegate = _delegate, portNumber;
@synthesize ipv4socket = _ipv4socket, ipv6socket = _ipv6socket;

#pragma mark - public
-(void)beginConnectionToPeerWithInfo:(NSDictionary*)peerInfo{
	
	//xmpp to come
	[self _connectToServerWithIP:[peerInfo valueForKey:@"address"] port:[[peerInfo valueForKey:@"port"] intValue] info:peerInfo];
}

-(NSUInteger)portNumber{
	
	NSUInteger serverPort	=	0;
	
	if (_ipv4socket != NULL){
		struct sockaddr_in v4ServerAddress;
		NSData * v4Addr = [(NSData *)CFSocketCopyAddress(_ipv4socket) autorelease];
		memcpy(&v4ServerAddress, [v4Addr bytes], [v4Addr length]);
		serverPort = ntohs(v4ServerAddress.sin_port); 
	}else if (_ipv6socket != NULL){
		struct sockaddr_in6 v6ServerAddress;	
		NSData * v6Addr = [(NSData *)CFSocketCopyAddress(_ipv6socket) autorelease];
		memcpy(&v6ServerAddress, [v6Addr bytes], [v6Addr length]);
		serverPort = ntohs(v6ServerAddress.sin6_port);
	}
	
	return serverPort;
}

-(void)	suspendNetworkActivity{
	[self _teardownServerSockets];
}
-(void)	resumeNetworkActivity{
	[self _setupServerSockets];
}


#pragma mark NSObject
-(id)initWithDelegate:(id<swypCloudNetServiceDelegate>)delegate{
	if (self = [super init]){
		_delegate = delegate;
		
		[self _setupServerSockets];
	}
	return self;
}

-(void)dealloc{
	_delegate = nil;
	
	[super dealloc];
}

#pragma mark - private
#pragma mark - server
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
			EXOLog(@"No sockets in ipv4 %@", [error description]);
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
	swypCloudNetService * cloudySelf	=	(swypCloudNetService*)info;
	
	if (type == kCFSocketAcceptCallBack) { 
		
        CFSocketNativeHandle nativeSocketHandle = *(CFSocketNativeHandle *)data;
		
		CFReadStreamRef		readStream		= NULL;
		CFWriteStreamRef	writeStream		= NULL;
		
		NSString *			clientIPAddress	= nil;
		NSUInteger			clientPort		= 0;
		NSUInteger			adrBufferLength	= 50;
		
		if (socket == cloudySelf.ipv4socket){
			struct sockaddr_in peerAddress;
			socklen_t peerLen = sizeof(peerAddress);
			char		addressBuffer[adrBufferLength];
						
			if (getpeername(nativeSocketHandle, (struct sockaddr *)&peerAddress, (socklen_t *)&peerLen) == 0) {

				clientPort = ntohs(peerAddress.sin_port); 
				
				if (inet_ntop(AF_INET,&peerAddress,addressBuffer,adrBufferLength) != NULL){
					clientIPAddress	=	[NSString stringWithUTF8String:addressBuffer];
				}
			}
		}else if (socket == cloudySelf.ipv6socket){
			struct		sockaddr_in6 peerAddress;
			socklen_t	peerLen = sizeof(peerAddress);
			char		addressBuffer[adrBufferLength];
						
			if (getpeername(nativeSocketHandle, (struct sockaddr *)&peerAddress, (socklen_t *)&peerLen) == 0) {

				clientPort = ntohs(peerAddress.sin6_port); 
				
				if (inet_ntop(AF_INET6,&peerAddress,addressBuffer,adrBufferLength) != NULL){
					clientIPAddress	=	[NSString stringWithUTF8String:addressBuffer];
				}
			}			
		}
		
		
		CFStreamCreatePairWithSocket(kCFAllocatorDefault, nativeSocketHandle, &readStream, &writeStream);
		
        if (readStream && writeStream) {
            CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
            CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
			EXOLog(@"successful socket to peer at address: %@",clientIPAddress);
			
			//this is for dict system
			NSMutableDictionary * peerInfo	=	[NSMutableDictionary dictionary];
			[peerInfo setValue:clientIPAddress forKey:@"address"];
			
			[[cloudySelf delegate] cloudNetService:cloudySelf didReceiveInputStream:(NSInputStream*) readStream outputStream:(NSOutputStream*)writeStream withPeerFromInfo:peerInfo];
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
		
	}
	
}
#pragma mark - initiator
-(void) _connectToServerWithIP:(NSString*)ip port:(NSUInteger)port info:(NSDictionary*)peerInfo{
	
	CFReadStreamRef				readStream = NULL;
	CFWriteStreamRef			writeStream = NULL;
	
	CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (CFStringRef)ip, port, &readStream, &writeStream);
	if(!readStream || !writeStream) {
		if(readStream)
			CFRelease(readStream);
		if(writeStream)
			CFRelease(writeStream);

		[_delegate cloudNetService:self didFailToCreateConnectionWithPeerFromInfo:peerInfo];
	}else{
		[_delegate cloudNetService:self didCreateInputStream:(NSInputStream *)readStream outputStream:(NSOutputStream *)writeStream withPeerFromInfo:peerInfo];
		
		CFRelease(readStream);
		CFRelease(writeStream);
	}	
}



@end
