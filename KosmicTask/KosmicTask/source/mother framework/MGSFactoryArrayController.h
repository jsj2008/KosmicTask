//
//  MGSArray.h
//  Mother
//
//  Created by Jonathan on 09/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MGSFactoryArrayController : NSObject {
@private
	NSMutableArray *_array;
	NSMapTable *_mapTable;
	Class _itemClass;			// class of items in the array
	SEL _itemFactorySelector;	// factory selector to create new instance of class
	SEL _itemAddSelector;		// add item selector
	BOOL _useFactorySelector;
}

@property BOOL useFactorySelector;

// note that this appoach is not compatible with bindings
- (void)addItem:(id)item;  
- (id)itemAtIndex:(NSUInteger)index;
- (NSInteger)count;
- (void)setArray:(NSMutableArray *)array;
- (id)initWithItemClass:(Class)aClass withFactorySelector:(SEL)aSelector withAddItemSelector:(SEL)addSelector;
- (void)removeItemAtIndex:(NSUInteger)index;
- (NSMutableArray *)array;
- (NSInteger)indexOfItem:(id)item;
- (void)moveItemAtIndex:(NSUInteger)sourceIdx toIndex:(NSUInteger)targetIdx;
- (void)insertItem:(id)item atIndex:(NSUInteger)idx;
- (void)replaceItemAtIndex:(NSUInteger)idx withItem:(id)item;
- (NSArray *)factoryArray;
@end
