//
//  swypPendingConnectionQueue.h
//  swyp
//
//  Created by Alexander List on 1/13/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import <Foundation/Foundation.h>

/** This class further encapsulates pending connections for the swypPendingConnectionManager.
 
	It stands for a particular swyp in the swypPendingConnectionManager, and organizes all potential swypServerCandidates by  interfacePriorityOrder.
*/
@interface swypPendingConnectionQueue : NSObject{
	NSMutableDictionary *	_pendingConnectionSessionsByInterfaceMethod;
	
	NSMutableSet *			_pendingInterfaceMethods;
}

/** mutableSet set of interface methods supported & not timed-out */
@property(nonatomic, readonly) NSMutableSet *	pendingInterfaceMethods;

/** Inits with supported interfaces
 @param supportedInterfaceMethods swypConnectionMethod(s) as NSNumber intergers in NSArray
 */
-(id)initWithInterfaceMethods:(NSArray*)supportedInterfaceMethods;

/** adds a supported interface
 If you add an interface of higher priority after the emptying of other interfaces, this might cause some undefined behavior...
 @param method swypConnectionMethod 
 */
-(void) addInterfaceMethod:(swypConnectionMethod)method;

/** Returns a mutable array for managing connection sessions within a specific connection method 
 @return returns mutable array for manipulation at will, or returns nil if either not supported or removed
 */
-(NSMutableArray*) connectionSessionArrayForInterfaceMethod:(swypConnectionMethod)connectionMethod;

/** Returns a mutable array for managing connection sessions within a specific connection method 
 @return returns mutable array for manipulation at will
 */
-(void) removeConnectionSessionArrayForInterfaceMethod:(swypConnectionMethod)connectionMethod;

/** Relates if any connectionSessionArray(s) are not nil */
-(BOOL)hasPendingConnectionSessions;

@end
