//
//  MGSPopupButton.m
//  Mother
//
//  Created by Jonathan on 16/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSPopupButton.h"


@implementation MGSPopupButton

/*
 
 mouse down
 
 we cannot just show our menu here as the methods block.
 see MGSPopupButtonCell.
 
 */
- (void)mouseDown:(NSEvent *)theEvent {

#undef MGS_USE_POPUP_CELL 
    
#ifdef MGS_USE_POPUP_CELL
    if (self.menu) {
        NSMenu *popUpMenu = [[self menu] copy];
        [popUpMenu insertItemWithTitle:@"" action:NULL keyEquivalent:@"" atIndex:0];	// blank item at top
        [popUpCell setMenu:popUpMenu];
        
        // and show it
        [popUpCell performClickWithFrame:[self bounds] inView:self];
        
        [self setNeedsDisplay: YES];
    } else {
        [super mouseDown:theEvent];
    }
#else
    
    
	if ([theEvent type] == NSLeftMouseDown) {
		[[self cell] setMenu:[self menu]];
	} else {
		[[self cell] setMenu:nil];
	}
	[super mouseDown:theEvent];
#endif
    
}

- (void)setMenu:(NSMenu *)menu
{
    [super setMenu:menu];
    
#ifdef MGS_USE_POPUP_CELL
    
    if (menu) {
        popUpCell = [[NSPopUpButtonCell alloc] initTextCell:@""];
        [popUpCell setPullsDown:YES];
        [popUpCell setPreferredEdge:NSMaxYEdge];
    } else {
        popUpCell = nil;
    }
#endif
}
@end
