//
//  swypThumbView.h
//  libSwyp
//
//  Created by Ethan Sherbondy on 1/20/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface swypThumbView : UIView {
    UIActivityIndicatorView *_activityIndicator;
    UIImageView *_imageView;
}

+ (swypThumbView *)thumbViewWithImage:(UIImage *)theImage;
- (id)initWithImage:(UIImage *)theImage;
- (void)showLoading;
- (void)hideLoading;
- (void)setImage:(UIImage *)theImage;

// make atomic if we intend to access from multiple threads.
@property (nonatomic, retain) UIImage *image;

@end
