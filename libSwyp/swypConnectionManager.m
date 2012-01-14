//
//  swypConnectionManager.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import "swypConnectionManager.h"
#import "swypDiscernedInputStream.h"

@implementation swypConnectionManager
@synthesize delegate = _delegate, activeConnectionSessions = _activeConnectionSessions, availableConnectionMethods = _availableConnectionMethods, userPreferedConnectionClass = _userPreferedConnectionClass, activeConnectionClass = _activeConnectionClass, enabledConnectionMethods, activeConnectionMethods;

#pragma mark -
#pragma mark public 

-(void)	startServices{
	[_cloudPairManager resumeNetworkActivity];
	[_bonjourListener	setServiceIsListening:TRUE];
}

-(void)	stopServices{
	[_cloudPairManager suspendNetworkActivity];
	[_bonjourListener	setServiceIsListening:FALSE];
	[_bonjourAdvertiser setAdvertising:FALSE];

	for (swypConnectionSession * session in _activeConnectionSessions){
		[session removeConnectionSessionInfoDelegate:self];
		[session removeDataDelegate:self];
		[session invalidate];
	}	
}
-(swypConnectionMethod)	enabledConnectionMethods{
	if (_activeConnectionClass == swypConnectionClassWifiAndCloud){
		return (swypConnectionMethodWifiLoc	| swypConnectionMethodWifiCloud | swypConnectionMethodWWANCloud);
	}else if (_activeConnectionClass == swypConnectionMethodBluetooth){
		return swypConnectionMethodBluetooth;
	}else return 0;
}

-(swypConnectionMethod)	activeConnectionMethods{
	return ([self enabledConnectionMethods] & [self availableConnectionMethods]);
}

#pragma mark NSOBject 
-(id) init{
	if (self = [super init]){
		_activeConnectionSessions	=	[[NSMutableSet alloc] init];

		_swypIns			= [[NSMutableSet alloc] init];
		_swypOuts			= [[NSMutableSet alloc] init];
		_swypOutTimeouts	= [[NSMutableSet alloc] init];
		_swypInTimeouts		= [[NSMutableSet alloc] init];
		
		
		[self _setupNetworking];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
						
	}
	return self;
}

