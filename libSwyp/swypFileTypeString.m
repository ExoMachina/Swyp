//
//  swypFileTypeString.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import "swypFileTypeString.h"


@implementation NSString (swypFileTypeNSStringAdditions)

+(id) imagePNGFileType{
	static NSString * type = @"image/png";
	return type;		
}

+(id) imageJPEGFileType{
	static NSString * type = @"image/jpeg";
	return type;		
}


+(id) videoMPEGFileType{
	static NSString * type = @"video/mpeg";
	return type;	
}

+(id) applicationPDFFileType{
	static NSString * type = @"application/pdf";
	return type;
}

+(id) textPlainFileType{
	static NSString * type = @"text/plain";
	return type;
}

+(id) swypContactFileType{
	static NSString * type = @"text/contact";
	return type;
}

+(id) swypAddressFileType{
	static NSString * type = @"text/address";
	return type;
}


+(id) swypControlPacketFileType{
	static NSString * type = @"swyp/ControlPacket";
	return type;
}

+(id) swypWorkspaceThumbnailFileType{
	static NSString * type = @"swyp/WorkspaceThumbnail";
	return type;
}


-(BOOL) isFileType:	(NSString*)fileType{
	return [self isEqualToString:fileType];
}

@end
