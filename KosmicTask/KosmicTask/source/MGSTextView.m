//
//  MGSTextView.m
//  KosmicTask
//
//  Created by Jonathan on 21/10/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSTextView.h"


@implementation MGSTextView

@synthesize forcedTypingAttributes;




/*
 
 - initWithFrame:textContainer:
 
 */
- (id)initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer *)container
{
	self = [super initWithFrame:frameRect textContainer:container];
	if (self) {
		NSFont *consoleFont = [NSFont fontWithName:@"Menlo" size: 11];
		forcedTypingAttributes = [NSDictionary
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
	if (self.forcedTypingAttributes) {
		[self setTypingAttributes:self.forcedTypingAttributes];
	}
	
	return proposedSelRange;
}

@end
