//
//  MGSLevelIndicatorCell.m
//  Mother
//
//  Created by Jonathan on 17/09/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSLevelIndicatorCell.h"


@implementation MGSLevelIndicatorCell

/*
 
 init with coder
 
 */
- (id)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super initWithCoder:decoder])) {
	}
	return self;
}

/*
 
 draw with frame in view
 
 */
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{	
	// draw the value the right of the cell.
	if (YES) {
		/*
		[self setHighlighted:NO];
		NSRect outerFrame = cellFrame;
		outerFrame.origin.x -= 1;
		//outerFrame.origin.y -= 1;
		//outerFrame.size.height += 2;
		outerFrame.size.width += 2;
		
		[[NSColor whiteColor] set];
		NSRectFill(outerFrame);
		*/
		
		// if max and min values equal then draw nothing
		if ((NSInteger)[self maxValue] == (NSInteger)[self minValue]) {
			return;
		}
		
		// get our value
		NSString *number = [NSString stringWithFormat:@"%i%%", [self intValue]];
		
		// layout must accomodate max value
		NSString *maxNumber = [NSString stringWithFormat:@"%i%%", (int)[self maxValue]];
		
		// flip font and capsule colors when highlighted
		NSColor *fontColor = nil;
		NSFont *font = nil;
		if ([self isHighlighted]) {
			fontColor = [NSColor whiteColor];
			font = [NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]];
		} else {
			fontColor = [NSColor blackColor];
			font = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
		}
		
		// Create attributes for drawing the count.
		//for mini system font: [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize: NSMiniControlSize]]
		NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:font,
									 NSFontAttributeName,
									 fontColor,
									 NSForegroundColorAttributeName,
									 nil];
		NSSize numSize = [maxNumber sizeWithAttributes:attributes];
		
		// Compute the dimensions of the value rectangle.
		int cellWidth = MAX(numSize.width + 3, numSize.height + 1) + 1;
		
		NSRect valueFrame;
		
		// align value on right
		NSDivideRect(cellFrame, &valueFrame, &cellFrame, cellWidth + 4, NSMaxXEdge);
		valueFrame.origin.y += 2;	// Mail.app has similar clearances to these
		valueFrame.size.height -= 6;
		valueFrame.size.width -= 4;	// clearance on right of capsule
		
		// if the value is not full size there is insufficient room to display it properly.
		// so don't.
		if (valueFrame.size.width >= 20) {
			
			// Draw the value in the frame
			NSPoint point = NSMakePoint(NSMidX(valueFrame) - numSize.width / 2.0f,  NSMidY(valueFrame) - numSize.height / 2.0f );
			[number drawAtPoint:point withAttributes:attributes];
		}

		// create frame to draw level indicator in
		NSRect newFrame = cellFrame;
		//newFrame.origin.x += kTextOriginXOffset;
		newFrame.origin.y += 1;
		newFrame.size.height -= 6;
		
		// let the super class do its bit and draw the cell 
		[super drawWithFrame:newFrame inView:controlView];		
		
	}
		
}

@end
