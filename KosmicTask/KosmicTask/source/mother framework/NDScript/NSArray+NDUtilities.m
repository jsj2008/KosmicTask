/*
 *  NSArray+NDUtilities.m category
 *  AppleScriptRunner
 *
 *  Created by Nathan Day on Thu Jan 16 2003.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "NSArray+NDUtilities.h"

@interface NSEnumeratrorWithArrayIndicies : NSEnumerator
{
@private
	NSArray			* array;
	NSIndexSet		* indexSet;
	NSUInteger	currentIndex;
}
+ (id)enumeratrorWithArray:(NSArray *)anArray indicies:(NSIndexSet *)anIndiciesSet;
- (id)initWithArray:(NSArray *)anArray indicies:(NSIndexSet *)anIndiciesSet;
@end

/*
 * category implementation NSArray (NDUtilities)
 */
@implementation NSArray (NDUtilities)

/*
	- arrayByUsingFunction:
 */
- (NSArray *)arrayByUsingFunction:(id (*)(id, BOOL *))aFunc
{
	NSUInteger		theIndex,
							theCount;
	NSMutableArray		* theResultArray;
	BOOL					theContinue = YES;

	theCount = [self count];
	theResultArray = [NSMutableArray arrayWithCapacity:theCount];

	for( theIndex = 0; theIndex < theCount && theContinue == YES; theIndex++ )
	{
		id		theResult;
		
		theResult = aFunc([self objectAtIndex:theIndex], &theContinue );

		if( theResult ) [theResultArray addObject:theResult];
	}

	return theResultArray;
}

/*
	- everyObjectOfKindOfClass:
 */
- (NSArray *)everyObjectOfKindOfClass:(Class)aClass
{
	NSUInteger		theIndex,
							theCount;
	NSMutableArray		* theResultArray;

	theCount = [self count];
	theResultArray = [NSMutableArray arrayWithCapacity:theCount];
	
	for( theIndex = 0; theIndex < theCount; theIndex++ )
	{
		id		theObject;

		theObject = [self objectAtIndex:theIndex];

		if( [theObject isKindOfClass:aClass] )
			[theResultArray addObject:theObject];
	}

	return theResultArray;
}

/*
	- makeObjectsPerformFunction:
 */
- (BOOL)makeObjectsPerformFunction:(BOOL (*)(id))aFunc
{
	NSUInteger		theIndex,
							theCount = [self count];
	
	for( theIndex = 0; theIndex < theCount; theIndex++ )
		if( !aFunc([self objectAtIndex:theIndex]) ) return NO;

	return YES;
}

/*
	- makeObjectsPerformFunction:withContext:
 */
- (BOOL)makeObjectsPerformFunction:(BOOL (*)(id, void *))aFunc withContext:(void *)aContext
{
	NSUInteger		theIndex,
							theCount = [self count];

	for( theIndex = 0; theIndex < theCount; theIndex++ )
		if( !aFunc( [self objectAtIndex:theIndex], aContext ) ) return NO;

	return YES;
}

/*
	- makeObjectsPerformFunction:withContext:
 */
- (BOOL)makeObjectsPerformFunction:(BOOL (*)(id, id))aFunc withObject:(id)anObject
{
	NSUInteger		theIndex,
							theCount = [self count];

	for( theIndex = 0; theIndex < theCount; theIndex++ )
		if( !aFunc( [self objectAtIndex:theIndex], anObject ) ) return NO;

	return YES;
}

/*
	-makeObjectsPerformFunction:usingIndicies:
 */
- (BOOL)makeObjectsPerformFunction:(BOOL (*)(id))aFunc usingIndicies:(NSIndexSet *)anIndexSet
{
	NSUInteger		theIndex,
	theCount = [self count];
	
	for( theIndex = 0; theIndex < theCount; theIndex++ )
		if( [anIndexSet containsIndex:theIndex] && !aFunc( [self objectAtIndex:theIndex] ) ) return NO;
	
	return YES;
}

/*
	-makeObjectsPerformFunction:withObject:usingIndicies:
 */
- (BOOL)makeObjectsPerformFunction:(BOOL (*)(id, id))aFunc withObject:(id)anObject usingIndicies:(NSIndexSet *)anIndexSet
{
	NSUInteger		theIndex,
	theCount = [self count];
	
	for( theIndex = 0; theIndex < theCount; theIndex++ )
		if( [anIndexSet containsIndex:theIndex] && !aFunc( [self objectAtIndex:theIndex], anObject ) ) return NO;
	
	return YES;
}

