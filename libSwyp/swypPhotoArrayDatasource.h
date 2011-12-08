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

-(void) addUIImageArray:(NSArray*)imageArray;
-(void) addUIImage:(UIImage*)addImage atIndex:(NSUInteger)	insertIndex;
-(void) addUIImage:(UIImage*)addImage atIndex:(NSUInteger)	insertIndex fromSession:(swypConnectionSession*)session;
//native data-type is png
-(void) addPhotoDataArray:(NSArray*) arrayOfPhotoData;
-(void)	addPhotoData:(NSData*)photoData atIndex:(NSUInteger)	insertIndex fromSession:(swypConnectionSession*)session;
-(void)	addPhotoData:(NSData*)photoData atIndex:(NSUInteger)	insertIndex;
-(void) removePhotoAtIndex:	(NSUInteger)removeIndex;
-(void) removeAllPhotos;

-(UIImage*)	generateIconImageForImageData:(NSData*)imageData maxSize:(CGSize)maxSize;
@end
