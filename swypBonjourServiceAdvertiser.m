//
//  swypBonjourServiceAdvertiser.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import "swypBonjourServiceAdvertiser.h"


@implementation swypBonjourServiceAdvertiser
@synthesize delegate = _delegate;

#pragma mark -
#pragma mark public
-(BOOL)	isAdvertising{
	
}
-(void)	setAdvertising:(BOOL)advertisingEnabled{
	
}


#pragma mark NSObject


#pragma mark -
#pragma mark private
-(void)	_setupBonjourAdvertising{
	
}
-(void) _teardownBonjourAdvertising{
	
}
-(void) _setupServerSockets{
	
}
-(void) _teardownServerSockets{
	
}

#pragma mark NSNetServiceDelegate
- (void)netServiceDidPublish:(NSNetService *)sender{
	
}
- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict{
	
}

@end