/*
	-makeObjectsPerformFunction:usingPredicate:
 */
- (BOOL)makeObjectsPerformFunction:(BOOL (*)(id))aFunc usingPredicate:(NSPredicate *)aPredicate
{
	NSUInteger		theIndex,
	theCount = [self count];
	
	for( theIndex = 0; theIndex < theCount; theIndex++ )
	{
		id		theObject = [self objectAtIndex:theIndex];
		if( [aPredicate evaluateWithObject:theObject] && !aFunc( theObject ) ) return NO;
	}
	
	return YES;
}


/*
	-makeObjectsPerformFunction:withObject:usingPredicate:
 */
- (BOOL)makeObjectsPerformFunction:(BOOL (*)(id, id))aFunc withObject:(id)anObject usingPredicate:(NSPredicate *)aPredicate
{
	NSUInteger		theIndex,
	theCount = [self count];
	
	for( theIndex = 0; theIndex < theCount; theIndex++ )
	{
		id		theObject = [self objectAtIndex:theIndex];
		if( [aPredicate evaluateWithObject:theObject] && !aFunc( theObject, anObject ) ) return NO;
	}
	
	return YES;
}

/*
	- findObjectWithFunction:
 */
- (id)findObjectWithFunction:(BOOL (*)(id))aFunc
{
	id						theFoundObject = nil;
	NSUInteger		theIndex,
							theCount = [self count];

	for( theIndex = 0; theIndex < theCount && theFoundObject == nil; theIndex++ )
	{
		id		theObject = [self objectAtIndex:theIndex];
		if( aFunc( theObject ) )
				theFoundObject = theObject;
	}

	return theFoundObject;
}

/*
	- findObjectWithFunction:withContext:
 */
- (id)findObjectWithFunction:(BOOL (*)(id, void *))aFunc withContext:(void*)aContext
{
	id						theFoundObject = nil;
	NSUInteger		theIndex,
		theCount = [self count];

	for( theIndex = 0; theIndex < theCount && theFoundObject == nil; theIndex++ )
	{
		id		theObject = [self objectAtIndex:theIndex];
		if( aFunc( theObject, aContext ) )
			theFoundObject = theObject;
	}

	return theFoundObject;
}

/*
	-findAllObjectWithFunction:
 */
- (NSArray *)findAllObjectWithFunction:(BOOL (*)(id))aFunc
{
	NSMutableArray		* theFoundObjectArray = [NSMutableArray arrayWithCapacity:[self count]];
	NSUInteger		theIndex,
							theCount = [self count];
	
	for( theIndex = 0; theIndex < theCount; theIndex++ )
	{
		id		theObject = [self objectAtIndex:theIndex];
		if( aFunc( theObject ) )
			[theFoundObjectArray addObject:theObject];
	}
	
	return theFoundObjectArray;
}

/*
	-findAllObjectWithFunction:withContext:
 */
- (NSArray *)findAllObjectWithFunction:(BOOL (*)(id, void *))aFunc withContext:(void*)aContext
{
	NSMutableArray		* theFoundObjectArray = [NSMutableArray arrayWithCapacity:[self count]];
	NSUInteger		theIndex,
		theCount = [self count];
	
	for( theIndex = 0; theIndex < theCount; theIndex++ )
	{
		id		theObject = [self objectAtIndex:theIndex];
		if( aFunc( theObject, aContext ) )
			[theFoundObjectArray addObject:theObject];
	}
	
	return theFoundObjectArray;
}

/*
	- indexOfObjectWithFunction:
 */
- (NSUInteger)indexOfObjectWithFunction:(BOOL (*)(id))aFunc
{
	NSUInteger		theIndex,
							theFoundIndex = NSNotFound,
							theCount = [self count];
	
	for( theIndex = 0; theIndex < theCount && theFoundIndex == NSNotFound; theIndex++ )
	{
		if( aFunc( [self objectAtIndex:theIndex] ) )
			theFoundIndex = theIndex;
	}
	
	return theFoundIndex;
}

/*
	- indexOfObjectWithFunction:withContext:
 */
