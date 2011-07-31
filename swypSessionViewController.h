//
//  swypSessionViewController.h
//  swyp
//
//  Created by Alexander List on 7/29/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "swypConnectionSession.h"

@interface swypSessionViewController : UIViewController {
	swypConnectionSession *		_connectionSession;
}
@property (nonatomic, readonly) swypConnectionSession *		connectionSession;

-(id)	initWithConnectionSession:	(swypConnectionSession*)session;

@end
