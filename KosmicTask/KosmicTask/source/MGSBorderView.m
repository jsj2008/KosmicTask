//
//  MGSBorderView.m
//  KosmicTask
//
//  Created by Jonathan on 30/06/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSBorderView.h"


@implementation MGSBorderView

/*
 
 draw rect
 
 */
- (void)drawRect:(NSRect)rect {
	
	rect = [self bounds];
	rect.size.height--;
	
	NSGraphicsContext* gc = [NSGraphicsContext currentContext];
	
	[gc setShouldAntialias:NO];
	
	// border
	NSBezierPath *bgPath = [NSBezierPath bezierPathWithRect:rect];
	[[NSColor grayColor] set];
	[bgPath stroke];
	
}

@end
