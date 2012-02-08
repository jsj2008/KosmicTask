//
//  MGSTextView.m
//  KosmicTask
//
//  Created by Jonathan on 21/10/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSTextView.h"


@implementation MGSTextView

@synthesize consoleAttributes;




/*
 
 - initWithFrame:textContainer:
 
 */
- (id)initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer *)container
{
	self = [super initWithFrame:frameRect textContainer:container];
	if (self) {
		NSFont *consoleFont = [NSFont fontWithName:@"Menlo" size: 11];
		consoleAttributes = [NSDictionary
							 dictionaryWithObjectsAndKeys:
							 [NSColor blackColor], NSForegroundColorAttributeName,
							 consoleFont, NSFontAttributeName, nil];
	}
	return self;
}

/*
 
 - selectionRangeForProposedRange:granularity:
 
 */
- (NSRange)selectionRangeForProposedRange:(NSRange)proposedSelRange granularity:(NSSelectionGranularity)granularity 
{
	
#pragma unused(granularity)
	
	// impose a default font
	
	// Set typing attributes every time the cursor is moved.
	if (self.consoleAttributes) {
		[self setTypingAttributes:self.consoleAttributes];
	}
	
	return proposedSelRange;
}

/*
 
 - setText:append:options:
 
 */
- (void)setText:(NSString *)text append:(BOOL)append options:(NSDictionary *)options
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:consoleAttributes];
	
    float scrollPosition = [[[self enclosingScrollView] verticalScroller] floatValue];
    
	// process options
	if (options) {
		
		// combine text attributes with attributes
		NSDictionary *optionAttributes = [options objectForKey:@"attributes"];
		if (optionAttributes) {
			[attributes addEntriesFromDictionary:optionAttributes];
		}
	}
	
	NSAttributedString *attrMesg = [[NSAttributedString alloc] initWithString:text attributes:attributes];
	NSTextStorage *textStorage = [self textStorage];
	
	NSRange endRange;
	endRange.location = [[self textStorage] length];
    endRange.length = 0;
    
	[textStorage beginEditing];
	if (append) {
		[textStorage appendAttributedString:attrMesg];
	} else {
		[textStorage replaceCharactersInRange:NSMakeRange(0, [[self textStorage] length]) withAttributedString:attrMesg];
	}
	[textStorage endEditing];
    
    // if was scrolled to end before text was updated then scroll to end 
    if (scrollPosition == 1.0f) {
        endRange.length = [text length];
        [self scrollRangeToVisible:endRange];
        [[[self enclosingScrollView] verticalScroller] setFloatValue:1.0];
    }
}


@end
