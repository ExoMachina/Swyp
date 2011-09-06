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

@protocol swypContentDataSourceDelegate <NSObject>
-(void)	datasourceInsertedContentAtIndex:(NSUInteger)insertIndex withDatasource:	(id<swypContentDataSourceProtocol>)datasource;
-(void)	datasourceRemovedContentAtIndex:(NSUInteger)removeIndex withDatasource:	(id<swypContentDataSourceProtocol>)datasource;

-(void)	datasourceSignificantlyModifiedContent:	(id<swypContentDataSourceProtocol>)datasource;

@end

@protocol swypContentDataSourceProtocol <NSObject>
- (NSUInteger)		countOfContent;
- (UIImage *)		iconImageForContentAtIndex:	(NSUInteger)contentIndex;
- (NSArray*)		supportedFileTypesForContentAtIndex: (NSUInteger)contentIndex;
- (NSInputStream*)	inputStreamForContentAtIndex:	(NSUInteger)contentIndex fileType:	(swypFileTypeString*)type	length: (NSUInteger*)contentLengthDestOrNULL;

-(void)	setDatasourceDelegate:			(id<swypContentDataSourceDelegate>)delegate;
-(id<swypContentDataSourceDelegate>)	datasourceDelegate;
@end
