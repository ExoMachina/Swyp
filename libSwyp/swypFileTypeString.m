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

+(id) swypControlPacketFileType{
	static NSString * type = @"swyp/ControlPacket";
	return type;
}

+(id) swypCryptoNegotiationFileType{
	static NSString * type = @"swyp/CryptoNegotiation";
	return type;
}


-(BOOL) isFileType:	(NSString*)fileType{
	return [self isEqualToString:fileType];
}

@end
