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
-(void)	swypSessionViewControllerWantsCancel:(swypSessionViewController*)sessionViewController;
@end

@interface swypSessionViewController : UIViewController {
	swypConnectionSession *		_connectionSession;
	NSMutableSet	*			_contentLoadingThumbs;
    BOOL                        _transferringData;
	
	NSInteger					_transferIndicatorActiveCount;
}

///associated connection session
@property (nonatomic, readonly) swypConnectionSession *		connectionSession;
@property (nonatomic, readonly) NSMutableSet * contentLoadingThumbs;
@property (nonatomic, assign)   BOOL transferringData;

-(id)	initWithConnectionSession:	(swypConnectionSession*)session;
-(BOOL)	overlapsRect:(CGRect)testRect inView:(UIView*)	testView;

///The following is a 'smart' status indicator set true twice, and false once, and the thing is still indicating 
-(void) indicateTransferringData:(BOOL)isTransferring;
-(void) makeLandscape;

@end
