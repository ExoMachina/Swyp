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
-(void)	datasourceInsertedContentAtIndex:(NSUInteger)insertIndex withDatasource:	(id<swypContentDataSourceProtocol>)datasource withSession:(swypConnectionSession*)session;
-(void)	datasourceRemovedContentAtIndex:(NSUInteger)removeIndex withDatasource:	(id<swypContentDataSourceProtocol>)datasource;

-(void)	datasourceSignificantlyModifiedContent:	(id<swypContentDataSourceProtocol>)datasource;

@end

@protocol swypContentDataSourceProtocol <NSObject>
- (NSUInteger)		countOfContent;
- (UIImage *)		iconImageForContentAtIndex:	(NSUInteger)contentIndex ofMaxSize:(CGSize)maxIconSize;
- (NSArray*)		supportedFileTypesForContentAtIndex: (NSUInteger)contentIndex;
- (NSInputStream*)	inputStreamForContentAtIndex:	(NSUInteger)contentIndex fileType:	(swypFileTypeString*)type	length: (NSUInteger*)contentLengthDestOrNULL; //A pointer **EXPLAIN PLEASE

-(void)	setDatasourceDelegate:			(id<swypContentDataSourceDelegate>)delegate;
-(id<swypContentDataSourceDelegate>)	datasourceDelegate;
@end
