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
	[_normalDictionary setValue:value forKey:key];
}

-(void)setObject:(id)anObject forKey:(id)aKey{
	[_inverseDictionary	 setObject:aKey forKey:[NSValue valueWithNonretainedObject:anObject]];
	
	[_normalDictionary setObject:anObject forKey:aKey];
}

-(void)removeAllObjects{
	[_inverseDictionary removeAllObjects];
	[_normalDictionary removeAllObjects];
}

-(void)removeObjectForKey:(id)aKey{
	[_inverseDictionary removeObjectForKey:[NSValue valueWithNonretainedObject:[self objectForKey:aKey]]];
	[_normalDictionary removeObjectForKey:aKey];
}

-(id)objectForKey:(id)aKey{
	return [_normalDictionary objectForKey:aKey];
}

-(NSEnumerator*) keyEnumerator{
	return [_normalDictionary keyEnumerator];
}

-(NSUInteger) count{
	return [_normalDictionary count];
}


#pragma mark NSObject
-(id) init{
	if (self = [super init]){
		_inverseDictionary	= [NSMutableDictionary new];
		_normalDictionary	= [NSMutableDictionary new];
	}
	return self;
}

-(void)dealloc{
	SRELS(_normalDictionary);
	
	SRELS(_inverseDictionary);
	[super dealloc];
}

@end
