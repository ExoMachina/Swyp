//
//  cloudSwypInManager.h
//  swyp
//
//  Created by Alexander List on 1/4/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "swypCloudNetService.h"
#import "swypInfoRef.h"

@class cloudSwypInManager;
@protocol cloudSwypInManagerDelegate <NSObject>
-(void)cloudSwypInManager:(cloudSwypInManager*)manager didReceiveSwypConnectionFromClient:(swypClientCandidate*)clientCandidate withStreamIn:(NSInputStream*)inputStream streamOut:(NSOutputStream*)outputStream;
-(void)cloudSwypInManager:(cloudSwypInManager*)manager didCreateSwypConnectionToServer:(swypServerCandidate*)serverCandidate withStreamIn:(NSInputStream*)inputStream streamOut:(NSOutputStream*)outputStream;
@end

@interface cloudSwypInManager : NSObject <swypCloudNetServiceDelegate>{
	swypCloudNetService*			_cloudService;
	
	id<cloudSwypInManagerDelegate> _delegate;
}
-(id)initWithCloudSwypInManagerDelegate:(id<cloudSwypInManagerDelegate>) delegate;

-(void)swypInCompleted:(swypInfoRef*)swyp;

//private
-(void)_postSwypToPairServer:(swypInfoRef*)swyp;

@end
