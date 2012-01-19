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
@synthesize delegate = _delegate, activeConnectionSessions = _activeConnectionSessions, availableConnectionMethods = _availableConnectionMethods, userPreferedConnectionClass = _userPreferedConnectionClass, activeConnectionClass, enabledConnectionMethods, activeConnectionMethods,supportedConnectionMethods = _supportedConnectionMethods;

#pragma mark -
#pragma mark public 

-(void)	startServices{
	if (self.activeConnectionMethods & swypConnectionMethodWifiCloud){
		[_cloudPairManager resumeNetworkActivity];
	}
	if (self.activeConnectionMethods & swypConnectionMethodWWANCloud){
		[_cloudPairManager resumeNetworkActivity];
	}
	if (self.activeConnectionMethods & swypConnectionMethodWifiLoc){
		[_bonjourPairManager resumeNetworkActivity];
	}
	if (self.activeConnectionMethods & swypConnectionMethodBluetooth){
		[_bluetoothPairManager resumeNetworkActivity];
	}
}

-(void)	stopServices{
	[_cloudPairManager suspendNetworkActivity];
	[_bonjourPairManager suspendNetworkActivity];
	[_bluetoothPairManager suspendNetworkActivity];

	for (swypConnectionSession * session in _activeConnectionSessions){
		[session removeConnectionSessionInfoDelegate:self];
		[session removeDataDelegate:self];
		[session invalidate];
	}	
}

-(void) setUserPreferedConnectionClass:(swypConnectionClass)class{
	swypConnectionClass currentClass	=	self.activeConnectionClass;
	_userPreferedConnectionClass		= class;
	if (currentClass != _userPreferedConnectionClass){
		[self _activeConnectionInterfacesChanged];
	}
}

-(swypConnectionClass)	activeConnectionClass{
	if (_userPreferedConnectionClass == swypConnectionClassNone){
		if (_availableConnectionMethods & (swypConnectionMethodWifiLoc	| swypConnectionMethodWifiCloud | swypConnectionMethodWWANCloud)){
			return swypConnectionClassWifiAndCloud;
		}else{
			return swypConnectionClassBluetooth;
		}
	}else return _userPreferedConnectionClass;
}

-(swypConnectionMethod)	enabledConnectionMethods{
	if (self.activeConnectionClass == swypConnectionClassWifiAndCloud){
		swypConnectionMethod enabledMethods = ((swypConnectionMethodWifiLoc	| swypConnectionMethodWifiCloud | swypConnectionMethodWWANCloud) & _supportedConnectionMethods);
		return enabledMethods;
	}else if (self.activeConnectionClass == swypConnectionClassBluetooth){
		return (swypConnectionMethodBluetooth & _supportedConnectionMethods);
	}else return swypConnectionMethodNone;
}

-(swypConnectionMethod)	activeConnectionMethods{
	swypConnectionMethod activeMethods = ([self enabledConnectionMethods] & [self availableConnectionMethods]);
	return activeMethods;
}

#pragma mark NSOBject 
-(id) init{
	if (self = [super init]){
		
		//find out what works
		[[swypNetworkAccessMonitor sharedReachabilityMonitor] addDelegate:self];	
		
		_activeConnectionSessions	=	[[NSMutableSet alloc] init];
		
		_pendingSwypInConnections	=	[[swypPendingConnectionManager alloc] initWithDelegate:self];
		
		[self _setupNetworking];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
						
	}
	return self;
}

-(void)	dealloc{

	[[swypNetworkAccessMonitor sharedReachabilityMonitor] removeDelegate:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_bluetoothPairManager removeObserver:self forKeyPath:@"bluetoothEnabled"];
		
	SRELS(_bonjourPairManager);
	SRELS(_cloudPairManager);
	SRELS(_bluetoothPairManager);
	
	SRELS(_handshakeManager);
			
	SRELS(_activeConnectionSessions);
	
	[super dealloc];
}

