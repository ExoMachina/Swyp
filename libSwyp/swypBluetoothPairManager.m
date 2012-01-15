//
//  swypBluetoothPairManager.m
//  swyp
//
//  Created by Alexander List on 1/14/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import "swypBluetoothPairManager.h"

@implementation swypBluetoothPairManager

#pragma mark swypInterfaceManager
-(void)	suspendNetworkActivity{
	
}

-(void)	resumeNetworkActivity{
	
}

-(void) advertiseSwypOutAsPending:(swypInfoRef*)ref{
	NSTimer * advertiseTimer	=	[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(_advertiseAsPendingTimedOutWithTimer:) userInfo:ref repeats:NO];
	[_swypOutTimeoutTimerBySwypInfoRef setObject:advertiseTimer forKey:[NSValue valueWithNonretainedObject:ref]];	
}

-(void) advertiseSwypOutAsCompleted:(swypInfoRef*)ref{
	NSTimer * pendingTimer	=	[_swypOutTimeoutTimerBySwypInfoRef objectForKey:[NSValue valueWithNonretainedObject:ref]];
	if (pendingTimer == nil){
		return;	
	}else{
		EXOLog(@"advertiseSwypOutAsCompleted in swypBluetoothPairManager from ref@time:%@",[[ref startDate]description]);
		[pendingTimer invalidate];
		
		NSTimer * advertiseTimer	=	[NSTimer scheduledTimerWithTimeInterval:4 target:self selector:@selector(_advertiseTimedOutWithTimer:) userInfo:ref repeats:NO];
		[_swypOutTimeoutTimerBySwypInfoRef setObject:advertiseTimer forKey:[NSValue valueWithNonretainedObject:ref]];	
		[_validSwypOutsForConnectionReceipt addObject:ref];
	}
}

-(void) stopAdvertisingSwypOut:(swypInfoRef*)ref{
	NSTimer * advertiseTimer	=	[_swypOutTimeoutTimerBySwypInfoRef objectForKey:[NSValue valueWithNonretainedObject:ref]];
	if (advertiseTimer == nil) return;
	
	[advertiseTimer invalidate];

	[_swypOutTimeoutTimerBySwypInfoRef removeObjectForKey:[NSValue valueWithNonretainedObject:ref]];	
	[_validSwypOutsForConnectionReceipt removeObject:ref];
	
	[_delegate interfaceManager:self isDoneAdvertisingSwypOutAsPending:ref forConnectionMethod:swypConnectionMethodBluetooth];
}

-(BOOL) isAdvertisingSwypOut:(swypInfoRef*)ref{
	return ([_swypOutTimeoutTimerBySwypInfoRef objectForKey:[NSValue valueWithNonretainedObject:ref]] != nil);
}

-(void)	startFindingSwypInServerCandidatesForRef:(swypInfoRef*)ref{
	NSTimer * searchTimer	=	[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(_findServersTimedOutWithTimer:) userInfo:ref repeats:NO];
	[_swypInTimeoutTimerBySwypInfoRef setObject:searchTimer forKey:[NSValue valueWithNonretainedObject:ref]];	
	[_validSwypInForConnectionCreation addObject:ref];
}

-(void) stopFindingSwypInServerCandidatesForRef:(swypInfoRef*)ref{
	[_swypInTimeoutTimerBySwypInfoRef removeObjectForKey:[NSValue valueWithNonretainedObject:ref]];
	[_validSwypInForConnectionCreation removeObject:ref];

	[_delegate interfaceManager:self isDoneAdvertisingSwypOutAsPending:ref forConnectionMethod:swypConnectionMethodBluetooth];
}

#pragma mark timeouts
-(void)_findServersTimedOutWithTimer:(NSTimer*)sender{
	[self stopFindingSwypInServerCandidatesForRef:sender.userInfo];
}
-(void)_advertiseAsPendingTimedOutWithTimer:(NSTimer*)sender{
	[self stopAdvertisingSwypOut:sender.userInfo];
}
-(void)_advertiseTimedOutWithTimer:(NSTimer*)sender{
	[self stopAdvertisingSwypOut:sender.userInfo];
}

#pragma mark NSObject
-(id) initWithInterfaceManagerDelegate:(id<swypInterfaceManagerDelegate>)delegate{
	if (self = [super init]){
		_delegate = delegate;
		_swypOutTimeoutTimerBySwypInfoRef	=	[NSMutableDictionary new];
		_validSwypOutsForConnectionReceipt	=	[NSMutableSet new];
		
		_swypInTimeoutTimerBySwypInfoRef	=	[NSMutableDictionary new];
		_validSwypInForConnectionCreation	=	[NSMutableSet new];

	}
	return self;
}

-(void)dealloc{
	SRELS(_swypOutTimeoutTimerBySwypInfoRef);
	SRELS(_validSwypOutsForConnectionReceipt);
	SRELS(_swypInTimeoutTimerBySwypInfoRef);
	SRELS(_validSwypInForConnectionCreation);
	[super dealloc];
}


#pragma mark gamekit

@end
