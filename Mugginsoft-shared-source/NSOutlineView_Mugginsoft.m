//
//  NSOutlineView_Mugginsoft.m
//  KosmicTask
//
//  Created by Jonathan on 01/09/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "NSOutlineView_Mugginsoft.h"


@implementation NSOutlineView (Mugginsoft)

/*
 
 - mgs_expandAll
 
 */
- (void)mgs_expandAll
{
	for (id item in [self mgs_expandableItems]) {
		[self expandItem:item expandChildren:YES];
	}
}

/*
 
 - mgs_collapseAll
 
 */
- (void)mgs_collapseAll
{
	for (id item in [self mgs_expandableItems]) {
		[self collapseItem:item collapseChildren:YES];
	}
}
/*
 
 - mgs_expandableItems
 
 */
- (NSMutableArray *)mgs_expandableItems
{
	NSMutableArray *expandableItems = [NSMutableArray arrayWithCapacity:10];
	NSInteger numberOfRows = [self numberOfRows];
	for (int i = 0; i < numberOfRows; i++) {
		id item = [self itemAtRow:i];
		if ([self isExpandable:item]) {
			[expandableItems addObject:item];
		}
	}
	
	return expandableItems;
}

@end
