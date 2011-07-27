//
//  swypBonjourServiceListener.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- check online.
//

#import <Foundation/Foundation.h>
#import "swypClientCandidate.h"

@class swypBonjourServiceListener;

@protocol swypBonjourServiceListenerDelegate <NSObject>
-(void) receivedClientConnectionFromCandidate:(swypClientCandidate*) withReadStream:(NSInputStream*)inputStream writeStream:(NSOutputStream*)outputStream;
@end


@interface swypBonjourServiceListener : NSObject {

}
-(BOOL)	isListening;
-(void)	setListening:(BOOL)listeningEnabled;
@end
