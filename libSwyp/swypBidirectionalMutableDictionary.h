//
//  swypBidirectionalMutableDictionary.h
//  swyp
//
//  Created by Alexander List on 1/14/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import <Foundation/Foundation.h>
/**
 This class simply supports setting object for key, or value for key, then being able to efficiently retrieve the inverse of key for value, etc.
 
 Simply add values, then use as normal, paying special attention to keyForObject:. 
 
 @warning I'm not sure if removeObjectsForKeys works...
 */
@interface swypBidirectionalMutableDictionary : NSMutableDictionary{
	NSMutableDictionary	*	_inverseDictionary;
}

/**  This is the core functionality. Returns nil if nothing available.*/
-(id)keyForObject:(id)object;

/**  This is the string method. Returns nil if nothing available.*/
-(NSString*)keyForValue:(id)value;

/**  Returns dictionary of keysByObject. */
-(NSDictionary*)inverseDictionary;


@end
