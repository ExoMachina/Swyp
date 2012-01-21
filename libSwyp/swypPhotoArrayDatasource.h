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

/**
	This class allows its owners to add photo data, and serves as a datasource in the swypContentInteractionManager. 
 
 This class adopts swypContentDataSourceProtocol, which is how your app interacts with the interactionManager, and provides previews and streams to the user and connected peer. 
 
 @warning Observe how internally we use contentIDs, yet externally we stil support the typical contentAtIndex paradigm. 
 
 @warning The following determines what filetypes your app accepts.
 This class adopts swypConnectionSessionDataDelegate, which includes the supportedFileTypesForReceipt method. As this dataSource is set in swypContentInteractionManager, supportedFileTypesForReceipt determines what fileTypes your app can receive. 
 */
@interface swypPhotoArrayDatasource : NSObject <swypContentDataSourceProtocol, swypConnectionSessionDataDelegate>{	
	
	NSMutableArray	*		_orderedContentIDs;
	NSMutableDictionary *	_photoDataByContentID;
	NSMutableDictionary *	_cachedImagesByContentID;

	
	id<swypContentDataSourceDelegate>	_datasourceDelegate;
}

/**
 Initialize the datasource backed by an array of png data.
 */
-(id)	initWithImageDataArray:(NSArray*) arrayOfPhotoData;

///remove a specific image from the model
-(void) removePhotoAtIndex:	(NSUInteger)removeIndex;
///add all images from the model
-(void) removeAllPhotos;


///add a UIImage to the model
-(void) addUIImage:(UIImage*)addImage atIndex:(NSUInteger)	insertIndex;

///add a UIImage array to the model
-(void) addUIImageArray:(NSArray*)imageArray;

///add PNG data to dataSource
-(void)	addPhotoData:(NSData*)photoData atIndex:(NSUInteger)	insertIndex;
///Add a NSData of PNG array to dataSource
-(void) addPhotoDataArray:(NSArray*) arrayOfPhotoData;

//
//private
-(UIImage*)	_generateIconImageForImageData:(NSData*)imageData maxSize:(CGSize)maxSize;

-(NSString*) _generateUniqueContentID;
@end
