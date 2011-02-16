//
//  MGSViewButton.m
//  Mother
//
//  Created by Jonathan on 07/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSButton.h"


@implementation MGSViewButton

- (BOOL)acceptsFirstResponder
{
	[[self superview] setNeedsDisplay:YES];
	return [super acceptsFirstResponder];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	[[self superview] setNeedsDisplay:YES];
	[super mouseDown:theEvent];
	[self mouseUp:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	#pragma unused(theEvent)
	
	[[self superview] setNeedsDisplay:YES];
	//[super mouseUp:theEvent];
}


// this actually does not seem to be effective
// as the focus ring must be drawn after the background is updated.
// the NSControl - (void)controlTextDidEndEditing:(NSNotification *)aNotification 
// deleaget seems to work though
- (BOOL)resignFirstResponder
{
	[[self superview] setNeedsDisplay:YES];
	return [super resignFirstResponder];
}

@end
