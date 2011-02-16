//
//  MGSTextField.m
//  Mother
//
//  Created by Jonathan on 07/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSTextField.h"

//
// when NSTextField is having its background drawn behind it
// the focus ring corrupts the background and must be redrawn.
// hence the need to setNeedsDisplay on superview when control
// becomes firstresponder
//
@implementation MGSViewTextField

- (BOOL)acceptsFirstResponder
{
	[[self superview] setNeedsDisplay:YES];
	return [super acceptsFirstResponder];
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