-(void)	dealloc{

	[[swypNetworkAccessMonitor sharedReachabilityMonitor] removeDelegate:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
		
	SRELS(_bonjourListener);
	SRELS(_bonjourAdvertiser);
	SRELS(_handshakeManager);
	
	SRELS(_cloudPairManager);
	
	for (NSTimer * timer in _swypOutTimeouts){
		[timer invalidate];
	}
	SRELS(_swypOutTimeouts);
	
	for (NSTimer * timer in _swypInTimeouts){
		[timer invalidate];
	}
	SRELS(_swypInTimeouts);
	
	SRELS(_activeConnectionSessions);
	
	
	SRELS(_swypIns);
	SRELS(_swypOuts);
	
	[super dealloc];
}

#pragma mark -
#pragma mark SWYP Responders

-(swypInfoRef*)	oldestSwypInSet:(NSSet*)swypSet{
	swypInfoRef * oldest = nil;
	for (swypInfoRef * next in swypSet){
		if ([[next startDate] timeIntervalSinceReferenceDate] < [[oldest startDate] timeIntervalSinceReferenceDate] || oldest == nil)
			oldest = next;
	}
	
	return oldest;
}

-(swypInfoRef*)	newestSwypInSet:(NSSet*)swypSet{
	swypInfoRef * newest = nil;
	for (swypInfoRef * next in swypSet){
		if ([[next startDate] timeIntervalSinceReferenceDate] > [[newest startDate] timeIntervalSinceReferenceDate] || newest == nil)
			newest = next;
	}
	
	return newest;
}


#pragma mark IN
-(void) swypInCompletedWithSwypInfoRef:	(swypInfoRef*)inInfo{
	NSTimer* swypInTimeout = [[NSTimer timerWithTimeInterval:7 target:self selector:@selector(swypInResponseTimeoutOccuredWithTimer:) userInfo:inInfo repeats:NO] retain];
	[[NSRunLoop mainRunLoop] addTimer:swypInTimeout forMode:NSRunLoopCommonModes];
	[_swypInTimeouts addObject:swypInTimeout];
	[_swypIns addObject:inInfo];
	SRELS(swypInTimeout);

	[_handshakeManager beginHandshakeProcessWithServerCandidates:[_bonjourListener allServerCandidates]];	
	[_cloudPairManager swypInCompleted:inInfo];
}
-(void) swypInResponseTimeoutOccuredWithTimer:	(NSTimer*)timeoutTimer{
	[_swypInTimeouts removeObject:timeoutTimer];
	
	swypInfoRef* swypInfo =	[timeoutTimer userInfo];
	if ([swypInfo isKindOfClass:[swypInfoRef class]]){
		[_swypIns removeObject:swypInfo];
	}
	
	if ([_swypInTimeouts count] == 0){
		EXOLog(@"no longer within swyp-in window");
	}
}

#pragma mark OUT
-(void)	swypOutStartedWithSwypInfoRef:	(swypInfoRef*)outInfo{
	[_bonjourAdvertiser setAdvertising:TRUE];
	[_swypOuts addObject:outInfo];
	
	[_cloudPairManager swypOutBegan:outInfo];
}
-(void)	swypOutCompletedWithSwypInfoRef:(swypInfoRef*)outInfo{
	NSTimer* swypOutTimeout = [[NSTimer timerWithTimeInterval:4 target:self selector:@selector(swypOutResponseTimeoutOccuredWithTimer:) userInfo:outInfo repeats:NO] retain];
	[[NSRunLoop mainRunLoop] addTimer:swypOutTimeout forMode:NSRunLoopCommonModes];
	[_swypOutTimeouts addObject:swypOutTimeout];
	[_swypOuts addObject:outInfo];
	SRELS(swypOutTimeout);
	
	[_cloudPairManager swypOutCompleted:outInfo];
}
-(void)	swypOutFailedWithSwypInfoRef:	(swypInfoRef*)outInfo{
	[_swypOuts removeObject:outInfo];
	
	if (SetHasItems(_swypOuts) == NO){
		[_bonjourAdvertiser setAdvertising:FALSE];		
	}
	
	[_cloudPairManager swypOutFailed:outInfo];
}

-(void) swypOutResponseTimeoutOccuredWithTimer:	(NSTimer*)timeoutTimer{
	[_swypOutTimeouts removeObject:timeoutTimer];
	
	swypInfoRef* swypInfo =	[timeoutTimer userInfo];
	if ([swypInfo isKindOfClass:[swypInfoRef class]]){
		[_swypOuts removeObject:swypInfo];
	}
	
	if (SetHasItems(_swypOuts) == NO){
		[_bonjourAdvertiser setAdvertising:FALSE];		
	}
}

#pragma mark - connectivity
-(void)updateNetworkAvailability{
	swypConnectionMethod preUpdateAvailability	=	_availableConnectionMethods;
	
	swypNetworkAccess reachability = [[swypNetworkAccessMonitor sharedReachabilityMonitor] lastReachability];
	if ((reachability & swypNetworkAccessReachableViaWiFi) == swypNetworkAccessReachableViaWiFi){
		_availableConnectionMethods	= (_availableConnectionMethods | swypConnectionMethodWifiLoc);
	}else{
		_availableConnectionMethods	= (_availableConnectionMethods & (~swypConnectionMethodWifiLoc));
	}

	if ((reachability & swypNetworkAccessReachableViaWWAN) == swypNetworkAccessReachableViaWWAN || (reachability & swypNetworkAccessReachableViaWiFi) == swypNetworkAccessReachableViaWiFi){
		//this means the net is accessable, so we can do cloud connect
		_availableConnectionMethods	= (_availableConnectionMethods | swypConnectionMethodWifiCloud);
	}else{
		_availableConnectionMethods	= (_availableConnectionMethods & (~swypConnectionMethodWifiCloud));
	}

	//check bluetooth only when it's already started, because it displays pop-ups and starts-up the module
	if ((_availableConnectionMethods & swypConnectionMethodBluetooth) == swypConnectionMethodBluetooth){
		[self _updateBluetoothAvailability];	
	}
	
	if (preUpdateAvailability != _availableConnectionMethods){
        // Why are you setting something equal to itself?
		_availableConnectionMethods = _availableConnectionMethods;
		[_delegate swypConnectionMethodsUpdated:_availableConnectionMethods withConnectionManager:self];
	}
}

#pragma mark swypNetworkAccessMonitorDelegate 
-(void)networkReachablityMonitor:(swypNetworkAccessMonitor*)monitor changedReachabilityToStatus:(swypNetworkAccess)reachability{
	[self updateNetworkAvailability];
}

#pragma mark CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(id)central{
	[self _updateBluetoothAvailability];
}


