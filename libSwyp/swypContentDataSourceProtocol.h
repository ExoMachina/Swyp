//
//  swypContentDataSourceProtocol.h
//  swyp
//
//  Created by Alexander List on 9/5/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "swypFileTypeString.h"

@protocol swypContentDataSourceProtocol;
@class swypConnectionSession;

/** this protocol defines the actions that a datasource expects its delegate to respond to
	
 These should allow model changes to easily propagate through the swypContentInteractionManager to a swypContentViewController
 */
@protocol swypContentDataSourceDelegate <NSObject>
/**
 This indicates that the datasourceInsertedContentWithID, and that the views should update accordingly. 
 
 */
-(void)	datasourceInsertedContentWithID:(NSString*)insertID withDatasource:	(id<swypContentDataSourceProtocol>)datasource;

/**
 This indicates that the datasourceRemovedContentWithID, and that the views should update accordingly. 
  */
-(void)	datasourceRemovedContentWithID:(NSString*)removeID withDatasource:	(id<swypContentDataSourceProtocol>)datasource;

/**
 This indicates that the datasourceSignificantlyModifiedContent, and that the views should update accordingly by reloading all content. 
 */
-(void)	datasourceSignificantlyModifiedContent:	(id<swypContentDataSourceProtocol>)datasource;

@end

/**
 This ID-based content identification protocol for swypContentDataSources has some central tennets.
 
 Content can be ordered, or not, in returning the 'idsForAllContent' array.
 
 Content is represented on a contentViewController iconImageForContentWithID:ofMaxSize:, then when that contentViewController detects a swyp-out of the content, the swypContentInteractionManager requests inputStreamForContentWithID:fileType:length: for that content, which is then added to the output for a particular session.
 */
@protocol swypContentDataSourceProtocol <NSObject>
/** Returns list of all unique IDs for each piece of content to displayed to swyp workspace. 
 @return	NSArray choc full of NSStrings.
			Can be as simple as [[NSNumber numberWithInt:index] stringValue];
 
  Content can be ordered, or not, in returning the 'idsForAllContent' array.

 */
- (NSArray*)		idsForAllContent;

/** Returns a UIImage representing content, which has dimensions no greater than maxIconSize.
	This image is displayed by the swypContentViewController.
 */
- (UIImage *)		iconImageForContentWithID: (NSString*)contentID ofMaxSize:(CGSize)maxIconSize;

/// Returns swypFileTypeString array that a specifc contentID supports
- (NSArray*)		supportedFileTypesForContentWithID: (NSString*)contentID;

/** Gets an NSInputStream for a specific piece of content for sending over connectionSession
 
	@param contentLengthDestOrNULL is a pointer that after function call should contain length of inputStream, or not if indefinite or unknown. 
 */
- (NSInputStream*)	inputStreamForContentWithID: (NSString*)contentID fileType:	(swypFileTypeString*)type	length: (NSUInteger*)contentLengthDestOrNULL; 

///Sets the delegate
-(void)	setDatasourceDelegate:			(id<swypContentDataSourceDelegate>)delegate;
///Retrieves the delegate
-(id<swypContentDataSourceDelegate>)	datasourceDelegate;
@end
