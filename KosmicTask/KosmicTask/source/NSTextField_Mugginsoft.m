//
//  NSTextField_Mugginsoft.m
//  Mother
//
//  Created by Jonathan on 18/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "NSTextField_Mugginsoft.h"

enum { IFVerticalPadding = 0 };

@implementation NSTextField (Mugginsoft)

/*
 
 autosize height using field editor
 
 Details taken from.
 http://www.cocoadev.com/index.pl?IFVerticallyExpandingTextfield
 
 */
- (float) verticalHeightToFit
 {
	 // Entry point for vertical expansion.  Call this method if you need to manually
	 // force an autosize.  Most of the time this is done for you in response to the 
	 // textDidChange and viewDidEndLiveResize callbacks.
	 //
	 // Note that if we're forced to steal the field editor and first responder status,
	 // quirky behavior can occur if we just throw first responder back to whoever 
	 // had it last (especially with several expanding text fields), so we resign 
	 // first responder.
	 
	 BOOL stolenEditor = NO;
	 NSWindow *myWindow = [self window];
	 NSTextView *fieldEditor = (NSTextView *)[myWindow fieldEditor: YES forObject: self];
	 BOOL isEditable = [self isEditable];
	 
	 if ([fieldEditor delegate] != (id)self) {
		 stolenEditor = YES;
		 
		 // self needs to be editable to accept first responder
		 if (![self isEditable]) {
			 [self setEditable:YES];
		 }
		 
		 [myWindow endEditingFor: nil];
		 [myWindow makeFirstResponder: self];	
		 
		 // Set cursor to end, breaking the selection
		 NSUInteger length = [[self stringValue] length];
		 [fieldEditor setSelectedRange:NSMakeRange(length, 0)];
	 }
	 
	 // get rect need to display all text
	 float newHeight = [[fieldEditor layoutManager] usedRectForTextContainer: [fieldEditor textContainer]].size.height + IFVerticalPadding;
	 
	 if (stolenEditor) {   
		 // Odd things can occur when messing with the first responder when using 
		 // several IFVerticallyExpandingTextFields.  Best not to mess with it, for now.
		 
		 [myWindow makeFirstResponder: nil];
	 }

	 [self setEditable:isEditable];

	 return newHeight;
}

/*
 
 set string value or empty on nil
 
 if a placeholder is defined then the placeholder will be
 displayed in place of an empty string
 
 */
- (void)setStringValueOrEmptyOnNil:(NSString *)aString
{
	if (!aString) {
		aString = @"";
	}
	[self setStringValue:aString];
}
@end
