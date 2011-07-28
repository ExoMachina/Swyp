//
//  swypFileTypeString.h
//  swyp
//
//  Created by Alexander List on 7/27/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

//defines file types used by swypConnectionSession for sending and receiving data

#import <Foundation/Foundation.h>


@interface swypFileTypeString : NSString {

}
-(BOOL) isFileType:	(swypFileTypeString*)fileType;

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
