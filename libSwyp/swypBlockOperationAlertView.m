//
//  swypBlockOperationAlertView.m
//  Fibromyalgia
//
//  Created by Alexander List on 7/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "swypBlockOperationAlertView.h"


@implementation swypBlockOperationAlertView

-(id) initWithoutDelegateWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSArray *)otherButtonTitles blockOperations:(NSArray*)operationsForIndexes{
	if (self = [super init]){
		self.delegate	= self;
		self.title		= title;
		self.message	= message;
		self.cancelButtonIndex = 0;
		[self addButtonWithTitle:cancelButtonTitle];
		for (NSString * buttonTitle in otherButtonTitles)
			[self addButtonWithTitle:buttonTitle];
		
		for (int i = 0; i < [operationsForIndexes count]; i++){
			[self setBlockOperation:[operationsForIndexes objectAtIndex:i] forButtonIndex:i];
		}
		
	}
	return self;
}

-(void) setBlockOperation: (NSBlockOperation*)blockOperation forButtonIndex:(NSInteger)index{
	if (operationDictionary == nil){
		operationDictionary = [[NSMutableDictionary alloc] init];
	}
	
	NSNumber * indexNumber	= [NSNumber numberWithInt:index];
	if (blockOperation != nil){
		[operationDictionary setObject:blockOperation forKey:indexNumber];
	}else {
		[operationDictionary removeObjectForKey:indexNumber];
	}

}

-(void)dealloc{
	SRELS(operationDictionary);
	
	[super dealloc];
}



- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	NSNumber * indexNumber	= [NSNumber numberWithInt:buttonIndex];
	
	NSBlockOperation *operationForIndex	= [operationDictionary objectForKey:indexNumber];
	
	if (operationForIndex != nil){
		[operationForIndex start];
		[operationForIndex waitUntilFinished];
	}
}
@end
