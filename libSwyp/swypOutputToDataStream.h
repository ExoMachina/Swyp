//
//  swypOutputToDataStream.h
//  swyp
//
//  Created by Alexander List on 1/15/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import <Foundation/Foundation.h>

@class swypOutputToDataStream;
@protocol swypOutputToDataStreamDataDelegate <NSObject>
///The method that provides data-- data must be accepted otherwise it's permanently lost
-(void)outputToDataStream:(swypOutputToDataStream*)stream wantsProvideData:(NSData*)data;

///Notifies of the closure (was open) of stream. 
-(void)outputToDataStreamWasClosed:(swypOutputToDataStream *)stream;
@end

/** This class basically just acts an NSOutputStream that takes any written bytes, shoves them in an NSData shell, the tells then tosses them at the dataDelegate */
@interface swypOutputToDataStream : NSOutputStream{
	id <swypOutputToDataStreamDataDelegate>	_dataDelegate;
}

@property(nonatomic, assign) id <swypOutputToDataStreamDataDelegate> dataDelegate;

/// The delegate is of critical importance- otherwise use something else.
-(id) initWithDataDelegate:(id <swypOutputToDataStreamDataDelegate>)delegate;

@end
