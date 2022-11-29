//
//  SwypPromptImageView.h
//  swyp
//
//  Created by Ethan Sherbondy on 1/18/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 This is the view for the swyp icon in the center of the swyp Workspace
 */

@interface SwypPromptImageView : UIView {
    UIImageView *_imageView;
    UIView *_bluetoothView;
	
	BOOL	hasDoneFirstPromptDisplay;
}

/** 
 This performs a flip animation to/from the regular swyp icon once
 bluetooth is on and ready to accept connections.
 */
- (void) showBluetoothLoadingPrompt:(BOOL)show;

@end
