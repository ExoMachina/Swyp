//
//  swypPhotoArrayDatasource.h
//  swyp
//
//  Created by Alexander List on 9/6/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "swypContentDataSourceProtocol.h"
#import "swypConnectionSession.h"

@interface swypPhotoArrayDatasource : NSObject <swypContentDataSourceProtocol, swypConnectionSessionDataDelegate>{
	NSMutableArray *	_photoDataArray;
	NSMutableArray *	_cachedPhotoUIImages;
	
	id<swypContentDataSourceDelegate>	_datasourceDelegate;
}

-(id)	initWithImageDataArray:(NSArray*) arrayOfPhotoData;

-(void)	addPhoto:(NSData*)photoPNGData atIndex:(NSUInteger)	insertIndex fromSession:(swypConnectionSession*)session;
-(void)	addPhoto:(NSData*)photoPNGData atIndex:(NSUInteger)	insertIndex;
-(void) removePhotoAtIndex:	(NSUInteger)removeIndex;
@end
