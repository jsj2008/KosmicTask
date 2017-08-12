//
//  MGSCollapsibleSplitView.m
//  KosmicTask
//
//  Created by Jonathan on 15/10/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//
// see http://homepage.mac.com/jrc/contrib/cocoa/CollapsableSplitView.m.txt

#import "MGSCollapsibleSplitView.h"


@implementation MGSCollapsibleSplitView

/*
 
 - initWithFrame:
 
 */
- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		_collapsedSubviewsDict = [NSMutableDictionary new];
    }
    return self;
}

/*
 
 - awakeFromNib
 
 */
- (void) awakeFromNib
{
	_collapsedSubviewsDict = [NSMutableDictionary new];
}

/*
 
 - drawDividerInRect:
 
 */
- (void)drawDividerInRect:(NSRect)aRect	// XXX: doesn't really belong here
{
	if ([_collapsedSubviewsDict count] > 0)
	{
		BOOL isVertical = [self isVertical];
		
		NSEnumerator * keyEnumerator = [_collapsedSubviewsDict keyEnumerator];
		id key;
		while ((key = [keyEnumerator nextObject]))
		{
			NSView * tempView = [key pointerValue];
			
			// If the collapsed placeholder view has now been resized by the user
			// to the extent that it should be uncollapsed (i.e. expanded) ...
			NSSize size = [tempView frame].size;
			if ((isVertical && size.width > 0.0) || (isVertical == NO && size.height > 0.0))
			{
				// Swap in subview
				NSView * origSubview = [_collapsedSubviewsDict objectForKey:key];
				[origSubview setFrameSize:size];
				[self replaceSubview:tempView with:origSubview];
				[_collapsedSubviewsDict removeObjectForKey:key];
			}
		}
	}
	
	[super drawDividerInRect:aRect];
}

/*
 
 - collapseSubviewAt:
 
 */
- (void)collapseSubviewAt:(int)offset
{
	NSView * subview = [[self subviews] objectAtIndex:offset];
	NSView * tempView = [[NSView alloc] initWithFrame:NSZeroRect];
	
	// Swap out subview
	id key = tempView; // pre ARC was [NSValue valueWithPointer:tempView];
	[_collapsedSubviewsDict setObject:subview forKey:key];
	[self replaceSubview:subview with:tempView];
	[self adjustSubviews];
}

/*
 
 - uncollapseSubviewAt:
 
 */
- (void)uncollapseSubviewAt:(int)offset
{
	NSView * subview = [[self subviews] objectAtIndex:offset];
	NSView * tempView = [[NSView alloc] initWithFrame:NSZeroRect];
	
	// Swap out subview
	id key = tempView; // pre ARC was [NSValue valueWithPointer:tempView];
	[_collapsedSubviewsDict setObject:subview forKey:key];
	[self replaceSubview:subview with:tempView];
	[self adjustSubviews];
}

@end
