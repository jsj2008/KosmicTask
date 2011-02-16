//
//  NSString_Bezier_Mugginsoft.m
//  KosmicTask
//
//  Created by Jonathan on 05/12/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import "NSString_Bezier_Mugginsoft.h"
#import "NSAffineTransform_Mugginsoft.h"

/*
 
 from 
 http://developer.apple.com/mac/library/samplecode/WebKitPluginStarter/listing7.html
 
 */
@implementation BezierNSLayoutManager

- (void) dealloc {
    [self setTheBezierPath: nil];
    [super dealloc];
}

- (NSBezierPath *)theBezierPath {
    return [[theBezierPath retain] autorelease];
}

- (void)setTheBezierPath:(NSBezierPath *)value {
    if (theBezierPath != value) {
        [theBezierPath release];
        theBezierPath = [value retain];
    }
}

/* convert the NSString into a NSBezierPath using a specific font. */
- (void)showPackedGlyphs:(char *)glyphs length:(unsigned)glyphLen
			  glyphRange:(NSRange)glyphRange atPoint:(NSPoint)point font:(NSFont *)font
				   color:(NSColor *)color printingAdjustment:(NSSize)printingAdjustment {
    
	#pragma unused(glyphLen)
	#pragma unused(glyphRange)
	#pragma unused(font)
	#pragma unused(color)
	#pragma unused(printingAdjustment)

	/* if there is a NSBezierPath associated with this
	 layout, then append the glyphs to it. */
    NSBezierPath *bezier = [self theBezierPath];
    
    if ( nil != bezier ) {
		
		/* add the glyphs to the bezier path */
        [bezier moveToPoint:point];
        [bezier appendBezierPathWithPackedGlyphs: glyphs];
		
    }
}

@end

/*
 
 from 
 http://developer.apple.com/mac/library/samplecode/WebKitPluginStarter/listing7.html
 
 */
@implementation NSString (BezierConversions)

- (NSBezierPath*) bezierWithFont: (NSFont*) theFont {
    NSBezierPath *bezier = nil; /* default result */
    
	/* put the string's text into a text storage
	 so we can access the glyphs through a layout. */
    NSTextStorage *textStore = [[NSTextStorage alloc] initWithString: self];
    NSTextContainer *textContainer = [[NSTextContainer alloc] init];
    BezierNSLayoutManager *myLayout = [[BezierNSLayoutManager alloc] init];
    [myLayout addTextContainer: textContainer];
    [textStore addLayoutManager: myLayout];
    [textStore setFont: theFont];
    
	/* create a new NSBezierPath and add it to the custom layout */
    [myLayout setTheBezierPath: [NSBezierPath bezierPath]];
    
	/* to call drawGlyphsForGlyphRange, we need a destination so we'll
	 set up a temporary one.  Size is unimportant and can be small.  */
    NSImage* theImage = [[NSImage alloc] initWithSize: NSMakeSize(10, 10)];
	/* lines are drawn in reverse order, so we will draw the text upside down
	 and then flip the resulting NSBezierPath right side up again to achieve
	 our final result with the lines in the right order and the text with
	 proper orientation.  */
    [theImage setFlipped:YES];
    [theImage lockFocus];
    
	/* draw all of the glyphs to collecting them into a bezier path
	 using our custom layout class. */
    NSRange glyphRange = [myLayout glyphRangeForTextContainer:textContainer];
    [myLayout drawGlyphsForGlyphRange:glyphRange atPoint: NSMakePoint(0, 0)];
    
	/* clean up our temporary drawing environment */
    [theImage unlockFocus];
    [theImage release];
    
	/* retrieve the glyphs from our BezierNSLayoutManager instance */
    bezier = [myLayout theBezierPath];
    
	/* clean up our text storage objects */
    [textStore release];
    [textContainer release];
    [myLayout release];
    
	/* Flip the final NSBezierPath. */
    [bezier transformUsingAffineTransform: 
	[[NSAffineTransform transform] flipVertical: [bezier bounds]]];
    
	/* return the new bezier path */
    return bezier;
}

@end