#pragma mark -
#pragma mark private
-(void)_setupNetworking{

	//
	//set defaults 
	_supportedConnectionMethods	|= swypConnectionMethodWifiLoc;
	_supportedConnectionMethods	|= swypConnectionMethodWifiCloud;
	_supportedConnectionMethods	|= swypConnectionMethodWWANCloud;
	_supportedConnectionMethods	|= swypConnectionMethodBluetooth;
	
	_userPreferedConnectionClass	= swypConnectionClassNone;
	_activeConnectionClass			= swypConnectionClassWifiAndCloud;
	
	//
	//find out what works
	[[swypNetworkAccessMonitor sharedReachabilityMonitor] addDelegate:self];
	[self _updateBluetoothAvailability];
	
	//
	//setup services
	
	_bonjourListener	= [[swypBonjourServiceListener alloc] init];
	[_bonjourListener	setDelegate:self];
	
	_bonjourAdvertiser	= [[swypBonjourServiceAdvertiser alloc] init];
	[_bonjourAdvertiser setDelegate:self];
	
	_cloudPairManager	= [[swypCloudPairManager alloc] initWithSwypCloudPairManagerDelegate:self];
	
	_handshakeManager	= [[swypHandshakeManager alloc] init];
	[_handshakeManager	setDelegate:self];
}

-(void)_updateBluetoothAvailability{
		if (1 == 1) { //bluetooth works!
			_availableConnectionMethods |= swypConnectionMethodBluetooth;
		}else{
			_availableConnectionMethods = (_availableConnectionMethods & (!swypConnectionMethodBluetooth));
		}
}


#pragma mark - System Notifcations
- (void)_applicationWillResignActive:(NSNotification *)note{
	[_cloudPairManager suspendNetworkActivity];
	[_bonjourAdvertiser suspendNetworkActivity];
	[_bonjourListener setServiceIsListening:NO];
}

- (void)_applicationDidBecomeActive:(NSNotification *)note{
	[_cloudPairManager resumeNetworkActivity];
	[_bonjourAdvertiser resumeNetworkActivity];
	[_bonjourListener setServiceIsListening:YES];
	
	//check network 
	[self updateNetworkAvailability];
	
}

#pragma mark -
#pragma mark bonjourAdvertiser 
-(void)	bonjourServiceAdvertiserReceivedConnectionFromSwypClientCandidate:(swypClientCandidate*)clientCandidate withStreamIn:(NSInputStream*)inputStream streamOut:(NSOutputStream*)outputStream serviceAdvertiser: (swypBonjourServiceAdvertiser*)advertiser{
	[_handshakeManager beginHandshakeProcessWithClientCandidate:clientCandidate streamIn:inputStream streamOut:outputStream];
}

-(void)	bonjourServiceAdvertiserFailedAdvertisingWithError:(NSError*) error serviceAdvertiser: (swypBonjourServiceAdvertiser*)advertiser{
	EXOLog(@"Failed advertising with error: %@", [error description]);
}

#pragma mark bonjourListener
-(void)	bonjourServiceListenerFoundServerCandidate: (swypServerCandidate*) serverCandidate withListener:(swypBonjourServiceListener*) serviceListener{
	EXOLog(@"Listener found server candidate: %@", [[serverCandidate netService] name]);
	if ([_swypInTimeouts count] > 0){
		[_handshakeManager beginHandshakeProcessWithServerCandidates:[NSSet setWithObject:serverCandidate]];
	}
}
-(void)	bonjourServiceListenerFailedToBeginListen:	(swypBonjourServiceListener*) listener	error:(NSError*)error{
	EXOLog(@"Listener failed to begin listen with error!:%@",[error description]);	
}




#pragma mark -
#pragma mark swypHandshakeManagerDelegate
-(NSArray*)	relevantSwypsForCandidate:	(swypCandidate*)candidate		withHandshakeManager:	(swypHandshakeManager*)manager{
	if ([candidate isKindOfClass:[swypServerCandidate class]]){
		NSArray * swypArray	=	(SetHasItems(_swypIns))? [NSArray arrayWithObject:[self newestSwypInSet:_swypIns]] : nil;
		return swypArray;
	}else if ([candidate isKindOfClass:[swypClientCandidate class]]){
		
		NSMutableArray * swypArray	=	[NSMutableArray array];
		for (swypInfoRef * outRef in _swypOuts){
			if ([outRef endDate] != nil){
				[swypArray addObject:outRef];
			}
		}
		
		return swypArray;
	}
	
	return nil;
}

