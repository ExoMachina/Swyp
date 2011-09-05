//
//  swypOneImageFileDatasource.h
//  swyp
//
//  Created by Alexander List on 9/5/11.
//  Copyright 2011 ExoMachina. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "swypContentDataSourceProtocol.h"
#import "swypFileTypeString.h"

@interface swypOneImageFileDatasource : NSObject <swypContentDataSourceProtocol>{
	UIImage *	_image;
	
	UIImage	*	_cachedIconImage;
}
+ (id) datasourceWithImage: (UIImage*)image;

- (id)initWithImage: (UIImage*) image;

@end
