//
//  swypDiscernedInputStream.m
//  swyp
//
//  Created by Alexander List on 8/9/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import "swypDiscernedInputStream.h"

@implementation swypDiscernedInputStream
@synthesize isIndefinite = _isIndefinite, streamLength = _streamLength, streamTag = _streamTag, streamType = _streamType;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

@end
