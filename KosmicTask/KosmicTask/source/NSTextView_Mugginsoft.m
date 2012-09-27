//
//  NSTextView_Mugginsoft.m
//  Mother
//
//  Created by Jonathan on 10/04/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "NSTextView_Mugginsoft.h"
#import "NSObject_Mugginsoft.h"

static char toggleKey;

@implementation NSTextView (Mugginsoft)

/*
 
 - mgs_addStringAndScrollToVisible:
 
 */
- (void)mgs_addStringAndScrollToVisible:(NSString *)string
{
	NSRange endRange;

	@try{
		
		endRange.location = [[self textStorage] length];
		endRange.length = 0;

		[self replaceCharactersInRange:endRange withString:string];
		endRange.length = [string length];
		
		// note that this method is very slow for large amounts of text
		[self scrollRangeToVisible:endRange];
		
	} @catch (NSException *e){
		NSLog(@"Exception scrolling NSTextView: %@", [e name]);
	}
}

/*
 
 - mgs_addString:
 
 */
- (void)mgs_addString:(NSString *)string
{
	NSRange endRange;

	@try{
		
		endRange.location = [[self textStorage] length];
		endRange.length = 0;
		
		[self replaceCharactersInRange:endRange withString:string];
		endRange.length = [string length];
		
	} @catch (NSException *e){
		NSLog(@"Exception scrolling NSTextView: %@", [e name]);
	}
}

/*
 
 - mgs_setLineWrap:
 
 see /developer/examples/appkit/TextSizingExample
 
 */
- (void)mgs_setLineWrap:(BOOL)wrap
{
    // get control properties
	NSScrollView *textScrollView = [self enclosingScrollView];
	NSTextContainer *textContainer = [self textContainer];
    
    // content view is clipview
	NSSize contentSize = [textScrollView contentSize];
    
    if (wrap) {
        
        // setup text container
        [textContainer setContainerSize:NSMakeSize(contentSize.width, CGFLOAT_MAX)];
        [textContainer setWidthTracksTextView:YES];
        [textContainer setHeightTracksTextView:NO];
        
        // setup text view
        [self setFrameSize:contentSize];
        [self setHorizontallyResizable: NO];
        [self setVerticallyResizable: YES];
        [self setMinSize:NSMakeSize(10, contentSize.height)];
        [self setMaxSize:NSMakeSize(10, CGFLOAT_MAX)];
        
        // setup scroll view
        [textScrollView setHasHorizontalScroller:NO];
        [textScrollView setHasVerticalScroller:YES];
    } else {
        
        // setup text container
        [textContainer setContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
        [textContainer setWidthTracksTextView:NO];
        [textContainer setHeightTracksTextView:NO];
        
        // setup text view
        [self setFrameSize:contentSize];
        [self setHorizontallyResizable: YES];
        [self setVerticallyResizable: YES];
        [self setMinSize:contentSize];
        [self setMaxSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
        
        // setup scroll view
        [textScrollView setHasHorizontalScroller:YES];
        [textScrollView setHasVerticalScroller:YES];
    }
    
    
    // invalidate the glyph layout
	[[self layoutManager] textContainerChangedGeometry:textContainer];
    
    // redraw the display and reposition scrollers
    [textScrollView display];
    [textScrollView reflectScrolledClipView:textScrollView.contentView];
	
	// associate toggle status - saves having to subclass
	[self mgs_associateValue:[NSNumber numberWithBool:wrap] withKey:&toggleKey];
}

/*
 
 - mgs_toggleLineWrapping
 
 */
- (IBAction)mgs_toggleLineWrapping:(id)sender
{
#pragma unused(sender)
	NSNumber *wrap = [self mgs_associatedValueForKey:&toggleKey];
	if (wrap) {
		[self mgs_setLineWrap:![wrap boolValue]];
	}
}

/*
 
 - mgs_increaseFontSize:
 
 see http://stackoverflow.com/questions/2245308/how-to-change-only-font-size-for-the-whole-styled-text-in-nstextview
 
 */
- (IBAction)mgs_increaseFontSize:(id)sender
{
#pragma unused(sender)
	NSTextStorage *textStorage = [self textStorage];
	[textStorage beginEditing];
	[textStorage enumerateAttributesInRange: NSMakeRange(0, [textStorage length])
									 options: 0
								  usingBlock: ^(NSDictionary *attributesDictionary,
												NSRange range,
												BOOL *stop)
	 {
#pragma unused(stop)
		 NSFont *font = [attributesDictionary objectForKey:NSFontAttributeName];
		 if (font) {
			 [textStorage removeAttribute:NSFontAttributeName range:range];
			 font = [[NSFontManager sharedFontManager] convertFont:font toSize:[font pointSize] + 2];
			 [textStorage addAttribute:NSFontAttributeName value:font range:range];
		 }
	 }];
	[textStorage endEditing];
	[self didChangeText];

}

/*
 
 - mgs_decreaseFontSize:
 
 */
- (IBAction)mgs_decreaseFontSize:(id)sender
{
	#pragma unused(sender)
	
	NSTextStorage *textStorage = [self textStorage];
	[textStorage beginEditing];
	[textStorage enumerateAttributesInRange: NSMakeRange(0, [textStorage length])
									options: 0
								 usingBlock: ^(NSDictionary *attributesDictionary,
											   NSRange range,
											   BOOL *stop)
	 {
#pragma unused(stop)
		 NSFont *font = [attributesDictionary objectForKey:NSFontAttributeName];
		 if (font) {
			 CGFloat pointSize = [font pointSize] - 2;
			 if (pointSize > 6) {
				 [textStorage removeAttribute:NSFontAttributeName range:range];
				 font = [[NSFontManager sharedFontManager] convertFont:font toSize:pointSize];
				 [textStorage addAttribute:NSFontAttributeName value:font range:range];
			 }
		 }
	 }];
	[textStorage endEditing];
	[self didChangeText];
	
}

- (void)changeFont:(NSFont *)plainFont
{
    NSFont *boldFont = [[NSFontManager sharedFontManager] convertFont:plainFont toHaveTrait:NSBoldFontMask];
    NSTextStorage * textStorage = [self textStorage];
    [textStorage beginEditing];
    [textStorage enumerateAttribute:NSFontAttributeName
                            inRange:NSMakeRange(0, [textStorage length])
                            options:0
                         usingBlock:^(id value,
                                      NSRange range,
                                      BOOL * stop)
        {
            #pragma unused(stop)
            #pragma unused(value)

            NSFont *newFont = plainFont;
            NSFont *font = value;
            if ([[NSFontManager sharedFontManager] traitsOfFont:font] & NSBoldFontMask) {
                newFont = boldFont;
            }
            [textStorage removeAttribute:NSFontAttributeName
                        range:range];
            [textStorage addAttribute:NSFontAttributeName
                     value:newFont
                     range:range];
        }
    ];
    [textStorage endEditing];
    [self didChangeText];
}

@end
