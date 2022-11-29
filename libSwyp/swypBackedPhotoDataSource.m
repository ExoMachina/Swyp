//
//  swypBackedPhotoDataSource.m
//  swyp
//
//  Created by Alexander List on 12/3/11.
//  Copyright (c) 2011 ExoMachina. All rights reserved.
//

#import "swypBackedPhotoDataSource.h"

@implementation swypBackedPhotoDataSource
@synthesize backingDelegate = _backingDelegate;
-(void)	yieldedData:(NSData*)streamData ofType:(NSString *)streamType fromDiscernedStream:(swypDiscernedInputStream *)discernedStream inConnectionSession:(swypConnectionSession *)session{
	
	[_backingDelegate swypBackedPhotoDataSourceRecievedPhoto:[UIImage imageWithData:streamData] withDataSource:self];
}


-(void)contentWithIDWasDraggedOffWorkspace:(NSString *)contentID{
    
}

-(id) initWithBackingDelegate: (id<swypBackedPhotoDataSourceDelegate>)	backingDelegate{
	if (self = [super init]){
		[self setBackingDelegate:backingDelegate];
	}
	return self;
}
@end
