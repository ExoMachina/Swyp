//
//  swypNetworkAccessMonitor.h
//  exoLib
//
//  Created by Alexander List on 7/27/10.
//  Copyright (c) 2010 List Consulting. All rights reserved.
//

//makes it easier to have an entire project determine its network connectivity

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>


typedef enum swypNetworkAccess {
    swypNetworkAccessNotChecked = -1,
   swypNetworkAccessNotReachable = 0,
    swypNetworkAccessReachableViaWiFi,
    swypNetworkAccessReachableViaWWAN
} swypNetworkAccess;

@protocol swypNetworkAccessMonitorDelegate;

@interface swypNetworkAccessMonitor : NSObject {
    BOOL localWiFiRef;
    SCNetworkReachabilityRef reachabilityRef;
    
    swypNetworkAccess recentReachability;
    
    NSMutableSet *_delegates;
}

//most relevant methods
-(swypNetworkAccess)lastReachability;

-(void)addDelegate:(id<swypNetworkAccessMonitorDelegate>)delegate;
-(void)removeDelegate:(id<swypNetworkAccessMonitorDelegate>)delegate;

//intializes and begins checking
+(swypNetworkAccessMonitor*)sharedReachabilityMonitor;

///****** LESS RELEVANT:
-(void)beginCheckingForReachability;
-(void)stopCheckingForReachability;
-(void)refreshReachabiltyChecking;

- (BOOL)_startNotifier;
- (void)_stopNotifier;

- (void) examineReachabilityWithHostName: (NSString*) hostName;
-(void)reachabilityFlagsFound:(SCNetworkReachabilityFlags)flags;
-(void) examineReachabilityWithAddress: (const struct sockaddr_in*) hostAddress;
-(void)examineReachabilityForInternetConnection;
-(void) examineReachabilityForLocalWiFi;
- (swypNetworkAccess)swypNetworkAccessForFlags: (SCNetworkReachabilityFlags) flags;

@end

@protocol swypNetworkAccessMonitorDelegate <NSObject>
-(void)networkReachablityMonitor:(swypNetworkAccessMonitor*)monitor changedReachabilityToStatus:(swypNetworkAccess)reachability;
@end