#pragma mark - Hardcore delegation
#pragma mark swypInterfaceManagerDelegate
-(void) interfaceManager:(id<swypInterfaceManager>)manager isDoneAdvertisingSwypOutAsPending:(swypInfoRef*)ref forConnectionMethod:(swypConnectionMethod)method{
	[_handshakeManager dereferenceSwypOutAsPending:ref];
}

-(void)interfaceManager:(id<swypInterfaceManager>)manager isDoneSearchForSwypInServerCandidatesForRef:(swypInfoRef*)ref forConnectionMethod:(swypConnectionMethod)method{
	[_pendingSwypInConnections connectionMethodTimedOut:method forSwypRef:ref];
}

-(void)interfaceManager:(id<swypInterfaceManager>)manager madeUninitializedSwypServerCandidateConnectionSession:(swypConnectionSession*)connectionSession forRef:(swypInfoRef*)ref withConnectionMethod:(swypConnectionMethod)method{

	
	for (int i = 0; i <= 7; i ++){
		//swypConnectionMethod are bitshifted values, and method might be too
		swypConnectionMethod testMethod  = ((char)1 << i);
		if (testMethod & method){
			[_pendingSwypInConnections addSwypServerCandidateConnectionSession:connectionSession forSwypRef:ref forConnectionMethod:testMethod];
			break; //only add for the highest priority
		}
	}
	
	//swyp-in potentially matched ref
}

-(void)interfaceManager:(id<swypInterfaceManager>)manager receivedUninitializedSwypClientCandidateConnectionSession:(swypConnectionSession*)connectionSession withConnectionMethod:(swypConnectionMethod)method{
	
	//swyp out matched ref
	[_handshakeManager beginHandshakeProcessWithConnectionSession:connectionSession];
}

#pragma mark swypPendingConnectionManagerDelegate
-(void)	swypPendingConnectionManager:(swypPendingConnectionManager*)manager hasAvailableHandshakeableConnectionSessionsForSwyp:(swypInfoRef*)ref{
	
	swypConnectionSession * connectionSession	=	nil;
	if ((connectionSession = [_pendingSwypInConnections nextConnectionSessionToAttemptHandshakeForSwypRef:ref])){
		[_handshakeManager beginHandshakeProcessWithConnectionSession:connectionSession];
	}
}

-(void)	swypPendingConnectionManager:(swypPendingConnectionManager*)manager finishedForSwyp:(swypInfoRef*)ref{
//	EXOLog(@"pending connection mngr completed swypRef from time %@",[[ref startDate] description]);
}


#pragma mark - less hardcore but still hardcore
#pragma mark swypHandshakeManagerDelegate
-(void)	connectionSessionCreationFailedForConnectionSession:(swypConnectionSession*)session	forSwypRef:(swypInfoRef*)ref	withHandshakeManager:	(swypHandshakeManager*)manager error:(NSError*)error{
	EXOLog(@"session failed handshake with swyp from time: %@; with error: %@", [[ref startDate] description],[error description]);
	
	if (ref.swypType == swypInfoRefTypeSwypIn){
		swypConnectionSession * connectionSession	=	nil;
		if ((connectionSession = [_pendingSwypInConnections nextConnectionSessionToAttemptHandshakeForSwypRef:ref])){
			[_handshakeManager beginHandshakeProcessWithConnectionSession:connectionSession];
		}
	}
}
-(void)	connectionSessionWasCreatedSuccessfully:	(swypConnectionSession*)session forSwypRef:(swypInfoRef*)ref	withHandshakeManager:	(swypHandshakeManager*)manager{
	
	if (ref.swypType == swypInfoRefTypeSwypIn){
		[_pendingSwypInConnections clearAllPendingConnectionsForSwypRef:ref];
	}else if (ref.swypType == swypInfoRefTypeSwypOut){
		[self dropSwypOutSwypInfoRefFromAdvertisers:ref];
	}
	
	[session addDataDelegate:self];
	[session addConnectionSessionInfoDelegate:self];
	[_activeConnectionSessions addObject:session];
	[_delegate swypConnectionSessionWasCreated:session withConnectionManager:self];
}


