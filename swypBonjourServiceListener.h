//
//  swypBonjourServiceListener.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- check online.
//

#import <Foundation/Foundation.h>
#import "swypServerCandidate.h"

@class swypBonjourServiceListener;

@protocol swypBonjourServiceListenerDelegate <NSObject>
-(void)	bonjourServiceListenerFoundServerCandidate: (swypServerCandidate*) serverCandidate;
@end

@interface swypBonjourServiceListener : NSObject <NSNetServiceDelegate> {
	NSMutableSet *		serverCandidates;
}
//swypServerCandidate
-(NSSet*) allServerCandidates;

-(BOOL)	isListening;
-(void)	setListening:(BOOL)listeningEnabled;
@end
