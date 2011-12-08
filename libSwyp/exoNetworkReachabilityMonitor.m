//
//  exoNetworkReachabilityMonitor.m
//  exoLib
//
//  Created by Alexander List on 7/27/10.
//  Copyright (c) 2010 List Consulting. All rights reserved.
//

#import "exoNetworkReachabilityMonitor.h"



static exoNetworkReachabilityMonitor *reachabilityMonitor;
@implementation exoNetworkReachabilityMonitor

static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info)
{
#pragma unused (target, flags)
    
    if (info != NULL){
        NSCAssert(info != NULL, @"info was NULL in ReachabilityCallback");
        NSCAssert([(NSObject*) info isKindOfClass: [exoNetworkReachabilityMonitor class]], @"info was wrong class in ReachabilityCallback");
    }
        
    //We're on the main RunLoop, so an NSAutoreleasePool is not necessary, but is added defensively
    // in case someon uses the Reachablity object in a different thread.
    NSAutoreleasePool* myPool = [[NSAutoreleasePool alloc] init];
    
    [reachabilityMonitor reachabilityFlagsFound:flags];
    
    // Post a notification to notify the client that the network reachability changed.
    
    [myPool release];
}

-(networkReachability)lastReachability{
    return recentReachability;
}

-(void)reachabilityFlagsFound:(SCNetworkReachabilityFlags)flags{
    
    recentReachability = [self networkReachabilityForFlags:flags];
    
    for (NSValue * unretValue in _delegates){
		id<exoNetworkReachabilityMonitorDelegate> delegate = [unretValue nonretainedObjectValue];
        [delegate networkReachablityMonitor:self changedReachabilityToStatus:recentReachability];
    }    
}

- (networkReachability) networkReachabilityForFlags: (SCNetworkReachabilityFlags) flags
{

    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
    {
        // if target host is not reachable
        return networkReachabilityNotReachable;
    }
    
    networkReachability retVal = networkReachabilityNotReachable;
	
    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
    {
        // ... but WWAN connections are OK if the calling application
        //     is using the CFNetwork (CFSocketStream?) APIs.
        retVal = networkReachabilityReachableViaWWAN;
    }

    
    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
    {
        // if target host is reachable and no connection is required
        //  then we'll assume (for now) that your on Wi-Fi
        retVal = networkReachabilityReachableViaWiFi;
    }
    
    
    if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
         (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
    {
        // ... and the connection is on-demand (or on-traffic) if the
        //     calling application is using the CFSocketStream or higher APIs
        
        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
        {
            // ... and no [user] intervention is needed
            retVal = networkReachabilityReachableViaWiFi;
        }
    }
    return retVal;
}

- (void) examineReachabilityWithHostName: (NSString*) hostName;
{
    NSCAssert(reachabilityRef == NULL, @"Reachability is NOT stopped for current method!");
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, [hostName UTF8String]);

   reachabilityRef = reachability;
   localWiFiRef = NO;
}



-(void) examineReachabilityWithAddress: (const struct sockaddr_in*) hostAddress{
    NSCAssert(reachabilityRef == NULL, @"Reachability is NOT stopped for current method!");

    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)hostAddress);
    reachabilityRef = reachability;
    localWiFiRef = NO;
}

-(void)examineReachabilityForInternetConnection{
    NSCAssert(reachabilityRef == NULL, @"Reachability is NOT stopped for current method!");

    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    return [self examineReachabilityWithAddress: &zeroAddress];
}

-(void) examineReachabilityForLocalWiFi{
    NSCAssert(reachabilityRef == NULL, @"Reachability is NOT stopped for current method!");

    struct sockaddr_in localWifiAddress;
    bzero(&localWifiAddress, sizeof(localWifiAddress));
    localWifiAddress.sin_len = sizeof(localWifiAddress);
    localWifiAddress.sin_family = AF_INET;
    // IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0
    localWifiAddress.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);
    
    [self examineReachabilityWithAddress: &localWifiAddress];
    localWiFiRef = YES;
    
}



- (BOOL) _startNotifier
{
    BOOL retVal = NO;
    SCNetworkReachabilityContext    context = {0, self, NULL, NULL, NULL};
    if(SCNetworkReachabilitySetCallback(reachabilityRef, ReachabilityCallback, &context))
    {
        if(SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode))
        {
            retVal = YES;
        }
    }
    return retVal;
}

- (void) _stopNotifier
{
    if(reachabilityRef!= NULL)
    {
        SCNetworkReachabilityUnscheduleFromRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    }
}

-(id)init{
    if (self = [super init]){
        
        _delegates = [[NSMutableSet alloc] init];
        recentReachability = networkReachabilityNotChecked;

    }
    
    return self;
}



-(void)addDelegate:(id<exoNetworkReachabilityMonitorDelegate>)delegate{
    [_delegates addObject:[NSValue valueWithNonretainedObject:delegate]];
}
-(void)removeDelegate:(id<exoNetworkReachabilityMonitorDelegate>)delegate{
    [_delegates removeObject:[NSValue valueWithNonretainedObject:delegate]];
}

+(exoNetworkReachabilityMonitor*)sharedReachabilityMonitor{
    if (reachabilityMonitor == nil){
        reachabilityMonitor = [[exoNetworkReachabilityMonitor alloc] init];
		[reachabilityMonitor beginCheckingForReachability];
    }
    return reachabilityMonitor;
}

-(void)beginCheckingForReachability{
    [self examineReachabilityWithHostName:@"www.google.com"];
    
    [self _startNotifier];
}
-(void)stopCheckingForReachability{
    [self _stopNotifier];
}

-(void)refreshReachabiltyChecking{
    [self _stopNotifier];
    [self _startNotifier];
}


-(NSUInteger)retainCount{
    if (self == reachabilityMonitor)
        return UINT_MAX;
    return [super retainCount];
}

-(void)dealloc{
    
    [self _stopNotifier];
    if(reachabilityRef!= NULL)
    {
        CFRelease(reachabilityRef);
		reachabilityRef = NULL;
    }
    [_delegates release];
	_delegates = nil;
    
    [super dealloc];
}




@end