#pragma mark SWYP Responders
#pragma mark IN
-(void) swypInCompletedWithSwypInfoRef:	(swypInfoRef*)inInfo{

	NSMutableArray * addedInterfacesForSwypIn	=	[NSMutableArray array];
	if (self.activeConnectionMethods & swypConnectionMethodWifiCloud){
		[_cloudPairManager startFindingSwypInServerCandidatesForRef:inInfo];
		
		[addedInterfacesForSwypIn addObject:[NSNumber numberWithInt:swypConnectionMethodWifiCloud]];
	}
	if (self.activeConnectionMethods & swypConnectionMethodWWANCloud){
		[_cloudPairManager startFindingSwypInServerCandidatesForRef:inInfo];
		
		[addedInterfacesForSwypIn addObject:[NSNumber numberWithInt:swypConnectionMethodWWANCloud]];
	}
	if (self.activeConnectionMethods & swypConnectionMethodWifiLoc){
		[_bonjourPairManager startFindingSwypInServerCandidatesForRef:inInfo];
		
		[addedInterfacesForSwypIn addObject:[NSNumber numberWithInt:swypConnectionMethodWifiLoc]];

	}
	if (self.activeConnectionMethods & swypConnectionMethodBluetooth){

		[_pendingSwypInConnections setSwypInPending:inInfo forConnectionMethod:swypConnectionMethodBluetooth];
		[_bluetoothPairManager startFindingSwypInServerCandidatesForRef:inInfo];

		//we're not doing the bulk add
		
	}
	
	if ([addedInterfacesForSwypIn count] > 0){
		[_pendingSwypInConnections	setSwypInPending:inInfo forConnectionMethods:addedInterfacesForSwypIn];		
	}
}

#pragma mark OUT
-(void)	swypOutStartedWithSwypInfoRef:	(swypInfoRef*)outInfo{
	
	NSMutableArray * addedInterfacesForSwypOut	=	[NSMutableArray array];
	if (self.activeConnectionMethods & swypConnectionMethodWifiCloud){
		[_cloudPairManager advertiseSwypOutAsPending:outInfo];

		[addedInterfacesForSwypOut addObject:[NSNumber numberWithInt:swypConnectionMethodWifiCloud]];
	}
	if (self.activeConnectionMethods & swypConnectionMethodWWANCloud){
		[_cloudPairManager advertiseSwypOutAsPending:outInfo];

		[addedInterfacesForSwypOut addObject:[NSNumber numberWithInt:swypConnectionMethodWWANCloud]];
	}
	if (self.activeConnectionMethods & swypConnectionMethodWifiLoc){
		[_bonjourPairManager advertiseSwypOutAsPending:outInfo];
		
		[addedInterfacesForSwypOut addObject:[NSNumber numberWithInt:swypConnectionMethodWifiLoc]];
	}
	if (self.activeConnectionMethods & swypConnectionMethodBluetooth){
		[_bluetoothPairManager advertiseSwypOutAsPending:outInfo];
		
		[addedInterfacesForSwypOut addObject:[NSNumber numberWithInt:swypConnectionMethodBluetooth]];
	}
	
	for (NSNumber * interface in addedInterfacesForSwypOut){
		[_handshakeManager referenceSwypOutAsPending:outInfo];
	}
}
-(void)	swypOutCompletedWithSwypInfoRef:(swypInfoRef*)outInfo{

	NSMutableArray * addedInterfacesForSwypOut	=	[NSMutableArray array];
	if (self.activeConnectionMethods & swypConnectionMethodWifiCloud){
		[_cloudPairManager advertiseSwypOutAsCompleted:outInfo];
		
		[addedInterfacesForSwypOut addObject:[NSNumber numberWithInt:swypConnectionMethodWifiCloud]];
	}
	if (self.activeConnectionMethods & swypConnectionMethodWWANCloud){
		[_cloudPairManager advertiseSwypOutAsCompleted:outInfo];
		
		[addedInterfacesForSwypOut addObject:[NSNumber numberWithInt:swypConnectionMethodWWANCloud]];
	}
	if (self.activeConnectionMethods & swypConnectionMethodWifiLoc){
		[_bonjourPairManager advertiseSwypOutAsCompleted:outInfo];
	}
	if (self.activeConnectionMethods & swypConnectionMethodBluetooth){
		[_bluetoothPairManager advertiseSwypOutAsCompleted:outInfo];
	}
	
}
-(void)	swypOutFailedWithSwypInfoRef:	(swypInfoRef*)outInfo{
	[self dropSwypOutSwypInfoRefFromAdvertisers:outInfo];
}


