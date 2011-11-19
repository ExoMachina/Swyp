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


-(void)	addPhoto:(NSData*)photoData atIndex:(NSUInteger)	insertIndex fromSession:(swypConnectionSession*)session{
	UIImage * iconImage		=	[self generateIconImageForImageData:photoData maxSize:CGSizeMake(250, 250)];
	if (iconImage == nil)
		return;
	
	[_photoDataArray insertObject:photoData atIndex:insertIndex];
	[_cachedPhotoUIImages	insertObject:iconImage atIndex:insertIndex];
	
	[_datasourceDelegate datasourceInsertedContentAtIndex:insertIndex withDatasource:self withSession:session];
}

-(void)	addPhoto:(NSData*)photoData atIndex:(NSUInteger)	insertIndex{
	[self addPhoto:photoData atIndex:insertIndex fromSession:nil];
}

-(void) removePhotoAtIndex:	(NSUInteger)removeIndex{
	[_cachedPhotoUIImages removeObjectAtIndex:removeIndex];
	[_photoDataArray removeObjectAtIndex:removeIndex];
	
	[_datasourceDelegate datasourceRemovedContentAtIndex:removeIndex withDatasource:self];
}
	 
-(UIImage*)	generateIconImageForImageData:(NSData*)imageData maxSize:(CGSize)maxSize{
	UIImage * loadImage		=	[[UIImage alloc] initWithData:imageData];
	if (loadImage == nil)
		return nil;
	
	CGSize iconSize			=	(maxSize.width * maxSize.height < [loadImage size].width *[loadImage size].height)? maxSize : [loadImage size];

	UIGraphicsBeginImageContextWithOptions(iconSize, NO, [[UIScreen mainScreen] scale]);
	[loadImage drawInRect:CGRectMake(0,0,iconSize.width,iconSize.height)];
	UIImage* cachedIconImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	SRELS(loadImage);
	
	return cachedIconImage;
}

#pragma mark NSObject
-(id)	initWithImageDataArray:(NSArray*) arrayOfPhotoData{
	if (self = [super init]){
		_photoDataArray			=	[[NSMutableArray alloc] init];
		_cachedPhotoUIImages	=	[[NSMutableArray alloc] init];

		for (NSData * photoData in arrayOfPhotoData){
			[self addPhoto:photoData atIndex:0];
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
	SRELS(_photoDataArray);
	SRELS(_cachedPhotoUIImages);
	
	[super dealloc];
}

#pragma mark swypContentDataSource
- (UIImage *)		iconImageForContentAtIndex:	(NSUInteger)contentIndex ofMaxSize:(CGSize)maxIconSize{
	UIImage * cachedImage	=	[_cachedPhotoUIImages objectAtIndex:contentIndex]; 
	if (CGSizeEqualToSize([cachedImage size], maxIconSize) == NO){
		cachedImage		=	[self generateIconImageForImageData:[_photoDataArray objectAtIndex:contentIndex] maxSize:maxIconSize];
		if (cachedImage == nil)
			return nil;
		[_cachedPhotoUIImages removeObjectAtIndex:contentIndex];
		[_cachedPhotoUIImages insertObject:cachedImage atIndex:contentIndex];
	}
	
	return cachedImage;
}
-(void)	setDatasourceDelegate:			(id<swypContentDataSourceDelegate>)delegate{
	_datasourceDelegate	=	delegate;
}
-(id<swypContentDataSourceDelegate>)	datasourceDelegate{
	return _datasourceDelegate;
}

- (NSUInteger)		countOfContent{
	return [_photoDataArray count];
}

- (NSArray*)		supportedFileTypesForContentAtIndex: (NSUInteger)contentIndex{
	return [NSArray arrayWithObjects:[NSString imagePNGFileType],[NSString imageJPEGFileType],nil];
}
- (NSInputStream*)	inputStreamForContentAtIndex:	(NSUInteger)contentIndex fileType:	(swypFileTypeString*)type length: (NSUInteger*)contentLengthDestOrNULL{
	NSData *	photoJPEGData		=	[_photoDataArray objectAtIndex:contentIndex];

	NSData *	sendPhotoData	=	nil;
	if ([type isEqualToString:[swypFileTypeString imagePNGFileType]]){
		sendPhotoData	=  UIImagePNGRepresentation([UIImage imageWithData:photoJPEGData]);
	}else if ([type isEqualToString:[swypFileTypeString imageJPEGFileType]]){
		sendPhotoData	=	photoJPEGData;
	}
	
	if (sendPhotoData == nil){
		EXOLog(@"No supported export types in datasource");
	}
	
	*contentLengthDestOrNULL	=	[sendPhotoData length];
	
	return [NSInputStream inputStreamWithData:sendPhotoData];
	
}


#pragma mark swypConnectionSessionDataDelegate
-(BOOL) delegateWillHandleDiscernedStream:(swypDiscernedInputStream*)discernedStream wantsAsData:(BOOL *)wantsProvidedAsNSData inConnectionSession:(swypConnectionSession*)session{
	
	if ([[NSSet setWithArray:[swypContentInteractionManager supportedFileTypes]] containsObject:[discernedStream streamType]]){
		*wantsProvidedAsNSData = TRUE;
		return TRUE;
	}else{
		EXOLog(@"Unsupported filetype: %@", [discernedStream streamType]);
		return FALSE;
	}
}

-(void)	yieldedData:(NSData*)streamData discernedStream:(swypDiscernedInputStream*)discernedStream inConnectionSession:(swypConnectionSession*)session{
	if (streamData != nil){
		[self addPhoto:streamData atIndex:0 fromSession:session];
	}
}


@end
