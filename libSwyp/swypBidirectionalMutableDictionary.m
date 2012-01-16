//
//  swypBidirectionalMutableDictionary.m
//  swyp
//
//  Created by Alexander List on 1/14/12.
//  Copyright (c) 2012 ExoMachina. All rights reserved.
//

#import "swypBidirectionalMutableDictionary.h"

@implementation swypBidirectionalMutableDictionary

#pragma mark public
-(id)keyForObject:(id)object{
	return [_inverseDictionary objectForKey:[NSValue valueWithNonretainedObject:object]];
}

-(NSString*)keyForValue:(id)value{
	return [_inverseDictionary objectForKey:[NSValue valueWithNonretainedObject:value]];
}

-(NSDictionary*)inverseDictionary{
	return _inverseDictionary;
}

#pragma mark Overrides
-(void)setValue:(id)value forKey:(NSString *)key{
	[_inverseDictionary	 setObject:key forKey:[NSValue valueWithNonretainedObject:value]];
	[super setValue:value forKey:key];
}

-(void)setObject:(id)anObject forKey:(id)aKey{
	[_inverseDictionary	 setObject:aKey forKey:[NSValue valueWithNonretainedObject:anObject]];
	
	[super setObject:anObject forKey:aKey];
}

-(void)removeAllObjects{
	[_inverseDictionary removeAllObjects];
	[super removeAllObjects];
}

-(void)removeObjectForKey:(id)aKey{
	[_inverseDictionary removeObjectForKey:[NSValue valueWithNonretainedObject:[self objectForKey:aKey]]];
	[super removeObjectForKey:aKey];
}

#pragma mark NSObject
-(id) init{
	if (self = [super init]){
		_inverseDictionary = [NSMutableDictionary new];
	}
	return self;
}

-(void)dealloc{
	
	SRELS(_inverseDictionary);
	[super dealloc];
}

@end