-(void)	connectionSessionCreationFailedForCandidate:(swypCandidate*)candidate		withHandshakeManager:	(swypHandshakeManager*)manager error:(NSError*)error{
	EXOLog(@"Candidate session failed creation with error: %@",[error description]);
}
-(void)	connectionSessionWasCreatedSuccessfully:	(swypConnectionSession*)session	withHandshakeManager:	(swypHandshakeManager*)manager{
	[session addDataDelegate:self];
	[session addConnectionSessionInfoDelegate:self];
	[_activeConnectionSessions addObject:session];
	[_delegate swypConnectionSessionWasCreated:session withConnectionManager:self];
}

#pragma mark -
#pragma mark swypCloudPairManagerDelegate
-(void)swypCloudPairManager:(swypCloudPairManager*)manager didReceiveSwypConnectionFromClient:(swypClientCandidate*)clientCandidate withStreamIn:(NSInputStream*)inputStream streamOut:(NSOutputStream*)outputStream{
	[_handshakeManager beginHandshakeProcessWithPrePairedCandidate:clientCandidate streamIn:inputStream streamOut:outputStream];
}
-(void)swypCloudPairManager:(swypCloudPairManager*)manager didCreateSwypConnectionToServer:(swypServerCandidate*)serverCandidate withStreamIn:(NSInputStream*)inputStream streamOut:(NSOutputStream*)outputStream{
	[_handshakeManager beginHandshakeProcessWithPrePairedCandidate:serverCandidate streamIn:inputStream streamOut:outputStream];
}

#pragma mark -
#pragma mark swypInputToDataBridgeDelegate
-(void)	dataBridgeYieldedData:(NSData*) yieldedData fromInputStream:(NSInputStream*) inputStream withInputToDataBridge:(swypInputToDataBridge*)bridge{
	if ([inputStream isKindOfClass:[swypDiscernedInputStream class]]){
		EXOLog(@"Yielded data %@ with type '%@' tag '%@'",[NSString  stringWithUTF8String:[yieldedData bytes]], [(swypDiscernedInputStream*)inputStream streamType], [(swypDiscernedInputStream*)inputStream streamTag]);	
	}else{
		EXOLog(@"Unexpected bridge response with data :%@",[NSString  stringWithUTF8String:[yieldedData bytes]]);
	}
}
-(void)	dataBridgeFailedYieldingDataFromInputStream:(NSInputStream*) inputStream withError: (NSError*) error inInputToDataBridge:(swypInputToDataBridge*)bridge{
	
}

#pragma mark -
#pragma mark swypConnectionSessionInfoDelegate
-(void) sessionStatusChanged:	(swypConnectionSessionStatus)status	inSession:(swypConnectionSession*)session{
}
-(void) sessionWillDie:			(swypConnectionSession*)session{	
}
-(void) sessionDied:			(swypConnectionSession*)session withError:(NSError*)error{
	[_activeConnectionSessions removeObject:session];
	[_delegate swypConnectionSessionWasInvalidated:session withConnectionManager:self error:error];
}
#pragma mark swypConnectionSessionDataDelegate

-(BOOL) delegateWillHandleDiscernedStream:(swypDiscernedInputStream*)discernedStream wantsAsData:(BOOL *)wantsProvidedAsNSData inConnectionSession:(swypConnectionSession*)session{
	if ([[discernedStream streamType] isFileType:[NSString swypControlPacketFileType]]){
		if ([[discernedStream streamTag] isEqualToString:@"goodbye"]){
			[session invalidate];
		}
		wantsProvidedAsNSData = (BOOL*) TRUE;
		return TRUE;
	}	
	return FALSE;
}

-(void)	yieldedData:(NSData*)streamData discernedStream:(swypDiscernedInputStream*)discernedStream inConnectionSession:(swypConnectionSession*)session{
	if ([[discernedStream streamType] isFileType:[NSString swypControlPacketFileType]]){
		//do something to handle this :)
		
		NSDictionary *	receivedDictionary = nil;
		if ([streamData length] >0){
			NSString *	readStreamString	=	[[[NSString alloc]  initWithBytes:[streamData bytes] length:[streamData length] encoding: NSUTF8StringEncoding] autorelease];
			if (StringHasText(readStreamString))
				receivedDictionary				=	[NSDictionary dictionaryWithJSONString:readStreamString];
		}		
		
		if (receivedDictionary != nil){
			EXOLog(@"Received %@ dictionary of contents:%@",[discernedStream streamType],[receivedDictionary description]);
		}
	}
	
}



@end
