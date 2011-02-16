//
//  MGSScriptEditSplitView.m
//  KosmicTask
//
//  Created by Jonathan on 17/08/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSScriptEditSplitView.h"


@implementation MGSScriptEditSplitView

/*
 
 - dividerThickness
 
 */
- (CGFloat)dividerThickness
{
	return 0;
}

/*
 
 - drawDividerInRect:
 
 */
/*
- (void)drawDividerInRect:(NSRect)aRect
{
	NSGraphicsContext* gc = [NSGraphicsContext currentContext];
	[gc setShouldAntialias:NO];
	
	NSBezierPath *bgPath = [NSBezierPath bezierPath];
	[bgPath moveToPoint:aRect.origin];
	[bgPath lineToPoint:NSMakePoint(aRect.origin.x, aRect.origin.y + aRect.size.height)];
	NSColor*color = [NSColor colorWithCalibratedRed:0.25f green:0.251f blue:0.251f alpha:1.0f];
	[color set];
	[bgPath stroke];
}
*/

@end
