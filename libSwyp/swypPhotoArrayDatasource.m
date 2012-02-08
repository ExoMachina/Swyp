//
//  swypPhotoArrayDatasource.m
//  swyp
//
//  Created by Alexander List on 9/6/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import "swypPhotoArrayDatasource.h"
#import "swypContentInteractionManager.h"

@implementation swypPhotoArrayDatasource


-(void)	addPhotoData:(NSData*)photoData atIndex:(NSUInteger)	insertIndex{
	UIImage * iconImage		=	[self _generateIconImageForImageData:photoData maxSize:CGSizeMake(250, 250)];
	if (iconImage == nil)
		return;
	
	NSString * uniqueID	= [self _generateUniqueContentID];
	
	[_photoDataByContentID setValue:photoData forKey:uniqueID];
	[_cachedImagesByContentID setValue:iconImage forKey:uniqueID];
	[_orderedContentIDs insertObject:uniqueID atIndex:insertIndex];
	
	[_datasourceDelegate datasourceInsertedContentWithID:uniqueID withDatasource:self];
}

-(void) addUIImage:(UIImage*)addImage atIndex:(NSUInteger)insertIndex{
	[self addPhotoData:UIImagePNGRepresentation(addImage) atIndex:insertIndex];
}

-(void) addUIImageArray:(NSArray*)imageArray{
	for (UIImage * image in imageArray){
		[self addUIImage:image atIndex:0];
	}
}

-(void) addPhotoDataArray:(NSArray*) arrayOfPhotoData{
	for (NSData * photoData in arrayOfPhotoData){
		[self addPhotoData:photoData atIndex:0];
	}
}


-(void) removeAllPhotos{
	[_cachedImagesByContentID removeAllObjects];
	[_photoDataByContentID removeAllObjects];
	[_orderedContentIDs removeAllObjects];
	
	[_datasourceDelegate datasourceSignificantlyModifiedContent:self];
}

-(void) removePhotoAtIndex:	(NSUInteger)removeIndex{

	NSString * contentID	=	[_orderedContentIDs objectAtIndex:removeIndex];
	assert(StringHasText(contentID));
	
	[_photoDataByContentID removeObjectForKey:contentID];
	[_cachedImagesByContentID removeObjectForKey:contentID];
	[_orderedContentIDs removeObjectAtIndex:removeIndex];
	

	[_datasourceDelegate datasourceRemovedContentWithID:contentID withDatasource:self];

}
#pragma mark NSObject
-(id)	initWithImageDataArray:(NSArray*) arrayOfPhotoData{
	if (self = [super init]){
		_photoDataByContentID		= [[NSMutableDictionary alloc] init];
		_cachedImagesByContentID	= [[NSMutableDictionary alloc] init];
		_orderedContentIDs			= [[NSMutableArray alloc] init];

		for (NSData * photoData in arrayOfPhotoData){
			[self addPhotoData:photoData atIndex:0];
		}
	}
	return self;
}
- (id)init
{
    self = [self initWithImageDataArray:nil];
	
    return self;
}
	 
-(void)dealloc{
	SRELS(_photoDataByContentID);
	SRELS(_cachedImagesByContentID);
	SRELS(_orderedContentIDs);
	
	[super dealloc];
}

#pragma mark swypContentDataSource
- (NSArray*)	idsForAllContent{
	return _orderedContentIDs;
}
- (UIImage *)	iconImageForContentWithID: (NSString*)contentID ofMaxSize:(CGSize)maxIconSize{
	
	UIImage *cachedImage	=	[_cachedImagesByContentID objectForKey:contentID];
	
	if (CGSizeEqualToSize([cachedImage size], maxIconSize) == NO){
		cachedImage		=	[self _generateIconImageForImageData:[_photoDataByContentID objectForKey:contentID] maxSize:maxIconSize];
		if (cachedImage == nil)
			return nil;
		[_cachedImagesByContentID setObject:cachedImage forKey:contentID];
	}
	return cachedImage;

}
- (NSArray*)		supportedFileTypesForContentWithID: (NSString*)contentID{
	return [NSArray arrayWithObjects:[NSString imagePNGFileType],[NSString imageJPEGFileType],nil];
}

