//
//  swypPendingConnectionManager.m
//  swyp
//
//  Created by Alexander List on 1/12/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import "swypPendingConnectionManager.h"

@implementation swypPendingConnectionManager

#pragma mark - public
#pragma mark swyps
-(void) setSwypOutPending:(swypInfoRef*)swypRef forConnectionMethods:(NSArray*)methods{
	if ((swypRef && [methods count] > 0) == NO) return;

	[_allPendingSwypConnectionQueuesBySwypInfoRef setObject:[[[swypPendingConnectionQueue alloc] initWithInterfaceMethods:methods] autorelease] forKey:[NSValue valueWithNonretainedObject:swypRef]];
}

-(void) connectionMethodTimedOut:(swypConnectionMethod)method forSwypRef:(swypInfoRef*)ref{
	swypPendingConnectionQueue	* existingQueue	=	[_allPendingSwypConnectionQueuesBySwypInfoRef objectForKey:[NSValue valueWithNonretainedObject:ref]];
	
	if (existingQueue == nil) return;
	
	[[existingQueue pendingInterfaceMethods] removeObject:[NSNumber numberWithInt:method]];
	
	NSMutableArray * arrayForMethod	=	[existingQueue connectionSessionArrayForInterfaceMethod:method];
	if (arrayForMethod != nil && [arrayForMethod count] == 0){
		[existingQueue removeConnectionSessionArrayForInterfaceMethod:method];
	}
	
	[self _processConnectionAvailabilityForSwypRef:ref];
}

-(void) clearAllPendingConnectionsForSwypRef:(swypInfoRef*)ref{
	swypPendingConnectionQueue	* existingQueue	=	[_allPendingSwypConnectionQueuesBySwypInfoRef objectForKey:[NSValue valueWithNonretainedObject:ref]];
	
	if (existingQueue == nil) return;
	
	[_allPendingSwypConnectionQueuesBySwypInfoRef removeObjectForKey:[NSValue valueWithNonretainedObject:ref]]; 
	[_delegate swypPendingConnectioManager:self finishedForSwyp:ref];
}

-(void)	addSwypClientCandidateConnectionSession:(swypConnectionSession*)connectionSession forSwypRef:(swypInfoRef*)ref forConnectionMethod:(swypConnectionMethod)method{
	swypPendingConnectionQueue	* existingQueue	=	[_allPendingSwypConnectionQueuesBySwypInfoRef objectForKey:[NSValue valueWithNonretainedObject:ref]];
	
	if (existingQueue == nil) return;
	
	NSMutableArray * arrayForMethod	=	[existingQueue connectionSessionArrayForInterfaceMethod:method];
	
	if (arrayForMethod == nil)
		return;
	
	[arrayForMethod addObject:connectionSession];
	
	[self _processConnectionAvailabilityForSwypRef:ref];
}

-(swypConnectionSession*)	nextConnectionSessionToAttemptHandshakeForSwypRef:(swypInfoRef*)ref{
	swypPendingConnectionQueue	* existingQueue	=	[_allPendingSwypConnectionQueuesBySwypInfoRef objectForKey:[NSValue valueWithNonretainedObject:ref]];
	
	if (existingQueue == nil) return nil;
	
	if ([existingQueue hasPendingConnectionSessions] == NO){
		[self clearAllPendingConnectionsForSwypRef:ref];
		return nil;
	}
	
	swypConnectionSession * nextSession = nil;
	for (NSNumber * interfaceMethod in [self prioritizedInterfaceMethodsArray]){
		NSMutableArray * arrayForMethod	=	[existingQueue connectionSessionArrayForInterfaceMethod:[interfaceMethod intValue]];
		//if the array for interface method is not nil but zero, we wait for it to clear out
		//	the clearout is done only by timeout, or after a connection is popped
		if (arrayForMethod != nil){
			if ([arrayForMethod count] == 0){
				nextSession	=	nil;
				break;
			}else{
				nextSession	=	[arrayForMethod objectAtIndex:0];
				[arrayForMethod removeObjectAtIndex:0];
				
				//we'll see if it's safe to remove the interface from queue
				if ([arrayForMethod count] == 0){
					if ([[existingQueue pendingInterfaceMethods] containsObject:interfaceMethod] == NO){

						//not pending an update from interface -- let's axe it.
						[existingQueue removeConnectionSessionArrayForInterfaceMethod:[interfaceMethod intValue]];
					}
				}
				break;
			}
		}
		
	}
		
	return nextSession;
}


-(NSArray*)prioritizedInterfaceMethodsArray{
	NSMutableArray * methodsArray = [NSMutableArray array];
	[methodsArray addObject:[NSNumber numberWithInt:swypConnectionMethodWifiLoc]];
	[methodsArray addObject:[NSNumber numberWithInt:swypConnectionMethodWifiCloud]];
	[methodsArray addObject:[NSNumber numberWithInt:swypConnectionMethodWWANCloud]];
	[methodsArray addObject:[NSNumber numberWithInt:swypConnectionMethodBluetooth]];
	
	return methodsArray;
}


#pragma mark NSObject
-(id) initWithDelegate:(id<swypPendingConnectionManagerDelegate>)delegate{
	if (self = [super init]){
		_delegate	=	delegate;
		
		_allPendingSwypConnectionQueuesBySwypInfoRef = [[NSMutableDictionary alloc] init];
	}
	return self;
}

-(void) dealloc{
	_delegate = nil;
	SRELS(_allPendingSwypConnectionQueuesBySwypInfoRef);
	
	[super dealloc];
}

#pragma mark - private
-(void) _processConnectionAvailabilityForSwypRef:(swypInfoRef*)ref{
	swypPendingConnectionQueue	* existingQueue	=	[_allPendingSwypConnectionQueuesBySwypInfoRef objectForKey:[NSValue valueWithNonretainedObject:ref]];
	
	if ([existingQueue hasPendingConnectionSessions] == NO){
		//if everything is empty, let's clear and close out
		[self clearAllPendingConnectionsForSwypRef:ref];
	}else{
		//otherwise, let's iterate by priority, and see if we're ready to go
		for (NSNumber* interface in [self prioritizedInterfaceMethodsArray]){
			NSMutableArray * arrayForInterface = [existingQueue connectionSessionArrayForInterfaceMethod:[interface intValue]];
			
			if (arrayForInterface != nil){

				if ([arrayForInterface count] > 0){
					[_delegate swypPendingConnectionManager:self hasAvailableHandshakeableConnectionSessionsForSwyp:ref];
				}
				
				break;
			}
		}
	}
	
}

@end
