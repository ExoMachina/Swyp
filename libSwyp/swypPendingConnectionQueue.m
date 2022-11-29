//
//  swypPendingConnectionQueue.m
//  swyp
//
//  Created by Alexander List on 1/13/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import "swypPendingConnectionQueue.h"

@implementation swypPendingConnectionQueue
@synthesize pendingInterfaceMethods = _pendingInterfaceMethods;

-(id)initWithInterfaceMethods:(NSArray*)supportedInterfaceMethods{
	if (self = [super init]){
		_pendingConnectionSessionsByInterfaceMethod	=	[NSMutableDictionary new];
		for (NSNumber * method in supportedInterfaceMethods){
			[_pendingConnectionSessionsByInterfaceMethod setObject:[NSMutableArray array] forKey:method];
		}
		_pendingInterfaceMethods	=	[[NSMutableSet setWithArray:supportedInterfaceMethods] retain];
	}
	return self;
}
-(void)dealloc{
	SRELS(_pendingConnectionSessionsByInterfaceMethod);
	SRELS(_pendingInterfaceMethods);
	[super dealloc];
}

-(void) addInterfaceMethod:(swypConnectionMethod)method{
	if ([_pendingInterfaceMethods containsObject:[NSNumber numberWithInt:method]]){
		//already contained
		return;
	}
	
	[_pendingConnectionSessionsByInterfaceMethod setObject:[NSMutableArray array] forKey:[NSNumber numberWithInt:method]];
	[_pendingInterfaceMethods addObject:[NSNumber numberWithInt:method]];
}

-(NSMutableArray*) connectionSessionArrayForInterfaceMethod:(swypConnectionMethod)connectionMethod{
	return [_pendingConnectionSessionsByInterfaceMethod objectForKey:[NSNumber numberWithInt:connectionMethod]];
}

-(void) removeConnectionSessionArrayForInterfaceMethod:(swypConnectionMethod)connectionMethod{
	[_pendingConnectionSessionsByInterfaceMethod removeObjectForKey:[NSNumber numberWithInt:connectionMethod]];
	[_pendingInterfaceMethods removeObject:[NSNumber numberWithInt:connectionMethod]];
}

-(BOOL)hasPendingConnectionSessions{
	return ([[_pendingConnectionSessionsByInterfaceMethod allKeys] count] > 0);
}

@end
