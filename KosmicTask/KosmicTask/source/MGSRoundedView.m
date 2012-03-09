//
//  MGSRoundedView.m
//  Mother
//
//  Created by Jonathan on 06/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSRoundedView.h"

void offsetPoint (NSPoint *point, CGFloat x, CGFloat y)
{
	point->x +=x;
	point->y +=y;
}

@implementation MGSRoundedView
@synthesize gradientType = _gradientType;
@synthesize showDragRect = _showDragRect;

// NSView override
- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		_gradientType = MGSViewGradientToolbar;
		_showDragRect = NO;
	}
	return self;
}

// NSView override
// setup/remove key window notifications
// CAUSED big problem.

// Not even necessary as it seems that when the window becomes/resigns key the views
// are redisplyed anyway
- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
	#pragma unused(newWindow)
	
	/*
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSWindowDidResignKeyNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowDidChangeKeyNotification:)
												 name:NSWindowDidResignKeyNotification object:newWindow];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSWindowDidBecomeKeyNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowDidChangeKeyNotification:)
												 name:NSWindowDidBecomeKeyNotification object:newWindow];
	 */
}

// NSView override
- (void)drawRect:(NSRect)aRect
{
	#pragma unused(aRect)
	
	BOOL isKeyWindow = [[self window] isKeyWindow];
	NSColor *dragColor = nil;

	NSGraphicsContext* gc = [NSGraphicsContext currentContext];
	[gc setShouldAntialias:YES];
	
	// ignore the rect arg and redraw entire control background
	// using aRect here was causing a morning wasting problem
	// though I did get to investigate subclassing NSButton, NSControl and NSButtonCell!
    NSRect bgRect = [self bounds];
	float radius = 15.0f; 
	
	
    int minX = NSMinX(bgRect);
    int midX = NSMidX(bgRect);
    int maxX = NSMaxX(bgRect);
    int minY = NSMinY(bgRect);
    int midY = NSMidY(bgRect);
    int maxY = NSMaxY(bgRect);

	//minX += 5;
	//maxX -= 5;
	
    NSBezierPath *bgPath = [NSBezierPath bezierPath];
    
    // Bottom edge and bottom-right curve
    [bgPath moveToPoint:NSMakePoint(midX, minY)];
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(maxX, minY) 
                                     toPoint:NSMakePoint(maxX, midY) 
                                      radius:radius];
    
    // Right edge and top-right curve
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(maxX, maxY) 
                                     toPoint:NSMakePoint(midX, maxY) 
                                      radius:radius];
    
    // Top edge and top-left curve
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(minX, maxY) 
                                     toPoint:NSMakePoint(minX, midY) 
                                      radius:radius];
    
    // Left edge and bottom-left curve
    [bgPath appendBezierPathWithArcFromPoint:bgRect.origin 
                                     toPoint:NSMakePoint(midX, minY) 
                                      radius:radius];
    [bgPath closePath];
 
	// this method new in Leopard
	//NSBezierPath *bgPath = [NSBezierPath bezierPathWithRoundedRect:bgRect xRadius:15 yRadius:15];
	
	// set gradient colours
	NSColor *start = nil, *end = nil;
	switch (_gradientType) {
		case MGSViewGradientToolbar:
			if (isKeyWindow) {
				// key toolbar grey
				//start = [NSColor colorWithCalibratedRed:0.773 green:0.773 blue:0.773 alpha:1.0];
				//end = [NSColor colorWithCalibratedRed:0.588 green:0.588 blue:0.588 alpha:1.0];
				// unkey selected row blue
				start = [NSColor colorWithCalibratedRed:0.635f green:0.694f blue:0.812f alpha:1.0f];
				end = [NSColor colorWithCalibratedRed:0.435f green:0.510f blue:0.663f alpha:1.0f];
			} else {
				// unkey toolbar grey
				//start = [NSColor colorWithCalibratedRed:0.945 green:0.945 blue:0.945 alpha:1.0];
				//end = [NSColor colorWithCalibratedRed:0.812 green:0.812 blue:0.812 alpha:1.0];
				// unkey selected row blue
				start = [NSColor colorWithCalibratedRed:0.706f green:0.706f blue:0.706f alpha:1.0f];
				end = [NSColor colorWithCalibratedRed:0.541f green:0.541f blue:0.541f alpha:1.0f];			
			}
			dragColor = [NSColor darkGrayColor];
			break;
		
		case MGSViewGradientTableView:
			if (isKeyWindow) {			
				// key selected row blue
				start = [NSColor colorWithCalibratedRed:0.357f green:0.573f blue:0.835f alpha:1.0f];
				end = [NSColor colorWithCalibratedRed:0.082f green:0.325f blue:0.667f alpha:1.0f];
			} else {
				// unkey selected row blue
				start = [NSColor colorWithCalibratedRed:0.706f green:0.706f blue:0.706f alpha:1.0f];
				end = [NSColor colorWithCalibratedRed:0.541f green:0.541f blue:0.541f alpha:1.0f];
			}
			dragColor = [NSColor lightGrayColor];
			break;
			
		default:
			NSAssert(nil, @"invalid gradient type");
			return;
	}
	
	NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:start endingColor:end];
	[gradient drawInBezierPath:bgPath angle:-90.0f];
	
	// draw border
	[end set];
	[bgPath stroke];
	
	// draw the corner drag in the splitview additional rect
	if (_showDragRect) {
		NSRect dragRect = [self splitViewRect];
		NSPoint *pOrigin = &(dragRect.origin);
		CGFloat width = dragRect.size.width;
		CGFloat height = dragRect.size.height;
		
		// draw drag rect background
		if (isKeyWindow) {
			bgPath = [NSBezierPath bezierPath];
			[bgPath moveToPoint:*pOrigin];
			[bgPath appendBezierPathWithArcFromPoint:NSMakePoint(pOrigin->x + width, pOrigin->y) 
											 toPoint:NSMakePoint(pOrigin->x + width, pOrigin->y + height) 
											  radius:radius];
			[bgPath lineToPoint:NSMakePoint(pOrigin->x, pOrigin->y + height)];
			[bgPath closePath];
			[gradient drawInBezierPath:bgPath angle:-90.0f];
		}

		bgPath = [NSBezierPath bezierPath];
		[dragColor set];
		[bgPath moveToPoint:*pOrigin];
		[bgPath lineToPoint:NSMakePoint(pOrigin->x, pOrigin->y + height)];
		[bgPath lineToPoint:NSMakePoint(pOrigin->x + width, pOrigin->y + height)];
		[bgPath stroke];
		
		[gc setShouldAntialias:NO];
		
		// draw the drag rect lines
		bgPath = [NSBezierPath bezierPath];
		NSPoint startPoint = NSMakePoint(pOrigin->x, pOrigin->y + height);
		NSPoint endPoint = NSMakePoint(pOrigin->x + width, pOrigin->y + height);

		offsetPoint(&endPoint, -2, 0);
		offsetPoint(&startPoint, 2, 0);
		
		[bgPath moveToPoint:startPoint];
		[bgPath lineToPoint:endPoint];
		
		offsetPoint(&startPoint, 0, -5);
		offsetPoint(&endPoint, 0, -5);
		
		[bgPath moveToPoint:startPoint];
		[bgPath lineToPoint:endPoint];

		offsetPoint(&startPoint, 0, -5);
		offsetPoint(&endPoint, -5, -5);

		[bgPath moveToPoint:startPoint];
		[bgPath lineToPoint:endPoint];
		
		[bgPath setLineWidth:0];
		[bgPath stroke];
	}

	
}	

// addtional dragging rect for splitview
- (NSRect)splitViewRect
{
	NSRect rect = [self bounds];
	rect.origin.x += (rect.size.width - 15);
	rect.size.height = 15;
	rect.size.width = 15;
	return rect;
}
@end

@implementation MGSRoundedView(Private)


// NSWindow notification
- (void)windowDidChangeKeyNotification:(NSNotification *)notification
{
	#pragma unused(notification)
	
//#pragma warning crash here if script scheduled to be saved, switch to xcode before save, clear log and crash!
	// crashing when open and close a large number of edit windows
	//[self setNeedsDisplay:YES];
}
@end
