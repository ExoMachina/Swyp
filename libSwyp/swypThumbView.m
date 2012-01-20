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

@synthesize image;

static float framePadding = 8.0;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self insertSubview:_activityIndicator atIndex:1];
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
    self.image = theImage;
    _imageView.image = self.image;
}

+ (swypThumbView *)thumbViewWithImage:(UIImage *)theImage {
    return [[[swypThumbView alloc] initWithImage:theImage] autorelease];
}

- (void)showLoading {
    [_activityIndicator startAnimating];
}

- (void)hideLoading {
    [_activityIndicator stopAnimating];
}

- (void)drawRect:(CGRect)rect
{
    CALayer	*layer	=	self.layer;
    [layer setShadowColor:[UIColor blackColor].CGColor];
    [layer setShadowOpacity:0.9f];
    [layer setShadowOffset: CGSizeMake(1, 3)];
    [layer setShadowRadius:4.0];
    
    CGMutablePathRef shadowPath	= CGPathCreateMutable();
    CGPathAddRect(shadowPath, NULL, self.frame);
    [layer setShadowPath:shadowPath];
    CFRelease(shadowPath);
    
    [self setClipsToBounds:NO];
}

- (void)dealloc {
    [image release];
    [_imageView release];
    [_activityIndicator release];

    [super dealloc];
}

@end
