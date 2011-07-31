//
//  exoBlockOperationAlertView.h
//  Fibromyalgia
//
//  Created by Alexander List on 7/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface exoBlockOperationAlertView : UIAlertView <UIAlertViewDelegate> {
	NSMutableDictionary *	operationDictionary;
}
-(id) initWithoutDelegateWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSArray *)otherButtonTitles blockOperations:(NSArray*)operationsForIndexes;

-(void) setBlockOperation: (NSBlockOperation*)blockOperation forButtonIndex:(NSInteger)index;

@end
