//
//  swypSessionViewController.h
//  swyp
//
//  Created by Alexander List on 7/29/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "swypConnectionSession.h"

@class swypSessionViewController;
@protocol swypSessionViewControllerDelegate <NSObject>
-(void)	swypSessionViewControllerWantsCancel:(swypSessionViewController*)sessionViewController;//press and hold make glow red
-(void)	swypSessionViewControllerWantsSecurityIncrease:(swypSessionViewController*)sessionViewController;//single tap on padlock
@end

@interface swypSessionViewController : UIViewController {
	swypConnectionSession *		_connectionSession;
	
	BOOL						_showActiveTransferIndicator; 
	UIActivityIndicatorView	*	_activityIndicator;
}
@property (nonatomic, readonly) swypConnectionSession *		connectionSession;
@property (nonatomic, assign)	BOOL						showActiveTransferIndicator;

-(id)	initWithConnectionSession:	(swypConnectionSession*)session;
-(BOOL)	overlapsRect:(CGRect)testRect inView:(UIView*)	testView;

@end
