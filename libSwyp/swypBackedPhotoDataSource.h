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
@protocol swypBackedPhotoDataSourceDelegate <NSObject>
-(void) swypBackedPhotoDataSourceRecievedPhoto: (UIImage*) photo withDataSource: (swypBackedPhotoDataSource*)dataSource;
@end

@interface swypBackedPhotoDataSource : swypPhotoArrayDatasource{
	id<swypBackedPhotoDataSourceDelegate>	_backingDelegate;
}
@property (nonatomic, assign) 	id<swypBackedPhotoDataSourceDelegate>	backingDelegate;

@end
