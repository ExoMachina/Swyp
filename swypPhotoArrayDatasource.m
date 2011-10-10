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

-(void)	addPhoto:(NSData*)photoPNGData atIndex:(NSUInteger)	insertIndex{
	
	UIImage * loadTestImage		=	[[UIImage alloc] initWithData:photoPNGData];
	if (loadTestImage == nil)
		return;
	
	CGSize iconSize = CGSizeMake(150, 150);
	UIGraphicsBeginImageContext( iconSize );
	[loadTestImage drawInRect:CGRectMake(0,0,iconSize.width,iconSize.height)];
	UIImage* cachedIconImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	SRELS(loadTestImage);
	
	[_photoDataArray insertObject:photoPNGData atIndex:insertIndex];
	[_cachedPhotoUIImages	insertObject:cachedIconImage atIndex:insertIndex];
	
	[_datasourceDelegate datasourceInsertedContentAtIndex:insertIndex withDatasource:self];
}

-(void) removePhotoAtIndex:	(NSUInteger)removeIndex{
	[_cachedPhotoUIImages removeObjectAtIndex:removeIndex];
	[_photoDataArray removeObjectAtIndex:removeIndex];
	
	[_datasourceDelegate datasourceRemovedContentAtIndex:removeIndex withDatasource:self];
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
- (UIImage *)		iconImageForContentAtIndex:	(NSUInteger)contentIndex{
	return [_cachedPhotoUIImages objectAtIndex:contentIndex];
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
	return [NSArray arrayWithObject:[NSString imagePNGFileType]];
}
- (NSInputStream*)	inputStreamForContentAtIndex:	(NSUInteger)contentIndex fileType:	(swypFileTypeString*)type length: (NSUInteger*)contentLengthDestOrNULL{
	NSData *	photoData		=	[_photoDataArray objectAtIndex:contentIndex];
	*contentLengthDestOrNULL	=	[photoData length];
	
	return [NSInputStream inputStreamWithData:photoData];
	
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
		[self addPhoto:streamData atIndex:0];
	}
}


@end
