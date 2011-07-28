//
//  swypServerCandidate.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- check online.
//

#import <Foundation/Foundation.h>
#import "swypCandidate.h"

@interface swypServerCandidate : swypCandidate <NSNetServiceDelegate> {
	NSNetService*		netService;

}
/*
	this one is valid only for server candidates
	if the service stops, the netService property will be set to nil
*/
@property (nonatomic, retain) NSNetService*		netService;

@end
