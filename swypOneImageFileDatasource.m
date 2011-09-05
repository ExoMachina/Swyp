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


#pragma mark swypContentDataSource
- (NSUInteger)		countOfContent{
	return 1;
}

- (UIImage *)		iconImageForContentAtIndex:	(NSUInteger)contentIndex{
	if (_cachedIconImage == nil){
		CGSize iconSize = CGSizeMake(150, 150);
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
- (NSInputStream*)	inputStreamForContentAtIndex:	(NSUInteger)contentIndex fileType:	(swypFileTypeString*)type{
	return [NSInputStream inputStreamWithData:UIImagePNGRepresentation(_image)];
	
}


@end