- (NSUInteger)indexOfObjectWithFunction:(BOOL (*)(id, void *))aFunc withContext:(void*)aContext
{
	NSUInteger		theIndex,
	theFoundIndex = NSNotFound,
							theCount = [self count];

	for( theIndex = 0; theIndex < theCount && theFoundIndex == NSNotFound; theIndex++ )
	{
		if( aFunc( [self objectAtIndex:theIndex], aContext ) )
			theFoundIndex = theIndex;
	}

	return theFoundIndex;
}

- (void)sendEveryObjectToTarget:(id)aTarget withSelector:(SEL)aSelector
{
	NSUInteger		theIndex,
							theCount = [self count];
	
	for( theIndex = 0; theIndex < theCount; theIndex++ )
		[aTarget performSelector:aSelector withObject:[self objectAtIndex:theIndex]];
}

- (void)sendEveryObjectToTarget:(id)aTarget withSelector:(SEL)aSelector withObject:(id)anObject
{
	NSUInteger		theIndex,
							theCount = [self count];
	
	for( theIndex = 0; theIndex < theCount; theIndex++ )
		[aTarget performSelector:aSelector withObject:[self objectAtIndex:theIndex] withObject:anObject];
}

/*
	- firstObject
 */
- (id)firstObject
{
	return ([self count] > 0 ) ? [self objectAtIndex:0] : nil;
}

/*
	- isEmpty
 */
- (BOOL)isEmpty
{
	return [self count] == 0;
}

/*
	-objectEnumeratorWithIndicies:
 */
- (NSEnumerator *)objectEnumeratorWithIndicies:(NSIndexSet *)anIndicies
{
	return [NSEnumeratrorWithArrayIndicies enumeratrorWithArray:self indicies:anIndicies];
}

- (id)firstObjectReturningYESToSelector:(SEL)aSelector withObject:(id)anObject
{
	id		theFoundObject = nil;
	for( NSUInteger theIndex = 0, theCount = [self count]; theIndex < theCount && theFoundObject == nil; theIndex ++ )
	{
		id	theObject = [self objectAtIndex:theIndex];
		if( [theObject respondsToSelector:aSelector] )
		{
			BOOL (*theTestMethod)(id, SEL, id) = (BOOL (*)(id, SEL, id))[theObject methodForSelector:aSelector];
			if( theTestMethod( theObject, aSelector, anObject ) )
				theFoundObject = theObject;
		}
	}

	return theFoundObject;
}

/*
	-firstObjectOfKind:
 */
- (id)firstObjectOfKind:(Class)aClass
{
	return [self firstObjectReturningYESToSelector:@selector(isKindOfClass:) withObject:aClass];
}

@end

#if 0
@implementation NSMutableArray (NDUtilities)

- (void)insertObject:(id)anObject usingFunction:(int (*)(id, id, void *))aCompFun context:(void *)aContext
{
	unsigned int	theIndex = 0,
					theCount = [self count];
	for( theIndex = 0; theIndex < theCount && anObject != nil; theIndex++ )
	{
		if( aCompFun( anObject, [self objectAtIndex:theIndex], aContext ) > 0 )
		{
			[self insertObject:anObject atIndex:theIndex];
			anObject = nil;
		}
	}
	if( anObject != nil )
		[self addObject:anObject];
}

@end
#endif

@implementation NSEnumeratrorWithArrayIndicies

/*
	+enumeratrorWithArray:indicies:
 */
+ (id)enumeratrorWithArray:(NSArray *)anArray indicies:(NSIndexSet *)anIndiciesSet
{
	return [[[self alloc] initWithArray:anArray indicies:anIndiciesSet] autorelease];
}

/*
	-initWithArray:indicies:
 */
- (id)initWithArray:(NSArray *)anArray indicies:(NSIndexSet *)anIndiciesSet
{
	if( (self = [super init]) != nil )
	{
		array = [anArray retain];
		indexSet = [anIndiciesSet retain];
		currentIndex = [indexSet indexGreaterThanOrEqualToIndex:0];
	}
	return self;
}

/*
	-nextObject
 */
- (id)nextObject
{
	NSUInteger	theCount = [array count];
	id					theObject = nil;
	if( currentIndex < theCount && currentIndex != NSNotFound )
	{
		theObject = [array objectAtIndex:currentIndex];		
		currentIndex = [indexSet indexGreaterThanIndex:currentIndex];
	}
	return theObject;
}

@end