-(void)dropSwypOutSwypInfoRefFromAdvertisers:(swypInfoRef*)outInfo{
	if (self.activeConnectionMethods & swypConnectionMethodWifiCloud){
		if ([_cloudPairManager isAdvertisingSwypOut:outInfo]){
			[_cloudPairManager stopAdvertisingSwypOut:outInfo];
		}
	}
	
	if (self.activeConnectionMethods & swypConnectionMethodWWANCloud){
		
		if ([_cloudPairManager isAdvertisingSwypOut:outInfo]){
			[_cloudPairManager stopAdvertisingSwypOut:outInfo];
		}
	}
	
	if (self.activeConnectionMethods & swypConnectionMethodWifiLoc){
		if ([_bonjourPairManager isAdvertisingSwypOut:outInfo]){
			[_bonjourPairManager stopAdvertisingSwypOut:outInfo];
		}
	}
	if (self.activeConnectionMethods & swypConnectionMethodBluetooth){
		if ([_bluetoothPairManager isAdvertisingSwypOut:outInfo]){
			[_bluetoothPairManager stopAdvertisingSwypOut:outInfo];
		}
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

	//we require bluetooth to always be 'available' even if it isn't turned on
	_availableConnectionMethods |= swypConnectionMethodBluetooth;
	
	if (preUpdateAvailability != _availableConnectionMethods){
		[self _activeConnectionInterfacesChanged];
	}
}

#pragma mark swypNetworkAccessMonitorDelegate 
-(void)networkReachablityMonitor:(swypNetworkAccessMonitor*)monitor changedReachabilityToStatus:(swypNetworkAccess)reachability{
	[self updateNetworkAvailability];
}


#pragma mark -
#pragma mark private
-(void)_setupNetworking{

	//
	//set defaults 
//	_supportedConnectionMethods	|= swypConnectionMethodWifiLoc;
	_supportedConnectionMethods	|= swypConnectionMethodWifiCloud;
	_supportedConnectionMethods	|= swypConnectionMethodWWANCloud;
	_supportedConnectionMethods	|= swypConnectionMethodBluetooth;
	
	_userPreferedConnectionClass	= swypConnectionClassBluetooth;
	
	//
	//setup service managers
//	_bonjourPairManager		= [[swypBonjourPairManager alloc] initWithInterfaceManagerDelegate:self];
	_cloudPairManager		= [[swypCloudPairManager alloc] initWithInterfaceManagerDelegate:self];
	_bluetoothPairManager	= [[swypBluetoothPairManager alloc] initWithInterfaceManagerDelegate:self];
    
    [_bluetoothPairManager addObserver:self forKeyPath:@"bluetoothEnabled" options:NSKeyValueObservingOptionNew context:NULL];
	
	_handshakeManager	= [[swypHandshakeManager alloc] init];
	[_handshakeManager	setDelegate:self];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqual:@"bluetoothEnabled"]){
        EXOLog(@"BLUETOOTH AVAILABILITY CHANGED: %@", [change objectForKey:NSKeyValueChangeNewKey]);
        [self.delegate performSelector:@selector(setBluetoothReady:) 
                            withObject:[change objectForKey:NSKeyValueChangeNewKey]];
    }
}

-(void) _activeConnectionInterfacesChanged{
	[self stopServices];
	[self startServices];

	[_delegate swypConnectionMethodsUpdated:[self availableConnectionMethods] withConnectionManager:self];
}


#pragma mark - System Notifcations
- (void)_applicationWillResignActive:(NSNotification *)note{
	[self stopServices];
}

- (void)_applicationDidBecomeActive:(NSNotification *)note{
	[self startServices];
	
	//check network 
	[self updateNetworkAvailability];
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
