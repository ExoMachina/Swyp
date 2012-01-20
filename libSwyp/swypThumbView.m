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

- (id)initWithImageView:(UIImageView *)theImage {
    
    self = [self initWithFrame:CGRectInset(theImage.frame, -1*framePadding, -1*framePadding)];
    if (self) {
        self.image = theImage;
        self.image.frame = CGRectOffset(self.image.frame, framePadding, framePadding);
        [self insertSubview:self.image atIndex:0];
    }
    return self;
}

+ (swypThumbView *)thumbViewWithImage:(UIImageView *)theImage {
    return [[[swypThumbView alloc] initWithImageView:theImage] autorelease];
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
    [_activityIndicator release];
    [image release];
    [super dealloc];
}

@end
