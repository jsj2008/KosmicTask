//  NSTreeController-DMExtensions.m
//  Library
//
//  Created by William Shipley on 3/10/06.
//  Copyright 2006 Delicious Monster Software, LLC. Some rights reserved,
//    see Creative Commons license on wilshipley.com

#import "NSTreeController-DMExtensions.h"

@interface NSTreeController (DMExtensions_Private)
- (NSIndexPath *)dm_indexPathFromIndexPath:(NSIndexPath *)baseIndexPath inChildren:(NSArray *)children
							  childCount:(NSUInteger)childCount toObject:(id)object;
@end

@implementation NSTreeController (MGS_Extensions)

/*
 
 - mgs_processOutlineView:node:options:
 
 */
- (void)mgs_processOutlineView:(NSOutlineView *)outlineView node:(id)node options:(NSSet *)options
{
	id outlineItem = [self mgs_outlineItemForObject:node];
	if (!outlineItem) {
		return;
	}
	
	// select item
	if ([options containsObject:@"select"]) {
		[self dm_setSelectedObjects:[NSArray arrayWithObject:node]];
	}
	
	// expand item
	if ([options containsObject:@"expand"]) {
		[outlineView expandItem:outlineItem];
	} else if ([options containsObject:@"expandChildren"]) {
		[outlineView expandItem:outlineItem expandChildren:YES];
	}
	
}

/*
 
 - mgs_outlineItemForObject:
 
 */
-(NSTreeNode *)mgs_outlineItemForObject:(id)object
{	
	// NSTreeController.h states that arrangedObjects is a root proxy object that responds to -childNodes
	id proxyTree = [self arrangedObjects];
	NSAssert([proxyTree respondsToSelector:@selector(childNodes)], @"NSTreeController arranged objects proxy does not respond to -childNodes");
	NSAssert([proxyTree respondsToSelector:@selector(descendantNodeAtIndexPath:)], @"NSTreeController arranged objects proxy does not respond to -descendantNodeAtIndexPath:");

	NSIndexPath *indexPath = [self dm_indexPathToObject:object];
	
	id outlineItem = [proxyTree descendantNodeAtIndexPath:indexPath]; // this will be an NSTreeNode
	
	return outlineItem;
}

@end

@implementation NSTreeController (DMExtensions)

- (void)dm_setSelectedObjects:(NSArray *)newSelectedObjects
{
	NSMutableArray *indexPaths = [NSMutableArray array];
	unsigned int selectedObjectIndex;
	for (selectedObjectIndex = 0; selectedObjectIndex < [newSelectedObjects count];
		 selectedObjectIndex++) {
		id selectedObject = [newSelectedObjects objectAtIndex:selectedObjectIndex];
		NSIndexPath *indexPath = [self dm_indexPathToObject:selectedObject];
		if (indexPath)
			[indexPaths addObject:indexPath];
	}
	
	[self setSelectionIndexPaths:indexPaths];
}

- (NSIndexPath *)dm_indexPathToObject:(id)object
{
	NSArray *children = [self content];
	return [self dm_indexPathFromIndexPath:nil inChildren:children childCount:[children count]
								toObject:object];
}

@end


@implementation NSTreeController (DMExtensions_Private)

- (NSIndexPath *)dm_indexPathFromIndexPath:(NSIndexPath *)baseIndexPath inChildren:(NSArray *)children
							  childCount:(NSUInteger)childCount toObject:(id)object
{
	NSUInteger childIndex;
	for (childIndex = 0; childIndex < childCount; childIndex++) {
		id childObject = [children objectAtIndex:childIndex];
		
		NSArray *childsChildren = nil;
		NSUInteger childsChildrenCount = 0;
		NSString *leafKeyPath = [self leafKeyPath];
		if (!leafKeyPath || [[childObject valueForKey:leafKeyPath] boolValue] == NO) {
			NSString *countKeyPath = [self countKeyPath];
			if (countKeyPath)
				childsChildrenCount = [[childObject valueForKey:leafKeyPath] unsignedIntValue];
			if (!countKeyPath || childsChildrenCount != 0) {
				NSString *childrenKeyPath = [self childrenKeyPath];
				childsChildren = [childObject valueForKey:childrenKeyPath];
				if (!countKeyPath)
					childsChildrenCount = [childsChildren count];
			}
		}
		
		BOOL objectFound = [object isEqual:childObject];
		if (!objectFound && childsChildrenCount == 0)
			continue;
		
		NSIndexPath *indexPath = (baseIndexPath == nil) ? [NSIndexPath indexPathWithIndex:childIndex]
        : [baseIndexPath indexPathByAddingIndex:childIndex];
		
		if (objectFound)
			return indexPath;
		
		NSIndexPath *childIndexPath = [self dm_indexPathFromIndexPath:indexPath inChildren:childsChildren
														 childCount:childsChildrenCount toObject:object];
		if (childIndexPath)
			return childIndexPath;
	}
	
	return nil;
}
@end
