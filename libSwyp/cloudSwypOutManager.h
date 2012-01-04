//
//  cloudSwypOutManager.h
//  swyp
//
//  Created by Alexander List on 1/4/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "swypInfoRef.h"
#import "swypCloudNetService.h"


@class cloudSwypOutManager;
@protocol cloudSwypOutManagerDelegate <NSObject>
-(void)cloudSwypOutManager:(cloudSwypOutManager*)manager didReceiveSwypConnectionFromClient:(swypClientCandidate*)clientCandidate withStreamIn:(NSInputStream*)inputStream streamOut:(NSOutputStream*)outputStream;
-(void)cloudSwypOutManager:(cloudSwypOutManager*)manager didCreateSwypConnectionToServer:(swypServerCandidate*)serverCandidate withStreamIn:(NSInputStream*)inputStream streamOut:(NSOutputStream*)outputStream;
@end

@interface cloudSwypOutManager : NSObject <swypCloudNetServiceDelegate>{
	swypCloudNetService*			_cloudService;
	
	id<cloudSwypOutManagerDelegate> _delegate;
}
-(id)initWithCloudSwypOutManagerDelegate:(id<cloudSwypOutManagerDelegate>) delegate;

-(void)swypOutBegan:(swypInfoRef*)swyp;
-(void)swypOutCompleted:(swypInfoRef*)swyp;
-(void)swypOutFailed:(swypInfoRef*)swyp;

//private
-(void)_postSwypToPairServer:(swypInfoRef*)swyp;
-(void)_putSwypUpdateToPairServer:(swypInfoRef*)swyp;
-(void)_deleteSwypFromPairServer:(swypInfoRef*)swyp;
-(void)_updateSwypPairStatus:(swypInfoRef*)swyp;

@end
