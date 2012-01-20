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
 
 @warning don't try to use this anywhere. Use invalidate on swypConnectionSession to close connections instead.
*/
+(id) swypControlPacketFileType;

/**
 Used by swyp workspace to show preview image of loading content. 

 Only handled by swypContentInteractionManager, which provides things like a waterfall UI.
 
 We internally rely upon an 80% quality JPEG for v-fast xfer.
 
 MIME: "swyp/WorkspaceThumbnail"
 
 @warning to have the workspace display the thumbnail, you must have the swypContentInteractionManager as a swypConnectionSession dataDelegate. 

 @warning send the actual file right after the thumbnail, and set the tags of each to be identical. Behavior otherwise is undefined, but isn't good.
 */
+(id) swypWorkspaceThumbnailFileType;

@end
