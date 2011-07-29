//
//  swypUnencryptingTransform.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. Some rights reserved -- see included 'license' file.
//

#import <Foundation/Foundation.h>
#import "swypTransformInputStream.h"

@interface swypUnencryptingTransform: swypTransformInputStream {
	NSData *		_sessionAESKey;
}
-(id)	initWithSessionAES128Key:	(NSData*)sessionKey;

@end
