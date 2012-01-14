//
//  swypInterfaceManager.h
//  swyp
//
//  Created by Alexander List on 1/14/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "libSwyp.h"


/** Defines how network interfaces should behave */
@protocol swypInterfaceManager <NSObject>

///@name network
/** Pause network activity on this interface. Ususally app is going background. 
 
 Stop advertising, stop finding, but call delegate callbacks about that.*/
-(void)	suspendNetworkActivity;

/** Allow network activity to resume on this interface. Ususally app is going foreground, or workspace is opening for first time.
 
 Don't restart stuff that was paused.*/
-(void)	resumeNetworkActivity;

///@name swypOut
/** Begin advertising a specifc swypOut. Don't accept any connections from it yet as it hasn't completed successfully.
 
 Set a timeout for advertisement; let swypInterfaceManagerDelegate know when expired. */
-(void) advertiseSwypOutAsPending:(swypInfoRef*)ref;

/** Continue advertising specifc swypOut, perhaps updating with finalized swyp-info where necessary. Accept connections.
 
 Set a timeout for advertisement; let swypInterfaceManagerDelegate know when expired. */
-(void) advertiseSwypOutAsCompleted:(swypInfoRef*)ref;


/** No longer advertise a swyp out; remove from reference queue. No longer accept a connection for it (if an interface is able to tell this). 
 
 	Do not send further delegate messages with this ref. */
-(void) stopAdvertisingSwypOut:(swypInfoRef*)ref;


///@name swypIn

/** Start looking for and resolving for any networked candidates. Candidates are returned to swypInterfaceManagerDelegate.
 
  Set a timeout for search; let swypInterfaceManagerDelegate know when expired.
 */
-(void)	startFindingSwypInServerCandidatesForRef:(swypInfoRef*)ref;

/** No longer search for additional swypIn servers for this ref; remove from reference queue. 
	
	Do not send further delegate messages with this ref. */
-(void) stopFindingSwypInServerCandidatesForRef:(swypInfoRef*)ref;

@end


@protocol swypInterfaceManagerDelegate <NSObject>

/** This method decrements a given swyp in the swypHandShakeManger's dereferenceSwypOutAsPending */
-(void) interfaceManager:(id<swypInterfaceManager>)manager isDoneAdvertisingSwypOutAsPending:(swypInfoRef*)ref forConnectionMethod:(swypConnectionMethod)method; 

/** This method let's the swypConnectionManager know that this interface is no longer searching for candidates, and that it can proceed through to the lower priorities in swypPendingConnectionQueue */
-(void)interfaceManager:(id<swypInterfaceManager>)manager isDoneSearchForSwypOutServerCandidatesForRef:(swypInfoRef*)ref forConnectionMethod:(swypConnectionMethod)method;

/** This method triggers when the interface has found a server candidate and made a connection session out of it.
 
	These sessions will go to the swypPendingConnectionQueue to be pulled one-by-one by the swypConnectionManager. 
 */
-(void)interfaceManager:(id<swypInterfaceManager>)manager madeUninitializedSwypServerCandidateConnectionSession:(swypConnectionSession*)connectionSession forRef:(swypInfoRef*)ref withConnectionMethod:(swypConnectionMethod)method;

/** This method triggers when the interface has received a client candidate connection and has made session out of it w/ out intitializing it.
 
 These sessions will go to the swypHandshakeManager to begin connecting to their respective servers. */
-(void)interfaceManager:(id<swypInterfaceManager>)manager receivedUninitializedSwypClientCandidateConnectionSession:(swypConnectionSession*)connectionSession forRef:(swypInfoRef*)ref withConnectionMethod:(swypConnectionMethod)method;

@end