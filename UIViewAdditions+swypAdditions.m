//
//  UIViewAdditions+swypAdditions.m
//  swyp
//
//  Created by Alexander List on 9/5/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import "UIViewAdditions+swypAdditions.h"

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

@end
