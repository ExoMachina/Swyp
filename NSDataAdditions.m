//
//  NSDataAdditions.m
//  swyp
//
//  Created by Alexander List on 8/5/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import "NSDataAdditions.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSData (SwypAdditions)

- (NSData *) SHA1Hash
{
	unsigned char hashdata[CC_SHA1_DIGEST_LENGTH];
	(void) CC_SHA1( [self bytes], (CC_LONG)[self length], hashdata );
	return [NSData dataWithBytes:hashdata	length:CC_SHA1_DIGEST_LENGTH];
}

@end
