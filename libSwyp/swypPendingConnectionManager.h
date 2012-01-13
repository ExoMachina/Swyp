//
//  swypPendingConnectionManager.h
//  swyp
//
//  Created by Alexander List on 1/12/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import <Foundation/Foundation.h>
@class swypPendingConnectionManager;

@protocol swypPendingConnectionManagerDelegate <NSObject>

/**	
	callback is called only after a connectionMethodTimedOut: or addSwypClientCandidate:forSwypRef:forConnectionMethod:
		* not called after a nextConnectionSessionToAttemptHandshakeForSwypRef:
			instead, you should call nextConnectionSessionToAttemptHandshakeForSwypRef: until == nil
*/
-(void)	swypPendingConnectionManagerHasAvailableHandshakeableConnectionSessionsForSwyp:(swypInfoRef*)ref;

/** Called anytime ref is no longer needed; including clearAllPendingConnectionsForSwypRef */
-(void)	swypPendingConnectionManagerFinishedForSwyp:(swypInfoRef*)ref;
@end

/**
 This class is key in managing the prioritization of connection accross multiple interfaces. 
 It communicates directly with swypConnectionManager to ensure priorities are kept. 
 Prioritization occurs through the comparative value of each swypConnectionMethod
*/

@interface swypPendingConnectionManager : NSObject{	
}

/** After swypConnnectionManager posts swypInfoRef to an interface, it sets it as pending here */
-(void) setSwypOutPending:(swypInfoRef*)swypRef forConnectionMethods:(swypConnectionMethod)methods;

/**
 This tells the manager that an interface method will no longer send new candidates
 This allows the manager to clear out deadspace and proceed to call swypPendingConnectionManagerHasAvailableHandshakeableConnectionSessionsForSwyp:
 */
-(void) connectionMethodTimedOut:(swypConnectionMethod)method forSwypRef:(swypInfoRef*)swypRef;

/** After swypConnnectionManager has found its match for a swypCandidate, it acts responsibly by calling this method */
-(void) clearAllPendingConnectionsForSwypRef:(swypInfoRef*)ref;

/**
 After a swypConnectionMethod has returned a swypCandidate to swypConnnectionManager, swypConnnectionManager calls this method to add it to the queue for a specific swypInfoRef.
 */
-(void)	addSwypClientCandidate:(swypClientCandidate*)candidate forSwypRef:(swypInfoRef*)ref forConnectionMethod:(swypConnectionMethod)method;

/**
 This method is called by swypConnnectionManager after the delegate protocol swypPendingConnectionManagerHasAvailableHandshakeableConnectionSessionsForSwyp: is called
 */
-(swypConnectionSession*)	nextConnectionSessionToAttemptHandshakeForSwypRef:(swypInfoRef*)ref;

@end
