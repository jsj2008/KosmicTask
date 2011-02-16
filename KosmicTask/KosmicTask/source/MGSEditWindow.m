//
//  MGSEditWindow.m
//  Mother
//
//  Created by Jonathan on 01/09/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSEditWindow.h"
#import "MGSEditWindowController.h"
#import "MGSFragaria/SMLTextView.h"

@implementation MGSEditWindow

/*
 
 set document edited
 
 */
- (void)setDocumentEdited:(BOOL)flag
{
	[super setDocumentEdited:flag];
	if ([self delegate] && [[self delegate] respondsToSelector:@selector(documentEdited:forWindow:)]) {
		[(id)[self delegate] documentEdited:flag forWindow:self];
	}
}

/*
 
 - sendEvent:
 
 */
- (void)sendEvent:(NSEvent *)event
{
	if ([event type] == NSKeyDown) {
		NSInteger keyCode = [event keyCode];
		NSUInteger flags = [event modifierFlags];
	
		if (flags & NSShiftKeyMask) { // Shift
			if (keyCode == 48) { // 48 is Tab
				
				if ([[self firstResponder] isKindOfClass:[SMLTextView class]]) {
				
					if ([self delegate] && [[self delegate] respondsToSelector:@selector(shiftLeftAction:)]) {
						[(id)[self delegate] shiftLeftAction:self];
						return;
					}	
				}
			}
		} 
	}
	
	[super sendEvent:event];
}

@end
