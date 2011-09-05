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

@protocol swypContentDataSourceProtocol <NSObject>
- (NSUInteger)		countOfContent;
- (UIImage *)		iconImageForContentAtIndex:	(NSUInteger)contentIndex;
- (NSArray*)		supportedFileTypesForContentAtIndex: (NSUInteger)contentIndex;
- (NSInputStream*)	inputStreamForContentAtIndex:	(NSUInteger)contentIndex fileType:	(swypFileTypeString*)type;
@end
