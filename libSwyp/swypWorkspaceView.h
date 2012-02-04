//
//  swypWorkspaceView.h
//  libSwyp
//
//  Created by Alexander List on 2/4/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "swypInGestureRecognizer.h"
#import "swypOutGestureRecognizer.h"
#import "swypSessionViewController.h"
#import "swypWorkspaceBackgroundView.h"
#import "swypPromptImageView.h"

@interface swypWorkspaceView : UIView
@property (nonatomic, retain) swypWorkspaceBackgroundView * backgroundView;
@property (nonatomic, retain) 	UIImageView	*						prettyOverlay;
@property (nonatomic, retain) SwypPromptImageView *				swypPromptImageView;
@property (nonatomic, retain) UIButton *							swypNetworkInterfaceClassButton;


-(swypWorkspaceView*) initWithFrame:(CGRect)frame workspaceTarget:(id)workspace;
@end
