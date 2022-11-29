//
//  swypThumbView.m
//  libSwyp
//
//  Created by Ethan Sherbondy on 1/20/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import "swypThumbView.h"
#import <QuartzCore/QuartzCore.h>

@implementation swypThumbView

@synthesize image = _image;
@synthesize progress = _progress;
@synthesize loading = _loading;

static float framePadding = 8.0;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _activityIndicator.size = frame.size;
        _activityIndicator.alpha = 0;
        [self insertSubview:_activityIndicator atIndex:1];
        
        _progressView = [[SSPieProgressView alloc] initWithFrame:CGRectMake(0, 0, 48, 48)];
        _progressView.center = self.center;
        _progressView.frame = CGRectOffset(_progressView.frame, framePadding, framePadding);
        _progressView.pieBorderWidth = 2.0;
        _progressView.pieBorderColor = [UIColor whiteColor];
        _progressView.pieBackgroundColor = [UIColor blackColor];
        _progressView.pieFillColor = [UIColor whiteColor];
        _progressView.alpha = 0;
        
        [self insertSubview:_progressView atIndex:2];
        
        self.userInteractionEnabled = YES;
        self.clipsToBounds = NO;
    }
    return self;
}

- (id)initWithImage:(UIImage *)theImage {
    CGRect imageFrame = CGRectMake(0, 0, theImage.size.width, theImage.size.height);
    
    self = [self initWithFrame:CGRectInset(imageFrame, -1*framePadding, -1*framePadding)];
    if (self) {
        self.image = theImage;
        _imageView = [[UIImageView alloc] initWithFrame:CGRectOffset(imageFrame, framePadding, framePadding)];
        _imageView.image = self.image;
        [self insertSubview:_imageView atIndex:0];
    }
    return self;
}

- (void)setImage:(UIImage *)theImage {
    if (theImage != self.image) {
        [_image release];
        _image = [theImage retain];
        _imageView.image = _image;
    }
}

+ (swypThumbView *)thumbViewWithImage:(UIImage *)theImage {
    return [[[swypThumbView alloc] initWithImage:theImage] autorelease];
}

- (void)setLoading:(BOOL)loading {
    _loading = loading;
    if (_loading) {
        _progressView.hidden = NO;
        [_activityIndicator startAnimating];
        [UIView animateWithDuration:1 animations:^{
            _progressView.alpha = 1;
            _activityIndicator.alpha = 1;
            _activityIndicator.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        }];
    } else {
        [UIView animateWithDuration:1 animations:^{
            _progressView.alpha = 0;
            _activityIndicator.alpha = 0;
            _activityIndicator.backgroundColor = [UIColor clearColor];
        } completion:^(BOOL finished){
            if (finished) {
                _progressView.hidden = YES;
                [_activityIndicator stopAnimating];
            }
        }];
    }
}

- (void)setProgress:(CGFloat)theProgress {
    _progress = theProgress;
    _progressView.progress = _progress;
    if (theProgress >= 1.0f) {
        self.loading = NO;
    }
}

- (void)drawRect:(CGRect)rect {
    CALayer	*layer	=	self.layer;
    layer.shadowColor = [UIColor blackColor].CGColor;
    layer.shadowOpacity = 0.9f;
    layer.shadowOffset = CGSizeMake(0, 2);
    layer.shadowRadius = 4.0;
    
    CGMutablePathRef shadowPath	= CGPathCreateMutable();
    CGPathAddRect(shadowPath, NULL, CGRectMake(0, 0, self.frame.size.width, self.frame.size.height));
    layer.shadowPath = shadowPath;
    CFRelease(shadowPath);
}

- (void)dealloc {
    [_image release];
    [_imageView release];
    [_progressView release];
    [_activityIndicator release];

    [super dealloc];
}

@end
