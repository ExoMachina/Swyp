//
//  swypOneImageFileDatasource.m
//  swyp
//
//  Created by Alexander List on 9/5/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import "swypOneImageFileDatasource.h"

@implementation swypOneImageFileDatasource

+ (id) datasourceWithImage: (UIImage*)image{
	return [[[swypOneImageFileDatasource alloc] initWithImage:image] autorelease];
}
//
- (id)initWithImage: (UIImage*) image{
    self = [super init];
    if (self) {
        // Initialization code here.
		_image = [image retain];
    }
    
    return self;
}

-(void) dealloc{
	_datasourceDelegate	=nil;
	SRELS(_image);
	SRELS(_cachedIconImage);
	[super dealloc];
}

#pragma mark swypContentDataSource
-(void)	setDatasourceDelegate:			(id<swypContentDataSourceDelegate>)delegate{
	_datasourceDelegate	=	delegate;
}
-(id<swypContentDataSourceDelegate>)	datasourceDelegate{
	return _datasourceDelegate;
}



- (NSUInteger)		countOfContent{
	return 1;
}

- (UIImage *)		iconImageForContentAtIndex:	(NSUInteger)contentIndex ofMaxSize:(CGSize)maxIconSize{
	CGSize iconSize =	(maxIconSize.width * maxIconSize.height < [_image size].width *[_image size].height)? maxIconSize : [_image size];
	
	if (CGSizeEqualToSize([_cachedIconImage size],iconSize) == NO){
		SRELS( _cachedIconImage);
	}
	
	if (_cachedIconImage == nil){
		UIGraphicsBeginImageContext( iconSize );
		[_image drawInRect:CGRectMake(0,0,iconSize.width,iconSize.height)];
		_cachedIconImage = [UIGraphicsGetImageFromCurrentImageContext() retain];
		UIGraphicsEndImageContext();
	}
	
	return _cachedIconImage;
}
- (NSArray*)		supportedFileTypesForContentAtIndex: (NSUInteger)contentIndex{
	return [NSArray arrayWithObject:[NSString imagePNGFileType]];
}
- (NSInputStream*)	inputStreamForContentAtIndex:	(NSUInteger)contentIndex fileType:	(swypFileTypeString*)type length: (NSUInteger*)contentLengthDestOrNULL{
	NSData *	photoData		=	UIImagePNGRepresentation(_image);
	*contentLengthDestOrNULL	=	[photoData length];
	
	return [NSInputStream inputStreamWithData:photoData];
	
}


@end
