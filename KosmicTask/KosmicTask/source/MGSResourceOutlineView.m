//
//  MGSResourceOutlineView.m
//  KosmicTask
//
//  Created by Jonathan on 02/09/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSResourceOutlineView.h"


@implementation MGSResourceOutlineView

/*
 
 drawRow:clipRect;
 
 */
- (void)drawRow:(NSInteger)row clipRect:(NSRect)clipRect
{
	NSInteger drawStyleForRow = 0;
	
	// ask delegate about drawRowStyle
	if (self.delegate && [self.delegate respondsToSelector:@selector(mgs_outlineView:drawStyleForRow:)]) {
		drawStyleForRow = [(id)self.delegate mgs_outlineView:self drawStyleForRow:row];
	} 

	// using this method we can draw the entire row backround and then let the cells draw over it
	if (drawStyleForRow > 0) {
				
		[NSGraphicsContext saveGraphicsState];
		[[NSGraphicsContext currentContext] setShouldAntialias:NO];
		
		NSRect rect = [self rectOfRow:row];

		// draw highlight line
		CGFloat x = rect.origin.x;
		CGFloat y = rect.origin.y;
		if ((drawStyleForRow & 0x02) > 0) {
			[[[NSColor blackColor] colorWithAlphaComponent:1 - 0.725f] set];
		} else {
			[[[NSColor whiteColor] colorWithAlphaComponent:1 - 0.725f] set];
		}
		NSBezierPath *path = [NSBezierPath bezierPath];
		[path moveToPoint:NSMakePoint(x,y)];
		[path lineToPoint:NSMakePoint(x + rect.size.width, y)];
        [path stroke];
		
		// draw gradient fill
		rect.origin.y += 1;
		rect.size.height -= 1;
		NSColor *startColor = [[NSColor blackColor] colorWithAlphaComponent:1 - 0.925f];
		NSColor *endColor = [[NSColor blackColor] colorWithAlphaComponent:1 - 0.851f];
		NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
		[gradient drawInRect:rect angle:90];
		
		
		// draw shadow line
		x = rect.origin.x;
		y = rect.origin.y + rect.size.height;
		[[[NSColor blackColor] colorWithAlphaComponent:1 - 0.725f] set];
		path = [NSBezierPath bezierPath];
		[path moveToPoint:NSMakePoint(x,y)];
		[path lineToPoint:NSMakePoint(x + rect.size.width, y)];
        [path stroke];
		
		[NSGraphicsContext restoreGraphicsState];
		
	} 
	
	[super drawRow:row clipRect:clipRect];
}
@end
