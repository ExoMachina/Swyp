//
//  swypThumbView.h
//  libSwyp
//
//  Created by Ethan Sherbondy on 1/20/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SSPieProgressView.h"

@interface swypThumbView : UIView {
    UIActivityIndicatorView *_activityIndicator;
    SSPieProgressView *_progressView;
    UIImageView *_imageView;
}

+ (swypThumbView *)thumbViewWithImage:(UIImage *)theImage;
- (id)initWithImage:(UIImage *)theImage;
- (void)showLoading;
- (void)hideLoading;
- (void)setImage:(UIImage *)theImage;
- (void)setProgress:(CGFloat)theProgress;

// make atomic if we intend to access from multiple threads.
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, assign) CGFloat progress;

@end
