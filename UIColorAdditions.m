//
//  UIColorAdditions.m
//  swyp
//
//  Created by Alexander List on 8/17/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import "UIColorAdditions.h"

@implementation UIColor (SwypAdditions)
+(UIColor*)		colorWithSwypEncodedColorString:(NSString*)encodedColor{
    NSArray *encodedComponents = [encodedColor componentsSeparatedByString:@","];
	if ([encodedComponents count] != 4)
		return nil;
    CGFloat r = [[encodedComponents objectAtIndex:0] floatValue];
    CGFloat g = [[encodedComponents objectAtIndex:1] floatValue];
    CGFloat b = [[encodedComponents objectAtIndex:2] floatValue];
    CGFloat a = [[encodedComponents objectAtIndex:3] floatValue];
    return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

+(UIColor*)		randomSwypHueColor{
	srand ( time(NULL) );
	CGFloat r = (float)(rand() % 100) /(float)100;
    CGFloat g = (float)(rand() % 100) /(float)100;
	CGFloat b = (float)(rand() % 100) /(float)100;
    CGFloat a = (float)(rand() % 50) /(float)100 + 0.25; //alpha 25% to 75%
    return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

-(NSString*)	swypEncodedColorStringValue{
	const CGFloat *components = CGColorGetComponents(self.CGColor);
    return [NSString stringWithFormat:@"%f,%f,%f,%f", components[0], components[1], components[2], components[3]];	
}
@end
