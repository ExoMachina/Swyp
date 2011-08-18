//
//  UIColorAdditions.h
//  swyp
//
//  Created by Alexander List on 8/17/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (SwypAdditions)
+(UIColor*)		colorWithSwypEncodedColorString:(NSString*)encodedColor;
+(UIColor*)		randomSwypHueColor;
-(NSString*)	swypEncodedColorStringValue;
@end
