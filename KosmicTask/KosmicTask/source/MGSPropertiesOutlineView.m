//
//  MGSPropertiesOutlineView.m
//  KosmicTask
//
//  Created by Jonathan on 02/09/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSPropertiesOutlineView.h"


@implementation MGSPropertiesOutlineView

/*
 
 drawRow:clipRect;

 see http://www.corbinstreehouse.com/blog/archives/cocoa/

 */
- (void)drawRow:(int)row clipRect:(NSRect)clipRect 
{

	NSInteger drawStyleForRow = 0;
	
	// ask delegate about drawRowStyle
	if (self.delegate && [self.delegate respondsToSelector:@selector(mgs_outlineView:drawStyleForRow:)]) {
		drawStyleForRow = [(id)self.delegate mgs_outlineView:self drawStyleForRow:row];
	} 
	
	NSRect rect = NSZeroRect;
	
	// using this method we can draw the entire row backround and then let the cells draw over it
	switch (drawStyleForRow) {
		case 0:
			break;
		
			// gradient fill row
		case 1:
		
			[NSGraphicsContext saveGraphicsState];
					
			rect = [self rectOfRow:row];

			// draw gradient fill
			rect.origin.y += 1;
			rect.size.height -= 1;
			NSColor *startColor = [[NSColor blackColor] colorWithAlphaComponent:1 - 0.925f];
			NSColor *endColor = [[NSColor blackColor] colorWithAlphaComponent:1 - 0.851f];
			NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
			[gradient drawInRect:rect angle:90];
			
			[[NSGraphicsContext currentContext] setShouldAntialias:NO];

			// draw shadow line
			CGFloat x = rect.origin.x;
			CGFloat y = rect.origin.y + rect.size.height;
			[[[NSColor blackColor] colorWithAlphaComponent:1 - 0.725f] set];
			NSBezierPath *path = [NSBezierPath bezierPath];
			[path moveToPoint:NSMakePoint(x,y)];
			[path lineToPoint:NSMakePoint(x + rect.size.width, y)];
			[path stroke];
			
			[NSGraphicsContext restoreGraphicsState];
			break;
			
			// fill row
		case 2:;
			rect = [self rectOfRow:row];
		
			[[NSColor colorWithDeviceRed:0.0f green: 0.0f blue: 0.0f alpha: 0.05f] set];
			[NSBezierPath fillRect: rect];
			break;

			// fill first column
		case 3:;
			rect = [self rectOfRow:row];
			NSInteger columnIndex = [self columnAtPoint:rect.origin]; 
			if (columnIndex != -1) {
				rect.size.width = [[[self tableColumns] objectAtIndex:columnIndex] width] + 1;
			}
			[[NSColor colorWithDeviceRed:0.0f green: 0.0f blue: 0.0f alpha: 0.05f] set];
			[NSBezierPath fillRect: rect];
			break;
			
		default:
			NSAssert(NO, @"invalid switch value");
	}
	
	[super drawRow:row clipRect:clipRect];
}

@end
