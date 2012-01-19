//
//  SwypPromptImageView.h
//  swyp
//
//  Created by Ethan Sherbondy on 1/18/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SwypPromptImageView : UIView {
    UIImageView *_imageView;
    UIView *_bluetoothView;
}

- (void) setBluetoothReady:(BOOL)isWaiting;

@end
