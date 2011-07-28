//
//  swypEncryptingTransform.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- check online.
//

#import <Foundation/Foundation.h>
#import "swypTransformInputStream.h"

@interface swypEncryptingTransform: swypTransformInputStream {
	NSData *		_sessionAESKey;
}
-(id)	initWithSessionAES128Key:	(NSData*)sessionKey;


@end
