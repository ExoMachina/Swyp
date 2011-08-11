//
//  swypFileTypeString.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

//defines file types used by swypConnectionSession for sending and receiving data
// don't read into this too much, it's really just conviniencies for standardized string constants
////this class is not concrete, it can't be used as a full-on string


#import <Foundation/Foundation.h>


@interface NSString (swypFileTypeString)

-(BOOL) isFileType:	(NSString*)fileType;

/*
		This is the one type that all swypDataContent *must* support exporting. I'm serious-- I will develop blacklisting, implement exceptions, etc.
		You can choose whatever you want your app to accept, but obviously PNG is a good option.
		MIME: "image/png"
*/
+(id) imagePNGFileType;


/*
		MIME: "video/mpeg"
*/
+(id) videoMPEGFileType;


/*
		Used in conjunction with specifc tags during connection negotiation.
		Used to set things like session hue color.
		Used to notify peer of changes in connection state, like intention to terminate.
		MIME: "swyp/ControlPacket"
*/
+(id) swypControlPacketFileType;
@end
