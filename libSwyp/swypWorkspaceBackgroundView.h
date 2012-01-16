//
//  swypWorkspaceBackgroundView.h
//  swyp
//
//  Created by Alexander List on 8/2/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface swypWorkspaceBackgroundView : UIView {

	NSMutableDictionary *					_touchToPathCoordinationDictionary;
	
}

-(void)	redisplayPaths;

@end
