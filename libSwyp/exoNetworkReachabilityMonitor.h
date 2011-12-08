//
//  exoNetworkReachabilityMonitor.h
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


typedef enum networkReachability {
    networkReachabilityNotChecked = -1,
   networkReachabilityNotReachable = 0,
    networkReachabilityReachableViaWiFi,
    networkReachabilityReachableViaWWAN
} networkReachability;

@protocol exoNetworkReachabilityMonitorDelegate;

@interface exoNetworkReachabilityMonitor : NSObject {
    BOOL localWiFiRef;
    SCNetworkReachabilityRef reachabilityRef;
    
    networkReachability recentReachability;
    
    NSMutableSet *_delegates;
}

//most relevant methods
-(networkReachability)lastReachability;

-(void)addDelegate:(id<exoNetworkReachabilityMonitorDelegate>)delegate;
-(void)removeDelegate:(id<exoNetworkReachabilityMonitorDelegate>)delegate;

//intializes and begins checking
+(exoNetworkReachabilityMonitor*)sharedReachabilityMonitor;

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
- (networkReachability)networkReachabilityForFlags: (SCNetworkReachabilityFlags) flags;

@end

@protocol exoNetworkReachabilityMonitorDelegate <NSObject>
-(void)networkReachablityMonitor:(exoNetworkReachabilityMonitor*)monitor changedReachabilityToStatus:(networkReachability)reachability;
@end