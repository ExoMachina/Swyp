//
//  NSStringAdditions.m
//  swyp
//
//  Created by Alexander List on 8/5/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import "NSStringAdditions.h"
#import "NSDataAdditions.h"

@implementation NSString (SwypAdditions)
-(NSString *)SHA1AlphanumericHash{
	NSData *hashData			= [[self dataUsingEncoding:NSUTF8StringEncoding] SHA1Hash];
	unsigned char *hashBytes	= (unsigned char *)[hashData bytes];
	
	NSMutableString *alphaHashStr = [NSMutableString string];
	for (int i = 0; i < [hashData length]; i++){
		[alphaHashStr appendFormat:@"%02x",hashBytes[i]];
	}
	
	return [NSString stringWithString:alphaHashStr];	
}

+(NSString*)localAppName{
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
}

@end
