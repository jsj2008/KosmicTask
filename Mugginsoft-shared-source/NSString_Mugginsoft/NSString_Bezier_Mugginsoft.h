//
//  NSString_Bezier_Mugginsoft.h
//  KosmicTask
//
//  Created by Jonathan on 05/12/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BezierNSLayoutManager: NSLayoutManager {
    NSBezierPath* theBezierPath;
}
- (void) dealloc;

- (NSBezierPath *)theBezierPath;
- (void)setTheBezierPath:(NSBezierPath *)value;

/* convert the NSString into a NSBezierPath using a specific font. */
- (void)showPackedGlyphs:(char *)glyphs length:(unsigned)glyphLen
			  glyphRange:(NSRange)glyphRange atPoint:(NSPoint)point font:(NSFont *)font
				   color:(NSColor *)color printingAdjustment:(NSSize)printingAdjustment;
@end


@interface NSString (BezierConversions)

/* convert the NSString into a NSBezierPath using a specific font. */
- (NSBezierPath*) bezierWithFont: (NSFont*) theFont;

@end

