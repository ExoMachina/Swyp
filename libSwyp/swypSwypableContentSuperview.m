//
//  swypSwypableContentSuperview.m
//  libSwyp
//
//  Created by Alexander List on 1/31/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import "swypSwypableContentSuperview.h"

@implementation swypSwypableContentSuperview

-(id)	initWithContentDelegate:(id<swypSwypableContentSuperviewContentDelegate>)contentDelegate workspaceDelegate:(id<swypSwypableContentSuperviewWorkspaceDelegate>)workspaceDelegate frame:(CGRect)frame{
	if (self = [super initWithFrame:frame]){
		_superviewContentDelegate	= contentDelegate;
		_superviewWorkspaceDelegate	= workspaceDelegate;
		
	}
	return self;
}
-(id)initWithFrame:(CGRect)frame{
	return nil;
}
-(id)init{
	return nil;
}
@end
