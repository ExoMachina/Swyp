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

@protocol swypContentDataSourceDelegate <NSObject>
//	session here can be nil, but if it's not, it'll be used to animate the content in from the session indicator
-(void)	datasourceInsertedContentWithID:(NSString*)insertID withDatasource:	(id<swypContentDataSourceProtocol>)datasource withSession:(swypConnectionSession*)session;
-(void)	datasourceRemovedContentWithID:(NSString*)removeID withDatasource:	(id<swypContentDataSourceProtocol>)datasource;

-(void)	datasourceSignificantlyModifiedContent:	(id<swypContentDataSourceProtocol>)datasource;

@end

@protocol swypContentDataSourceProtocol <NSObject>
/** Returns list of all unique IDs for each piece of content to displayed to swyp workspace. 
 @return NSArray choc full of NSStrings.
 
 Can be as simple as [[NSNumber numberWithInt:index] stringValue];
 */
- (NSArray*)		idsForAllContent;

/// Returns a UIImage representing content, which has dimensions no greater than maxIconSize. 
- (UIImage *)		iconImageForContentWithID: (NSString*)contentID ofMaxSize:(CGSize)maxIconSize;

/// Returns swypFileTypeString array that a specifc contentID supports
- (NSArray*)		supportedFileTypesForContentWithID: (NSString*)contentID;

/** Gets an NSInputStream for a specific piece of content for sending over connectionSession
 
	@param contentLengthDestOrNULL is a pointer that after function call should contain length of inputStream, or not if indefinite or unknown. 
 */
- (NSInputStream*)	inputStreamForContentWithID: (NSString*)contentID fileType:	(swypFileTypeString*)type	length: (NSUInteger*)contentLengthDestOrNULL; 

-(void)	setDatasourceDelegate:			(id<swypContentDataSourceDelegate>)delegate;
-(id<swypContentDataSourceDelegate>)	datasourceDelegate;
@end
