//
//  PlacardScrollView.m
//  Mother
//
//  Created by Jonathan on 17/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
/*
 NSScrollView subclass to insert a "placard" within the scrollbar area.
 Original Source: <http://cocoa.karelia.com/AppKit_Classes/PlacardScrollView__.m>
 (See copyright notice at <http://cocoa.karelia.com>)
 */
#import "PlacardScrollView.h"

/*"	A placard is a little display in the scroll bar area; 
 for instance what you see in TextEdit when you're in "Wrap to Page" view.  
 PlacardScrollView is used to place a small view to the left or right of a horizontal scrollbar in a scrollview. 
 Replace #NSScrollView with #PlacardScrollView and then hook up a view to the "placard" outlet.  (The view should be 16 pixels high.)
 "*/

@implementation PlacardScrollView

@synthesize leftPlacard = _leftPlacard, placardVisible = _placardVisible;

/*
 
 init
 
 */
- (id)initWithFrame:(NSRect)frameRect
{
	if ([super initWithFrame:frameRect]) {
		placard = nil;
		_leftPlacard = nil;
		_placardVisible = YES;
	}
	return self;
}

/*"	Release all the objects held by self, then call superclass.
 "*/

- (void) dealloc
{
	[placard release];
	[_leftPlacard release];
	[super dealloc];
}

/*"	Set the side (!{PlacardLeft} or !{PlacardRight}) that the placard will appear on.
 "*/

- (void) setSide:(int) inSide
{
	_side = inSide;
}

/*"	This setter puts it into the superview.  Therefore, if you hook it up from Interface Builder,
 the view will be installed automagically. "*/

- (void) setPlacard:(NSView *)inView
{
	[inView retain];
	if (nil != placard)
	{
		[placard removeFromSuperview];
		[placard release];
	}
	placard = inView;
	[self addSubview:placard];
}


- (void) setLeftPlacard:(NSView *)inView
{
	[inView retain];
	if (nil != _leftPlacard)
	{
		[_leftPlacard removeFromSuperview];
		[_leftPlacard release];
	}
	_leftPlacard = inView;
	[self addSubview:_leftPlacard];
}

/*"	Return the placard view
 "*/

- (NSView *) placard
{
	return placard;
}

/*"	Tile the view.  This invokes super to do most of its work, but then fits the placard into place.
 "*/

- (void)tile
{
	[super tile];
	[self tilePlacardView:placard side:_side];
	
	// tried and failed miserably to add two placards. could not get second view to display.
	//[self tilePlacardView:_leftPlacard side:PlacardLeft];
	
	/*
	if ((placard || _leftPlacard) && [self hasHorizontalScroller])
	{
		NSScroller *horizScroller;
		NSRect horizScrollerFrame, placardFrame, leftPlacardFrame;
		
		horizScroller = [self horizontalScroller];
		horizScrollerFrame = [horizScroller frame];

		// left placard
		if (_leftPlacard) {
			leftPlacardFrame = [_leftPlacard frame];

			// Put placard where the horizontal scroller is
			leftPlacardFrame.origin.x = NSMinX(horizScrollerFrame);

			// set scroller frame size and origin
			horizScrollerFrame.size.width -= leftPlacardFrame.size.width;
			horizScrollerFrame.origin.x = NSMaxX(leftPlacardFrame);
			
			// Adjust height of placard
			leftPlacardFrame.size.height = horizScrollerFrame.size.height + 1.0;
			leftPlacardFrame.origin.y = [self bounds].size.height - leftPlacardFrame.size.height + 1.0;
			
			// Move the placard into place
			[_leftPlacard setFrame:leftPlacardFrame];
			[_leftPlacard setNeedsDisplay:YES];
		}
		
		// right placard
		if (placard) {
			placardFrame = [placard frame];
			
			// set scroller size
			if (_side != PlacardRightCorner) {
				horizScrollerFrame.size.width -= placardFrame.size.width;
			}
			
			// Put placard to the right of the existing scroller frame
			placardFrame.origin.x = NSMaxX(horizScrollerFrame);

			// Adjust height of placard
			placardFrame.size.height = horizScrollerFrame.size.height + 1.0;
			placardFrame.origin.y = [self bounds].size.height - placardFrame.size.height + 1.0;

			// Move the placard into place
			[placard setFrame:placardFrame];

		}

		// Move horizontal scroller 
		//[horizScroller setFrameSize:horizScrollerFrame.size];
		//[horizScroller setFrameOrigin:horizScrollerFrame.origin];
		[horizScroller setFrame:horizScrollerFrame];
		
	}
	 */
}


- (void)tilePlacardView:(NSView *)view side:(NSInteger)side
{
	// horizontal scroller may get toggled on and off
	if (view && ![self hasHorizontalScroller]) {
		if ([view superview]) {
			[view removeFromSuperview];
		}
	} else if (view && [self hasHorizontalScroller]) {
		if (![view superview]) {
			[self addSubview:view];
		}
		
		NSScroller *horizScroller;
		NSRect horizScrollerFrame, placardFrame;
		
		horizScroller = [self horizontalScroller];
		horizScrollerFrame = [horizScroller frame];
		placardFrame = [view frame];
		
		// Now we'll just adjust the horizontal scroller size 
		switch (side) {
			case PlacardLeft:
			case PlacardRight:
				horizScrollerFrame.size.width -= placardFrame.size.width;
				[horizScroller setFrameSize:horizScrollerFrame.size];
				break;
				
			case PlacardRightCorner:
				horizScrollerFrame.size.width -= placardFrame.size.width;
				if ([self hasVerticalScroller]) {
					NSRect vertScrollerFrame = [[self horizontalScroller] frame];
					horizScrollerFrame.size.width += vertScrollerFrame.size.height;
				}
				[horizScroller setFrameSize:horizScrollerFrame.size];
				
		}
		
		// set the placard size and location.
		switch (side) {
			case PlacardLeft:
				
				// Put placard where the horizontal scroller is
				placardFrame.origin.x = NSMinX(horizScrollerFrame);
				
				// Move horizontal scroller over to the right of the placard
				horizScrollerFrame.origin.x = NSMaxX(placardFrame);
				[horizScroller setFrameOrigin:horizScrollerFrame.origin];
				break;
				
			case PlacardRight:	// on right
				
				// Put placard to the right of the new scroller frame
				placardFrame.origin.x = NSMaxX(horizScrollerFrame);
				break;
				
			case PlacardRightCorner:			
				
				// Put placard to the right of the existing scroller frame
				placardFrame.origin.x = NSMaxX(horizScrollerFrame);
				break;
		}
		
		// Adjust height of placard
		placardFrame.size.height = horizScrollerFrame.size.height + 1.0f;
		placardFrame.origin.y = [self bounds].size.height - placardFrame.size.height + 1.0f;
				
		// Move the placard into place
		[view setFrame:placardFrame];
	}
	
}

@end
