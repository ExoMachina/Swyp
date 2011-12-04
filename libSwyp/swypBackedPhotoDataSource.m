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
-(void)	addPhotoData:(NSData*)photoData atIndex:(NSUInteger)	insertIndex fromSession:(swypConnectionSession*)session{
	[super addPhotoData:photoData atIndex:insertIndex fromSession:session];
	if (session != nil){
		[_backingDelegate swypBackedPhotoDataSourceRecievedPhoto:[UIImage imageWithData:photoData] withDataSource:self];
	}
}
@end
