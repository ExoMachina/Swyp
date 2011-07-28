//
//  swypBonjourServiceAdvertiser.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import <Foundation/Foundation.h>
#import "swypClientCandidate.h"

@class swypBonjourServiceAdvertiser;

@protocol swypBonjourServiceAdvertiserDelegate <NSObject>
-(void)	bonjourServiceAdvertiserReceivedConnectionFromSwypClientCandidate:(swypClientCandidate*)clientCandidate withStreamIn:(NSInputStream*)inputStream streamOut:(NSOutputStream*)outputStream; 
@end


@interface swypBonjourServiceAdvertiser : NSObject <NSNetServiceDelegate>  {

}

-(BOOL)	isAdvertising;
-(void)	setAdvertising:(BOOL)advertisingEnabled;



@end
