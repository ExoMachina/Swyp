//
//  swypBonjourServiceListener.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import <Foundation/Foundation.h>
#import "swypServerCandidate.h"

@class swypBonjourServiceListener;

@protocol swypBonjourServiceListenerDelegate <NSObject>
-(void)	bonjourServiceListenerFoundServerCandidate: (swypServerCandidate*) serverCandidate 	withListener:(swypBonjourServiceListener*) serviceListener;
-(void)	bonjourServiceListenerFailedToBeginListen:	(swypBonjourServiceListener*) serverListener	error:(NSError*)error;
@end

@interface swypBonjourServiceListener : NSObject <NSNetServiceBrowserDelegate> {
	NSMutableDictionary *	_serverCandidates; //candidates by netservice
	
	NSNetServiceBrowser	*	_serverBrowser;
	
	BOOL					_serviceIsListening;
	
	id<swypBonjourServiceListenerDelegate>	_delegate;
}
@property (nonatomic, assign)	id<swypBonjourServiceListenerDelegate>	delegate;
@property (nonatomic, assign)	BOOL	serviceIsListening;


//swypServerCandidate
-(NSSet*) allServerCandidates;



@end
