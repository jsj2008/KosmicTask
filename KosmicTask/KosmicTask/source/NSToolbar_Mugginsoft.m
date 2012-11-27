//
//  NSToolbar_Mugginsoft.m
//  Mother
//
//  Created by Jonathan on 01/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "NSToolbar_Mugginsoft.h"


@implementation NSToolbar (Mugginsoft)

/*
 
 get index of toolbar item with identifier
 
 */
- (NSInteger)indexOfItemWithItemIdentifier:(NSString *)identifier
{
	NSInteger idx = 0;
	for (NSToolbarItem *item in [self items]) {
		if ([[item itemIdentifier] isEqualToString:identifier]) {
			return idx;
		}
		idx++;
	}
	return -1;
}

/*
 
 remove toolbar item with identifier

 */
- (void)removeItemWithItemIdentifier:(NSString *)identifier
{
	NSInteger idx = [self indexOfItemWithItemIdentifier:identifier];
	if (idx == -1) return;
	
	[self removeItemAtIndex:idx];
}

/*
 
 remove items starting at index
 
 */
- (void)removeItemsStartingAtIndex:(NSInteger)startIndex
{
	for (NSInteger i = [[self items] count] - 1; i >= startIndex; i--) {
		[self removeItemAtIndex:i];
	}
}
@end
