//
//  MGSWindowSplitView.m
//  Mother
//
//  Created by Jonathan on 14/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSWindowSplitView.h"
#import "NSBezierPath_Mugginsoft.h"

@implementation MGSWindowSplitView

- (CGFloat)dividerThickness
{
	return 1;
}

- (void)drawDividerInRect:(NSRect)aRect
{
	if (![self isVertical]) return;
	
	NSGraphicsContext* gc = [NSGraphicsContext currentContext];
	
	// YES this view is flipped!
	//BOOL isFlipped = [self isFlipped];
	
	[gc setShouldAntialias:NO];
	NSColor *dividerColor = [NSColor colorWithCalibratedRed:0.333f green:0.333f blue:0.333f alpha:1.0f];
	
	CGFloat height = aRect.size.height;

	NSBezierPath *bgPath = [NSBezierPath bezierPathLineFrom:NSMakePoint(aRect.origin.x, aRect.origin.y) to: NSMakePoint(aRect.origin.x, aRect.origin.y + height)];
	[dividerColor set];
	[bgPath stroke];
}

@end
