//
//  ;
//  swyp
//
//  Created by Ethan Sherbondy on 1/18/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import "SwypPromptImageView.h"
#import <QuartzCore/QuartzCore.h>

@implementation SwypPromptImageView

-(id)init {
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

    if (self = [super initWithFrame:_imageView.frame]){
        [self addSubview:_imageView];
    }
    
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

- (void) showBluetoothWaiting {
    [UIView transitionFromView:_imageView toView:_bluetoothView duration:1.0 options:UIViewAnimationOptionTransitionFlipFromLeft completion:^(BOOL completed){
        if (completed){
            NSLog(@"Flipped");
        }
    }];
}

@end