- (NSData*)	dataForContentWithID: (NSString*)contentID fileType:	(swypFileTypeString*)type{
	
	NSData *	photoPNGData		=	[_photoDataByContentID objectForKey:contentID];
	
	NSData *	sendPhotoData	=	nil;
	if ([type isEqualToString:[swypFileTypeString imagePNGFileType]]){
		sendPhotoData	=  photoPNGData;
	}else if ([type isEqualToString:[swypFileTypeString imageJPEGFileType]]){
		sendPhotoData	=	UIImageJPEGRepresentation([UIImage imageWithData:photoPNGData],.8);
	}

	return sendPhotoData;
}

-(void)	setDatasourceDelegate:			(id<swypContentDataSourceDelegate>)delegate{
	_datasourceDelegate	=	delegate;
}
-(id<swypContentDataSourceDelegate>)	datasourceDelegate{
	return _datasourceDelegate;
}

#pragma mark swypConnectionSessionDataDelegate
-(NSArray*)supportedFileTypesForReceipt{
	return [NSArray arrayWithObjects:[NSString imageJPEGFileType] ,[NSString imagePNGFileType], nil];
}

//the OLD Way no longer will be called with the NEW Way is implemented
//-(BOOL) delegateWillHandleDiscernedStream:(swypDiscernedInputStream*)discernedStream wantsAsData:(BOOL *)wantsProvidedAsNSData inConnectionSession:(swypConnectionSession*)session{
//	
//	if ([[NSSet setWithArray:[swypContentInteractionManager supportedReceiptFileTypes]] containsObject:[discernedStream streamType]]){
//		*wantsProvidedAsNSData = TRUE;
//		return TRUE;
//	}else{
//		return FALSE;
//	}
//}

-(BOOL) delegateWillReceiveDataFromDiscernedStream:(swypDiscernedInputStream*)discernedStream ofType:(NSString*)streamType inConnectionSession:(swypConnectionSession*)session{
	if ([[NSSet setWithArray:[swypContentInteractionManager supportedReceiptFileTypes]] containsObject:[discernedStream streamType]]){
		return TRUE;
	}else{
		return FALSE;
	}
}

-(void)	yieldedData:(NSData*)streamData ofType:(NSString *)streamType fromDiscernedStream:(swypDiscernedInputStream *)discernedStream inConnectionSession:(swypConnectionSession *)session{
	EXOLog(@"swypPhotoArrayDataSource datasource received data of type: %@",[discernedStream streamType]);
	//you may want to see the swypBackedPhotoDataSource override
}

#pragma mark - private

-(UIImage*)	_generateIconImageForImageData:(NSData*)imageData maxSize:(CGSize)maxSize{
	UIImage * loadImage		=	[[UIImage alloc] initWithData:imageData];
	if (loadImage == nil)
		return nil;
	
	CGSize oversize = CGSizeMake([loadImage size].width - maxSize.width, [loadImage size].height - maxSize.height);
	
	CGSize iconSize			=	CGSizeZero;
	
	if (oversize.width > 0 || oversize.height > 0){
		if (oversize.height > oversize.width){
			double scaleQuantity	=	maxSize.height/ loadImage.size.height;
			iconSize		=	CGSizeMake(scaleQuantity * loadImage.size.width, maxSize.height);
		}else{
			double scaleQuantity	=	maxSize.width/ loadImage.size.width;	
			iconSize		=	CGSizeMake(maxSize.width, scaleQuantity * loadImage.size.height);		
		}
	}else{
		iconSize			= [loadImage size];
	}
	
	UIGraphicsBeginImageContextWithOptions(iconSize, NO, [[UIScreen mainScreen] scale]);
	[loadImage drawInRect:CGRectMake(0,0,iconSize.width,iconSize.height)];
	UIImage* cachedIconImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	SRELS(loadImage);
	
	return cachedIconImage;
}

-(NSString*) _generateUniqueContentID{
	NSInteger idNum 	= [_photoDataByContentID count];
	NSString * uniqueID = [NSString stringWithFormat:@"MODEL_%i",idNum];
	while ([_photoDataByContentID objectForKey:uniqueID] != nil) {
		idNum ++;
		uniqueID = [NSString stringWithFormat:@"MODEL_%i",idNum];
	}
	return uniqueID;
}




@end
