//
//  iTableColumnHeaderCell.m
//  iTableColumnHeader
//
//  Created by Matt Gemmell on Thu Feb 05 2004.
//  <http://iratescotsman.com/>
//

#import "iTableColumnHeaderCell.h"

// class extension
@interface iTableColumnHeaderCell()
- (void)click:(id)sender;
@end

@implementation iTableColumnHeaderCell


- (id)initTextCell:(NSString *)text
{
    if ((self = [super initTextCell:text])) {
        //metalBg = [[NSImage imageNamed:@"metal_column_header.png"] retain];
        if (text == nil || [text isEqualToString:@""]) {
            [self setTitle:@"Title"];
        }
        //[metalBg setFlipped:YES];
        attrs = [[NSMutableDictionary dictionaryWithDictionary:
                                        [[self attributedStringValue] 
                                                    attributesAtIndex:0 
                                                    effectiveRange:NULL]] 
                                                        mutableCopy];
		_sortPriority = 0;
		_sortAscending = YES;
		
		[self setTarget:self];
		[self setAction:@selector(click:)];
		
        return self;
    }
    return nil;
}



- (void)highlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	#pragma unused(flag)
	#pragma unused(cellFrame)
	#pragma unused(controlView)
	// doesn't seem to get called
	//[super highlight:flag withFrame:cellFrame inView:controlView];
	//NSLog(@"highlight called");
}

- (void)drawWithFrame:(NSRect)inFrame inView:(NSView*)inView
{

	NSColor *start, *end;
	NSBezierPath *bgPath = [NSBezierPath bezierPathWithRect:inFrame];
	
	//NSLog(@"state = %d", [self state]);
	//NSLog(@"highlight = %d", [self isHighlighted]);
	
	if ([self state]) {
		// itunes selected column
		end = [NSColor colorWithCalibratedRed:0.761f green:0.812f blue:0.867f alpha:1.0f];
		start = [NSColor colorWithCalibratedRed:0.490f green:0.576f blue:0.698f alpha:1.0f];		
	} else {
		if (_sortPriority == 0) {
			end = [NSColor colorWithCalibratedRed:0.333f green:0.333f blue:0.333f alpha:1.0f];
		start = [NSColor colorWithCalibratedRed:0.733f green:0.733f blue:0.733f alpha:1.0f];		
		} else {
		// itunes column
		end = [NSColor colorWithCalibratedRed:0.859f green:0.859f blue:0.859f alpha:1.0f];
		start = [NSColor colorWithCalibratedRed:0.733f green:0.733f blue:0.733f alpha:1.0f];	
		}
		

		
    /* Draw metalBg lowest pixel along the bottom of inFrame. */
    /*NSRect tempSrc = NSZeroRect;
    tempSrc.size = [metalBg size];
    tempSrc.origin.y = tempSrc.size.height - 1.0;
    tempSrc.size.height = 1.0;
    
    NSRect tempDst = inFrame;
    tempDst.origin.y = inFrame.size.height - 1.0;
    tempDst.size.height = 1.0;
    
    [metalBg drawInRect:tempDst 
               fromRect:tempSrc 
              operation:NSCompositeSourceOver 
               fraction:1.0];
    */
    /* Draw rest of metalBg along width of inFrame. */
    /*
	 tempSrc.origin.y = 0.0;
    tempSrc.size.height = [metalBg size].height - 1.0;
    
    tempDst.origin.y = 1.0;
    tempDst.size.height = inFrame.size.height - 2.0;
    
    [metalBg drawInRect:tempDst 
               fromRect:tempSrc 
              operation:NSCompositeSourceOver 
               fraction:1.0];
    */
	}

	NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:start endingColor:end];
	[gradient drawInBezierPath:bgPath angle:-90];
	
    /* Draw white text centered, but offset down-left. */
    float offset = 0.5f;
    [attrs setValue:[NSColor colorWithCalibratedWhite:1 alpha:0.7f] 
             forKey:@"NSColor"];
    
    NSRect centeredRect = inFrame;
    centeredRect.size = [[self stringValue] sizeWithAttributes:attrs];
    centeredRect.origin.x += 
        ((inFrame.size.width - centeredRect.size.width) / 2.0f) - offset;
    centeredRect.origin.y = 
        ((inFrame.size.height - centeredRect.size.height) / 2.0f) + offset;
    //[[self stringValue] drawInRect:centeredRect withAttributes:attrs];
    
    /* Draw black text centered. */
    [attrs setValue:[NSColor blackColor] forKey:@"NSColor"];
    centeredRect.origin.x += offset;
    centeredRect.origin.y -= offset;
    [[self stringValue] drawInRect:centeredRect withAttributes:attrs];
	
	if (_sortPriority > 0) {
	[super drawSortIndicatorWithFrame:inFrame inView:inView  
						   ascending:_sortAscending priority:_sortPriority];
	}

}

- (void)click:(id)sender
{
	#pragma unused(sender)
	
	[self setState: 1];
}
// see http://www.cocoabuilder.com/archive/message/cocoa/2008/1/3/195782
// http://www.cocoabuilder.com/archive/message/cocoa/2008/1/4/195832
/*-(void)drawSortIndicatorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView ascending:(BOOL)ascending priority:(int)priority 
{
	[self drawSortIndicatorWithFrame:cellFrame inView:controlView ascending:_sortAscending priority:_sortPriority];
}
*/
-(void)setSortAscending:(BOOL)asc priority:(int)pri
{
	_sortPriority = pri;
	_sortAscending = asc;
	
	[(NSControl *)[self controlView] updateCell: self];
}

@end
