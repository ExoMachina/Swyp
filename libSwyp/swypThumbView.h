//
//  swypThumbView.h
//  libSwyp
//
//  Created by Ethan Sherbondy on 1/20/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SSPieProgressView.h"

/** 
 The thumbnails in the swypWorkspace are swypThumbViews.
 Because swyp first sends thumbnails before sending the
 original files, swypThumbView has a built-in progress 
 indicator.
 */

@interface swypThumbView : UIView {
    UIActivityIndicatorView *_activityIndicator;
    SSPieProgressView *_progressView;
    UIImageView *_imageView;
}

/// Convenience method returning an autoreleased thumbView
+ (swypThumbView *)thumbViewWithImage:(UIImage *)theImage;
- (id)initWithImage:(UIImage *)theImage;

/** 
 When loading is set to YES, the activity indicator and 
 progressView fade in. When set to NO, they fade out.
 */
- (void)setLoading:(BOOL)loading;

/** 
 If you need to update the thumbnail after initialization,
 just use setImage: or the synonomous dot syntax: `thumbView.image = theImage`
 */
- (void)setImage:(UIImage *)theImage;

/** 
 Expects a float between 0.0 and 1.0. Any value higher than 1 is 
 truncated to 1. 
 @see SSPieProgressView for info on its inner workings.
 */
- (void)setProgress:(CGFloat)theProgress;

// make atomic if we intend to access from multiple threads.

/** 
 The thumbnail image. 
 @see setImage:
 */
@property (nonatomic, retain) UIImage *image;

/**
 The current download progress, a float between 0.0 and 1.0.
 @see setProgress:
 */
@property (nonatomic, assign) CGFloat progress;

/**
 Indicates whether or not the file is currently loading.
 @see setLoading:
 */
@property (nonatomic, assign) BOOL loading;

@end
