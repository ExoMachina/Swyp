//
//  UIViewAdditions+swypAdditions.h
//  swyp
//
//  Created by Alexander List on 9/5/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	UIViewAnimationDirectionRight = 1 << 0,
    UIViewAnimationDirectionLeft  = 1 << 1,
	UIViewAnimationDirectionUp    = 1 << 2,
    UIViewAnimationDirectionDown  = 1 << 3
} UIViewAnimationDirection;

@interface UIView(swypAdditions)

- (CGPoint)origin;
- (void)setOrigin:(CGPoint)origin;
- (CGSize)size ;
- (void)setSize:(CGSize)size;

@property(nonatomic) CGFloat width;
@property(nonatomic) CGFloat height;

/*
 UpdatePushAnimation
 
 screenshots "existingView"
 updates view with exact function in "updateBlock"
 if "nextViewGrabBlockOrNil" is passed, it uses it to grab the view to make the transition with, otherwise it reuses "existingView"
 
 finally, it moves the views in the direction that you set in "animationDirection" to make the screenshot of the "existingView" look like it's being pushed
 */
+(void)performPageSwitchAnimationWithExistingView:(UIView*)existingView viewUpdateBlock:(void (^)(void))updateBlock nextViewGrabBlock:(UIView* (^)(void))nextViewGrabBlockOrNil direction:(UIViewAnimationDirection)animationDirection;


@end
