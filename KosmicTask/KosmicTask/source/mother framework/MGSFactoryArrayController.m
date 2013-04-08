//
//  MGSFactoryArrayController.m
//  Mother
//
//  Created by Jonathan on 09/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
// This class encapsulates a mutable array.
// An itemClass and factory selector are defined to be called
// against the items in the array on retrieval.
// This typically done to wrap a particular class about a dictionary in the array.
// Only items of itemClass can be added to the array.
//
// The only advantage to all this is that the entire array of objects is always available.
// Probably not worth the extra effort and complexity.
//
// Two modes of operation.
// 1. _useFactorySelector:YES
//    items in the array are dictionaries and on item retrieval
//    an object of type _itemClass is created using the _itemFactorySelector to create a
//    wrapper object for the dictionary
//
// 2. _useFactorySelector:NO
//    items in the array are of type _itemClass
//
#import "MGSMother.h"
#import "MGSFactoryArrayController.h"

@interface MGSFactoryArrayController(Private)
- (void)validate;
@end

@implementation MGSFactoryArrayController

@synthesize useFactorySelector = _useFactorySelector;

/*
 init
 
 must call the designated initializer
 
 */
- (id)init
{
	// this will raise an exception
	return [self initWithItemClass:nil withFactorySelector:nil withAddItemSelector:nil];
}

/*
 
 designated init
 
 */
- (id)initWithItemClass:(Class)aClass withFactorySelector:(SEL)aSelector withAddItemSelector:(SEL)addSelector
{
	if ((self = [super init])) {
		_itemClass = aClass;
		_itemFactorySelector = aSelector;
		_itemAddSelector = addSelector;
		[self validate];
		_useFactorySelector = YES;
	}
	return self;
}

/*
 
 - addItem
 
 */
- (void)addItem:(id)item
{
	NSAssert(item, @"item argument is nil");
	NSAssert([item isKindOfClass:_itemClass], @"add item to array is of wrong class");

	if (_useFactorySelector == YES) {
		item = [item performSelector:_itemAddSelector];
	}
	
	[_array addObject:item];
}

/*
 
 - insertItem:atIndex:
 
 */
- (void)insertItem:(id)item atIndex:(NSUInteger)idx
{
	NSAssert(item, @"item argument is nil");
	NSAssert([item isKindOfClass:_itemClass], @"add item to array is of wrong class");
    
	if (_useFactorySelector == YES) {
		item = [item performSelector:_itemAddSelector];
	}
	
	[_array insertObject:item atIndex:idx];
}

/*
 
 set array
 
 */
- (void)setArray:(NSMutableArray *)array 
{
	_array = array;
	
	// map table with weak keys to weak objects and no copying
	_mapTable = [[NSMapTable alloc] initWithKeyOptions: (NSMapTableZeroingWeakMemory | NSPointerFunctionsObjectPersonality)
										  valueOptions: (NSMapTableZeroingWeakMemory | NSPointerFunctionsObjectPersonality)
											  capacity:50];
	return;
}


/*
 
 array
 
 */
- (NSMutableArray *)array
{
	return _array;
}

/*
 
 - factoryArray
 
 we don't want to mutate this
 
 */
- (NSArray *)factoryArray
{
    NSMutableArray *factoryArray = [NSMutableArray arrayWithCapacity:[_array count]];
    for (NSUInteger i = 0; i < [_array count]; i++) {
        [factoryArray addObject:[self itemAtIndex:i]];
    }
    
    return factoryArray;
}
/*
 
 item at index
 
 */
- (id)itemAtIndex:(NSUInteger)idx
{
	id item = [_array objectAtIndex:idx];
	
	if (_useFactorySelector) {
		
		// if we have already cached the object then retrieve it
		id wrapper = [_mapTable objectForKey:item];
		if (wrapper) {
			return wrapper;
		}
		
		// generate wrapper object from item
		wrapper = [_itemClass performSelector:_itemFactorySelector withObject:item];
		
		[_mapTable setObject:wrapper forKey:item];
		
		return wrapper;
	} 
	
	return item;
}

/*
 
 index of item
 
 */
- (NSInteger)indexOfItem:(id)item
{
	return [_array indexOfObjectIdenticalTo:item];
}

/*
 
 count
 
 */
- (NSInteger)count
{
	return [_array count];
}

/*
 
 remove item at index
 
 */
- (void)removeItemAtIndex:(NSUInteger)idx
{
	[_array removeObjectAtIndex:idx];
}

/*
 
 - moveItemAtIndex:toIndex
 
 */
- (void)moveItemAtIndex:(NSUInteger)sourceIdx toIndex:(NSUInteger)targetIdx
{
    id item = [_array objectAtIndex:sourceIdx];
    [_array removeObjectAtIndex:sourceIdx];
    [_array insertObject:item atIndex:targetIdx];
}

/*
 
 - replaceItemAtIndex:withItem:
 
 */
- (void)replaceItemAtIndex:(NSUInteger)idx withItem:(id)item
{
    [self removeItemAtIndex:idx];
    [self insertItem:item atIndex:idx];
}
@end

@implementation MGSFactoryArrayController(Private)

/*
 
 validate
 
 */
- (void)validate
{
	NSAssert(_itemClass, @"array item class is nil");
	NSAssert(_itemFactorySelector, @"array item factory selector is nil");
	NSAssert([_itemClass respondsToSelector:_itemFactorySelector], @"class does not respond to item factory selector");
}
@end
