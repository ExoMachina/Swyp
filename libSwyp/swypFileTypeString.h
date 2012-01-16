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

#define swypFileTypeString NSString

#import <Foundation/Foundation.h>

/** Predefinied file types to use if needed
	PNG is manditory if your app exports data.
 */
@interface NSString (swypFileTypeNSStringAdditions)

/** File type equality check */
-(BOOL) isFileType:	(NSString*)fileType;

/**		PNG, the universally supported filetype.

 This is the one type that all swypDataContent *must* support exporting. I'm serious-- I will develop blacklisting, implement exceptions, etc.
 You can choose whatever you want your app to accept, but obviously PNG is a good option.

	MIME: "image/png"
 
 @warning This is the one type that all swypDataContent *must* support exporting.
*/
+(id) imagePNGFileType;


/**
	jpeg is a way smaller smaller file than PNG; perhaps it's a good thing to support too
	
	MIME: "image/jpeg"
 */
+(id) imageJPEGFileType;

/*
		MIME: "video/mpeg"
*/
+(id) videoMPEGFileType;


/**
		Used in conjunction with specifc tags during connection negotiation.
		Used to set things like session hue color.
		Used to notify peer of changes in connection state, like intention to terminate.
		MIME: "swyp/ControlPacket"
 
 @warning an exception is thrown if you use this yourself. Use invalidate on swypConnectionSession instead.
*/
+(id) swypControlPacketFileType;


@end
