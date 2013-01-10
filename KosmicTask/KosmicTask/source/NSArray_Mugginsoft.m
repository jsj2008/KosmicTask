//
//  NSArray_Mugginsoft.m
//  KosmicTask
//
//  Created by Jonathan on 03/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "NSArray_Mugginsoft.h"


@implementation NSArray (Mugginsoft)

/*
 
 - mgs_sortedArrayUsingBestSelector
 
 */
- (NSArray *)mgs_sortedArrayUsingBestSelector
{
	// array of selectors as NSValue
	// also consider:
	// NSStringFromSelector, NSSelectorFromString
	// [NSValue valueWithBytes:&selector objCType:@encode(SEL)];
	NSArray *selectors = [NSArray arrayWithObjects:
						  [NSValue valueWithPointer:@selector(caseInsensitiveCompare:)],
						  [NSValue valueWithPointer:@selector(compare:)],
						  nil];
	
	// sort using selectors
	return [self mgs_sortedArrayUsingSelectors:selectors];
}

/*
 
 - mgs_sortedArrayUsingSelectors:
 
 */
- (NSArray *)mgs_sortedArrayUsingSelectors:(NSArray *)selectors
{
	// validate object similarity
	if (![self mgs_objectsShareClass]) {
		return self;
	}
	
	// precautionary
	if ([self count] <= 1 ) {
		return self;
	}
	id item = [self objectAtIndex:0];
	
	// find best compare selector
	for (NSValue *value in selectors) {
		SEL selector = [value pointerValue];
		if ([item respondsToSelector:selector]) {
			return [self sortedArrayUsingSelector:selector];
		} 
	}
	
	return self;
	
}
/*
 
 mgs_objectsShareClass
 
 */
- (BOOL)mgs_objectsShareClass
{
	
	if ([self count] <= 1 ) {
		return YES;
	}
	
	Class objectClass = [[self objectAtIndex:0] class];

	 
	for (NSUInteger i = 1; i < [self count]; i++) {
		if (![[self objectAtIndex:i] isKindOfClass:objectClass]) {
			return  NO;
		}
	}
	
	return YES;
}

/*
 
 - mgs_objectIndexes
 
 */
- (NSDictionary *)mgs_objectIndexes
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:[self count]];
    
    for (NSUInteger i = 0; i < [self count]; i++) {
        id object = [self objectAtIndex:i];
        NSMutableIndexSet *indexSet = [dict objectForKey:object];
        if (!indexSet) {
            indexSet = [[NSMutableIndexSet alloc] init];
            [dict setObject:indexSet forKey:object];
        }
        [indexSet addIndex:i];
    }
    
    return dict;
}
@end
