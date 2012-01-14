//
//  swypPendingConnectionManager.h
//  swyp
//
//  Created by Alexander List on 1/12/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "swypPendingConnectionQueue.h"

@class swypPendingConnectionManager;

@protocol swypPendingConnectionManagerDelegate <NSObject>

/**	
	Callback is called to indicate swypConnectionSession(s) are available for use by connection manager. 
	Callback is called only after a connectionMethodTimedOut: or addSwypClientCandidate:forSwypRef:forConnectionMethod:.
	
	@warning this method is not called after a nextConnectionSessionToAttemptHandshakeForSwypRef:, nor is there a runloop managing this method. Instead, you should call nextConnectionSessionToAttemptHandshakeForSwypRef: until == nil.
 
	 @param ref a swypInfoRef that's been added by the swypConnectionManager
*/
-(void)	swypPendingConnectionManager:(swypPendingConnectionManager*)manager hasAvailableHandshakeableConnectionSessionsForSwyp:(swypInfoRef*)ref;

/** Called when swypInforef is no longer needed; including clearAllPendingConnectionsForSwypRef 
 
 @param ref a swypInfoRef that's no longer needed
 */
-(void)	swypPendingConnectioManager:(swypPendingConnectionManager*)manager finishedForSwyp:(swypInfoRef*)ref;
@end

/**
 This class is key in managing the prioritization of connection accross multiple interfaces. 
 
 It communicates directly with swypConnectionManager to ensure priorities are kept. 
 After a 
 
 Prioritization occurs through the comparative value of each swypConnectionMethod. See prioritizedInterfaceMethodsArray for manually entered priority.
 

 */

@interface swypPendingConnectionManager : NSObject{	
	
	id<swypPendingConnectionManagerDelegate>	_delegate;
	
	NSMutableDictionary *	_allPendingSwypConnectionQueuesBySwypInfoRef;
}

/** swypPendingConnectionManager is initialized with probably swypConnectionManager as delegate */
-(id) initWithDelegate:(id<swypPendingConnectionManagerDelegate>)delegate;

/** After swypConnnectionManager posts swypInfoRef to an interface, it sets it as pending here 
	@param methods NSArray of swypConnectionMethod in NSNumber objects as ints
 */
-(void) setSwypOutPending:(swypInfoRef*)swypRef forConnectionMethods:(NSArray*)methods;

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
-(void)	addSwypClientCandidateConnectionSession:(swypConnectionSession*)connectionSession forSwypRef:(swypInfoRef*)ref forConnectionMethod:(swypConnectionMethod)method;

/**
 This method is called by swypConnnectionManager after the delegate protocol swypPendingConnectionManagerHasAvailableHandshakeableConnectionSessionsForSwyp: is called
 */
-(swypConnectionSession*)	nextConnectionSessionToAttemptHandshakeForSwypRef:(swypInfoRef*)ref;


/**
 A nice array for iterating over all the interfaceMethods defined in swypConnectionMethod
 @return returns NSArray of NSNumber objects init'd w/ int of swypConnectionMethod
 */
-(NSArray*)prioritizedInterfaceMethodsArray;

//
//Private
-(void) _processConnectionAvailabilityForSwypRef:(swypInfoRef*)ref;
@end
