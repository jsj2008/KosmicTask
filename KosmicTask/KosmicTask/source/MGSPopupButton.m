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
	if ([theEvent type] == NSLeftMouseDown) {
		[[self cell] setMenu:[self menu]];
	} else {
		[[self cell] setMenu:nil];
	}
	[super mouseDown:theEvent];
}

@end
