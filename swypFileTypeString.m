//
//  swypFileTypeString.m
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import "swypFileTypeString.h"


@implementation swypFileTypeString


-(BOOL) isFileType:	(swypFileTypeString*)fileType{
	return [self isEqualToString:fileType];
}

+(id) imagePNGFileType{
	static NSString * type = @"image/png";
	return type;		
}

+(id) videoMPEGFileType{
	static NSString * type = @"video/mpeg";
	return type;	
}

+(id) swypControlPacketFileType{
	static NSString * type = @"swyp/ControlPacket";
	return type;
}

@end
