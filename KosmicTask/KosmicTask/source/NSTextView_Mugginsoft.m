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

- (void)addStringAndScrollToVisible:(NSString *)string
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

- (void)addString:(NSString *)string
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
 
 see /developer/examples/appkit/TextSizingExample
 
 */
- (void)setLineWrap:(BOOL)wrap
{
    // get control properties
	NSScrollView *textScrollView = [self enclosingScrollView];
	NSTextContainer *textContainer = [self textContainer];

    // content view is clipview
	NSSize contentSize = [textScrollView contentSize];  
    
    // define wrap properties
    BOOL hasHorizontalScroller = YES;
    NSSize containerSize = NSMakeSize(contentSize.width, CGFLOAT_MAX);
    BOOL widthTracksTextView = YES;
	NSSize maxSize =  containerSize; // NSMakeSize([self frame].size.width, CGFLOAT_MAX);
	NSSize minSize =  containerSize;
    BOOL horizontallyResizable = NO;
    
    // define non wrap properties
	if (!wrap) {
        containerSize = NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX);
        widthTracksTextView = NO;
        maxSize =  containerSize;
        minSize = contentSize;
        horizontallyResizable = YES;
	}

    NSLog(@"Container size: %@", NSStringFromSize(containerSize));
    NSLog(@"Max size: %@", NSStringFromSize(maxSize));
    NSLog(@"Min size: %@", NSStringFromSize(minSize));
    
    // assign wrap properties
    [self setMinSize:contentSize];
    [textScrollView setHasHorizontalScroller:hasHorizontalScroller];
    [textContainer setContainerSize:containerSize];
    [textContainer setWidthTracksTextView:widthTracksTextView];
    [self setMaxSize:maxSize];
    [self setHorizontallyResizable: horizontallyResizable];

    // invalidate the glyph layout
	[[self layoutManager] textContainerChangedGeometry:textContainer];
	
	// associate toggle status - saves having to subclass
	[self mgs_associateValue:[NSNumber numberWithBool:wrap] withKey:&toggleKey];
}

/*
 
 - toggleLineWrapping
 
 */
- (IBAction)toggleLineWrapping:(id)sender
{
#pragma unused(sender)
	NSNumber *wrap = [self mgs_associatedValueForKey:&toggleKey];
	if (wrap) {
		[self setLineWrap:![wrap boolValue]];
	}
}

/*
 
 - increaseFontSize:
 
 see http://stackoverflow.com/questions/2245308/how-to-change-only-font-size-for-the-whole-styled-text-in-nstextview
 
 */
- (IBAction)increaseFontSize:(id)sender
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
 
 - decreaseFontSize:
 
 */
- (IBAction)decreaseFontSize:(id)sender
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
@end
