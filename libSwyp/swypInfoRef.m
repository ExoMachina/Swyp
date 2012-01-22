//
//  swypInfoRef.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import "swypInfoRef.h"


@implementation swypInfoRef
@synthesize velocity,startPoint,endPoint,startDate,endDate,swypBeginningContentView,swypType;
-(void) setSwypBeginningContentView:(UIView *)swypOutView{
	SRELS(swypBeginningContentView);
	swypBeginningContentView = [swypOutView retain];
}

-(swypScreenEdgeType)screenEdgeOfSwyp {
    CGPoint criticalPoint;
    
    switch (self.swypType) {
        case swypInfoRefTypeSwypIn:
            criticalPoint = self.startPoint;
            break;
        case swypInfoRefTypeSwypOut:
            criticalPoint = self.endPoint;
            break;
        default:
            return swypScreenEdgeTypeBottom;
    }
    
    CGSize screenSize = [UIScreen mainScreen].applicationFrame.size;
    if (criticalPoint.x < 40) {
        return swypScreenEdgeTypeLeft;
    } else if (criticalPoint.x > (screenSize.width - 40)) {
        return swypScreenEdgeTypeRight;
    } else if (criticalPoint.y > (screenSize.height - 40)) {
        return  swypScreenEdgeTypeBottom;
    } else {
        return swypScreenEdgeTypeTop;
    }
}

-(void)dealloc{
	SRELS(swypBeginningContentView);
	SRELS(startDate);
	SRELS(endDate);
	[super dealloc];
}

@end
