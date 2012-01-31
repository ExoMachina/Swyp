//
//  SwypPromptImageView.m
//  swyp
//
//  Created by Ethan Sherbondy on 1/18/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import "SwypPromptImageView.h"
#import <QuartzCore/QuartzCore.h>

@implementation SwypPromptImageView

-(id)init {
    if (self = [super initWithFrame:_imageView.frame]){
        _imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"swypPromptHud"]];
        _bluetoothView = [[UIView alloc] initWithFrame:_imageView.frame];
        
        _bluetoothView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
        _bluetoothView.layer.cornerRadius = 12;
        
        UIImageView *bluetoothImage = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bluetooth-logo-enabled"]] autorelease];
        bluetoothImage.center = _bluetoothView.center;
        UIActivityIndicatorView *bluetoothIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
        bluetoothIndicator.center = _bluetoothView.center;
        
        [_bluetoothView addSubview:bluetoothImage];
        [_bluetoothView addSubview:bluetoothIndicator];
        
        [bluetoothIndicator startAnimating];
        
        [self addSubview:_imageView];
    }
    
    [self showBluetoothLoadingPrompt:NO];
    
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    return [self init];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    return [self init];
}

-(void)dealloc {
    [_imageView release];
    [_bluetoothView release];
    [super dealloc];
}

- (void) showBluetoothLoadingPrompt:(BOOL)showBT {
    [UIView transitionFromView:(showBT ? _imageView: _bluetoothView)
                        toView:(showBT ?  _bluetoothView : _imageView) 
                      duration:1.0 options:(UIViewAnimationOptionTransitionFlipFromLeft|UIViewAnimationOptionBeginFromCurrentState)
                    completion:^(BOOL completed){
        if (completed){
//            EXOLog(@"Flipped %i", isReady);
        }
    }];
}

@end
