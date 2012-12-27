//
//  MGSPopupButtonCell.m
//  Mother
//
//  Created by Jonathan on 16/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSPopupButtonCell.h"


@implementation MGSPopupButtonCell

/*
 
 track mouse
 
 this gives Mail.app like popup button behaviour
 
 */
- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)untilMouseUp
{
    BOOL tracking = [super trackMouse:theEvent inRect:cellFrame ofView:controlView untilMouseUp:untilMouseUp];
    
	// show our menu on left mouse
	if ([theEvent type] == NSLeftMouseDown) {
		[NSMenu popUpContextMenu:[self menu] withEvent:theEvent forView:controlView];
		tracking = NO;
	}
    
	return tracking;
}

@end
