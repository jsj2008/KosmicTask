//
//  MGSGradientView.m
//  Mother
//
//  Created by Jonathan on 06/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSGradientView.h"
#import "NSBezierPath_Mugginsoft.h"

@implementation MGSGradientView

@synthesize hasBottomBorder = _hasBottomBorder, hasTopBorder = _hasTopBorder, startColor = _startColor, endColor = _endColor;

/*
 
 end color
 
 */
+ (NSColor *)endColor
{
	return [NSColor colorWithCalibratedRed:0.988f green:0.988f blue:0.988f alpha:1.0f];
}

/*
 
 start color
 
 */
+ (NSColor *)startColor
{
	return [NSColor colorWithCalibratedRed:0.875f green:0.875f blue:0.875f alpha:1.0f];;
}

/*
 
 init with frame
 
 */
- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		_hasTopBorder = YES;
		_hasBottomBorder = YES;
		_startColor = [[self class] startColor];
		_endColor = [[self class] endColor];
    }
    return self;
}

/*
 
 init with coder
 
 */

- (id)initWithCoder:(NSCoder *)aCoder
{
	self = [super initWithCoder:aCoder];
	//[self initialise];
	return self;
}

/*
 
 draw rect
 
 */
- (void)drawRect:(NSRect)rect {
	
	rect = [self bounds];
	
	NSGraphicsContext* gc = [NSGraphicsContext currentContext];
	
	// YES this view is flipped!
	//BOOL isFlipped = [self isFlipped];
	[gc setShouldAntialias:NO];
	
	// gradient
	NSBezierPath *bgPath = [NSBezierPath bezierPathWithRect:rect];
	NSColor *endColor = self.endColor;
	NSColor *startColor = self.startColor;
	
	NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
	[gradient drawInBezierPath:bgPath angle:90.0f];
	
	
	// top and bottom lines
	NSColor *topColor = [NSColor colorWithCalibratedRed:0.647f green:0.647f blue:0.647f alpha:1.0f];
	NSColor *bottomColor = [NSColor colorWithCalibratedRed:0.333f green:0.333f blue:0.333f alpha:1.0f];
	
	CGFloat width = rect.size.width;
	CGFloat height = rect.size.height;
	
	// draw top border
	if (_hasTopBorder) {
		bgPath = [NSBezierPath bezierPathLineFrom:NSMakePoint(rect.origin.x, rect.origin.y) to: NSMakePoint(rect.origin.x + width, rect.origin.y)];
		[topColor set];		
		[bgPath stroke];
	}
	
	// draw bottom border
	if (_hasBottomBorder) {
		bgPath = [NSBezierPath bezierPathLineFrom:NSMakePoint(rect.origin.x, rect.origin.y + height) to: NSMakePoint(rect.origin.x + width, rect.origin.y + height)];
		[bottomColor set];
		[bgPath stroke];
	}
}

@end
