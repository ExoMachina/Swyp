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


/** 
 This UIView subclass is used by the swypWorkspaceViewController for displaying its main view, and for generating workspace views that can be embedded in custom application code.
 
 This class is instantiated using workspaceViewForEmbeddedSwypIn. 
 */
@interface swypWorkspaceView : UIView
@property (nonatomic, retain) swypWorkspaceBackgroundView *	backgroundView;
@property (nonatomic, retain) UIImageView	*				prettyOverlay;
@property (nonatomic, retain) SwypPromptImageView *			swypPromptImageView;
@property (nonatomic, retain) UIButton *					swypNetworkInterfaceClassButton;


/**This initialization is handled by swypWorkspaceViewController in workspaceViewForEmbeddedSwypIn
 @param workspace is the viewController responsible for managing all the events associated with the buttons and gesture recognizers.
 */
-(swypWorkspaceView*) initWithFrame:(CGRect)frame workspaceTarget:(id)workspace;
@end
