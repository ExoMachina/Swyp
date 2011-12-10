//
//  UIViewAdditions+swypAdditions.m
//  swyp
//
//  Created by Alexander List on 9/5/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import "UIViewAdditions+swypAdditions.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIView(swypAdditions)


- (CGPoint)origin {
	return self.frame.origin;
}

- (void)setOrigin:(CGPoint)origin {
	CGRect frame = self.frame;
	frame.origin = origin;
	self.frame = frame;
}

- (CGSize)size {
	return self.frame.size;
}

- (void)setSize:(CGSize)size {
	CGRect frame = self.frame;
	frame.size = size;
	self.frame = frame;
}

- (CGFloat)width {
	return self.frame.size.width;
}

- (void)setWidth:(CGFloat)width {
	CGRect frame = self.frame;
	frame.size.width = width;
	self.frame = frame;
}

- (CGFloat)height {
	return self.frame.size.height;
}

- (void)setHeight:(CGFloat)height {
	CGRect frame = self.frame;
	frame.size.height = height;
	self.frame = frame;
}


+(void)performPageSwitchAnimationWithExistingView:(UIView*)existingView viewUpdateBlock:(void (^)(void))updateBlock nextViewGrabBlock:(UIView* (^)(void))nextViewGrabBlockOrNil direction:(UIViewPageAnimationDirection)animationDirection{
	
	CGPoint previousOrigin = existingView.frame.origin;
	
	CGSize layerSize = existingView.frame.size;
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef previousImageContext = CGBitmapContextCreate(NULL, (int)layerSize.width, (int)layerSize.height, 8, (int)layerSize.width * 4, colorSpace, kCGImageAlphaPremultipliedLast);
	CGContextTranslateCTM(previousImageContext, 0, layerSize.height);
	CGContextScaleCTM(previousImageContext, 1.0, -1.0);
	
	[existingView.layer renderInContext:previousImageContext];	
	
	CGImageRef previousLayerImage = CGBitmapContextCreateImage(previousImageContext);
	
	UIGraphicsEndImageContext();	
	CGContextRelease(previousImageContext);
	CGColorSpaceRelease(colorSpace);
	
	UIImageView *animationImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithCGImage:previousLayerImage]];
	
	CGImageRelease(previousLayerImage);
	
	
	[animationImageView setOrigin:previousOrigin];
	
	updateBlock();
	
	UIView *nextView = nil;
	if (nextViewGrabBlockOrNil != nil){
		nextView = nextViewGrabBlockOrNil();
	}
	
	if (nextView == nil)
		nextView = existingView;
	
	[nextView.superview insertSubview:animationImageView aboveSubview:nextView];
	
	if (animationDirection == UIViewPageAnimationDirectionRight){
		[nextView setOrigin:CGPointMake(-1*existingView.size.width, existingView.frame.origin.y)];
		
	}else if (animationDirection == UIViewPageAnimationDirectionLeft){
		[nextView setOrigin:CGPointMake(existingView.size.width, existingView.frame.origin.y)];
		
	}else if (animationDirection == UIViewPageAnimationDirectionDown){
		[nextView setOrigin:CGPointMake(existingView.frame.origin.x, -1* existingView.frame.size.height)];
		
	}else if (animationDirection == UIViewPageAnimationDirectionUp){
		[nextView setOrigin:CGPointMake(existingView.frame.origin.x, existingView.frame.size.height)];
		
	}
	
	
	[UIView animateWithDuration:.4 delay:0 options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction animations:^{ 
		[nextView setOrigin:previousOrigin];
		
		if (animationDirection == UIViewPageAnimationDirectionRight){
			[animationImageView setOrigin:CGPointMake(animationImageView.width, animationImageView.frame.origin.y)];	
			
		}else if (animationDirection == UIViewPageAnimationDirectionLeft){
			[animationImageView setOrigin:CGPointMake(-1*animationImageView.width, animationImageView.frame.origin.y)];	
			
		}else if (animationDirection == UIViewPageAnimationDirectionDown){
			[animationImageView setOrigin:CGPointMake(animationImageView.frame.origin.x, animationImageView.frame.size.height)];	
			
		}else if (animationDirection == UIViewPageAnimationDirectionUp){
			[animationImageView setOrigin:CGPointMake(animationImageView.frame.origin.x, -1* animationImageView.frame.size.height)];	
			
		}
	}
					 completion: ^(BOOL finnished){
						 [animationImageView removeFromSuperview];
					 }];
	
	SRELS(animationImageView);
	
}



@end
