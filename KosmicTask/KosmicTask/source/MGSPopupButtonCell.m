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
- (BOOL)trackMouse:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)untilMouseUp
{
	// show our menu on left mouse
	if ([event type] == NSLeftMouseDown) {
        
        NSPoint result = [controlView convertPoint:cellFrame.origin toView:nil];
       
        NSEvent *newEvent = [NSEvent mouseEventWithType: [event type]
                                               location: result
                                          modifierFlags: [event modifierFlags]
                                              timestamp: [event timestamp]
                                           windowNumber: [event windowNumber]
                                                context: [event context]
                                            eventNumber: [event eventNumber]
                                             clickCount: [event clickCount]
                                               pressure: [event pressure]];
        
        // need to generate a new event otherwise selection of button
        // after menu display fails
		[NSMenu popUpContextMenu:[self menu] withEvent:newEvent forView:controlView];
        
		return YES;
	}
	
	return [super trackMouse:event inRect:cellFrame ofView:controlView untilMouseUp:untilMouseUp];
}

@end
