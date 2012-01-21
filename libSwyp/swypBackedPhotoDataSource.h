//
//  swypBackedPhotoDataSource.h
//  swyp
//
//  Created by Alexander List on 12/3/11.
//  Copyright (c) 2011 ExoMachina. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "swypPhotoArrayDatasource.h"

@class swypBackedPhotoDataSource;
///The delegate protocol for swypBackedPhotoDataSource
@protocol swypBackedPhotoDataSourceDelegate <NSObject>
///The only supported callback, which alerts the delegate that a photo was received.
-(void) swypBackedPhotoDataSourceRecievedPhoto: (UIImage*) photo withDataSource: (swypBackedPhotoDataSource*)dataSource;
@end

/**
 This class is an abstraction of swypPhotoArrayDatasource that allows simple callbacks out of a swypConnectionSessionDataDelegate 
 */
@interface swypBackedPhotoDataSource : swypPhotoArrayDatasource{
	id<swypBackedPhotoDataSourceDelegate>	_backingDelegate;
}

///Set or read the delegate
@property (nonatomic, assign) 	id<swypBackedPhotoDataSourceDelegate>	backingDelegate;

///The only operating init function, setting the callback delegate
-(id) initWithBackingDelegate: (id<swypBackedPhotoDataSourceDelegate>)	backingDelegate;

@end
