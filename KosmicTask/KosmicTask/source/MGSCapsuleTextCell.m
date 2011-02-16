//
//  MGSCapsuleTextCell.m
//  Mother
//
//  Created by Jonathan on 21/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSCapsuleTextCell.h"
#import "MGSImageAndTextCell.h"

#define kMinCapsuleWidth 20

@implementation MGSCapsuleTextCell

@synthesize capsuleHasShadow = _capsuleHasShadow;
@synthesize sizeCapsuleToFit = _sizeCapsuleToFit;

/*
 
 init
 
 */
- (id)init
{
	if ((self = [super init])) {
		_capsuleHasShadow = NO;	
		_sizeCapsuleToFit = NO;
	}
	return self;
}
/*
 
 init with coder
 
 */
- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super initWithCoder:decoder];
	_capsuleHasShadow = NO;	
	_sizeCapsuleToFit = YES;
	return self;
}

// -------------------------------------------------------------------------------
//	drawWithFrame:inView:
// -------------------------------------------------------------------------------
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{		

	#pragma unused(controlView)
	
	NSString *stringValue = [self stringValue];
	
	// Use the current font point size as a guide for the count font size
	float pointSize = [[self font] pointSize];
	NSColor *fontColor = [self textColor];
	NSColor *capsuleColor = [self backgroundColor];

	// Create attributes for drawing the string.
	/*NSDictionary * attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont boldSystemFontOfSize:pointSize],
								 NSFontAttributeName,
								 fontColor,
								 NSForegroundColorAttributeName,
								 nil];*/
	NSDictionary * attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica-Bold" size:pointSize],
								 NSFontAttributeName,
								 fontColor,
								 NSForegroundColorAttributeName,
								 nil];
	NSSize stringSize = [stringValue sizeWithAttributes:attributes];
	
	// Compute the dimensions of the capsule rectangle.
	int cellWidth = cellFrame.size.width;
	if (_sizeCapsuleToFit) {
		cellWidth = MAX(stringSize.width + 6, stringSize.height + 1) + 1;
	}
	
	if (cellWidth < kMinCapsuleWidth) {
		cellWidth = kMinCapsuleWidth;
	}
	
	NSRect capsuleFrame;

	// frame centre x
	CGFloat centreX = cellFrame.origin.x + cellFrame.size.width/2;
	
	// align left or right
	NSTextAlignment alignment = [self alignment];
	if (alignment == NSRightTextAlignment) {
		NSDivideRect(cellFrame, &capsuleFrame, &cellFrame, cellWidth + 4, NSMaxXEdge);
	} else {
		NSDivideRect(cellFrame, &capsuleFrame, &cellFrame, cellWidth + 4, NSMinXEdge);
	}
	
	// align centre
	if ([self alignment] == NSCenterTextAlignment) {
		capsuleFrame.origin.x = centreX - capsuleFrame.size.width/2;
	}
	
	CGFloat heightDelta = capsuleFrame.size.height - stringSize.height - 2;
	capsuleFrame.size.height =  stringSize.height + 2;
	capsuleFrame.origin.y += heightDelta/2;
	
	if ([self drawsBackground])
	{
		[[self backgroundColor] set];
		NSRectFill(capsuleFrame);
	}
	
	
	// if the  capsule is not full size there is insufficient room to display it properly.
	// so don't.
	if (capsuleFrame.size.width >= kMinCapsuleWidth) {
		
		if (_capsuleHasShadow) {
			// prepare to receive shadow
			[[NSGraphicsContext currentContext] saveGraphicsState];
			
			// Create the shadow
			NSShadow* theShadow = [[NSShadow alloc] init];
			[theShadow setShadowOffset:NSMakeSize(0, -4)];
			[theShadow setShadowBlurRadius:4.0f];
			
			// Use a partially transparent color for shapes that overlap.
			[theShadow setShadowColor:[[NSColor blackColor]
									   colorWithAlphaComponent:0.3f]];
			
			[theShadow set];
		} else {
			// draw offset capsule
			NSBezierPath *offsetBp = [NSBezierPath bezierPathWithRoundedRect:capsuleFrame xRadius:stringSize.height / 2 yRadius:stringSize.height / 2];
			NSAffineTransform *transform = [NSAffineTransform transform];
			[transform translateXBy:0.0f yBy: 1.0f];
			[offsetBp transformUsingAffineTransform:transform];
			[fontColor set];
			[offsetBp fill];
		}
		
		// draw capsule
		NSBezierPath *bp = [NSBezierPath bezierPathWithRoundedRect:capsuleFrame xRadius:stringSize.height / 2 yRadius:stringSize.height / 2];
		[capsuleColor set];
		[bp fill];

		if (_capsuleHasShadow) {
			[[NSGraphicsContext currentContext] restoreGraphicsState];
		}
		
		// Draw the string in the rounded rectangle we just created.
		NSPoint point = NSMakePoint(NSMidX(capsuleFrame) - stringSize.width / 2.0f,  NSMidY(capsuleFrame) - stringSize.height / 2.0f );
		[stringValue drawAtPoint:point withAttributes:attributes];
		[attributes release];
	}

}
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	#pragma unused(cellFrame)
	#pragma unused(controlView)
	
}
 @end
