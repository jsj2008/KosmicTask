//
//  MGSMotherWindowSplitview.m
//  Mother
//
//  Created by Jonathan on 13/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSMainSplitview.h"
#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CoreImage.h>
#import "NSBezierPath_Mugginsoft.h"
#import "NSSplitView_Mugginsoft.h"
#import "NSView_Mugginsoft.h"

@interface MGSMainSplitview(Private)

@end

@implementation MGSMainSplitview

- (id)initWithFrame:(NSRect)newFrame {
    self = [super initWithFrame:newFrame];
    if (self) {
        //[self updateSubviewsTransition]; 
		// setting the layer here doesn't work
		// [self setWantsLayer:YES];
    }
    return self;
}

// create the core animation transition dictionary for this view
// this will have no effect until the view calls - setWantsLayer:YES.
// the transition runs in its own thread.
- (void)updateSubviewsTransition {
	_transition = [CATransition animation];
	[_transition setDelegate:self];
	[_transition setType:kCATransitionFade];
	[_transition setSubtype:kCATransitionFromLeft];
	[_transition setDuration:1.0];
	[self setAnimations:[NSDictionary dictionaryWithObject:_transition forKey:@"subviews"]];
}

- (void)replaceTopView:(NSView *)newView
{
	[self replaceSubview:[[self subviews] objectAtIndex:0] withViewSizedAsOld:newView];
} 

- (void)replaceMiddleView:(NSView *)newView
{
	[self replaceSubview:[[self subviews] objectAtIndex:1] withViewSizedAsOld:newView];
}

- (void)replaceBottomView:(NSView *)newView
{
	[self replaceSubview:[[self subviews] objectAtIndex:2] withViewSizedAsOld:newView];
}

- (void)replaceSubview:(NSView *)view with:(NSView *)newView
{
	if (_transition) {
		[[self animator] replaceSubview:view with:newView];
	} else {
		[super replaceSubview:view with:newView];
	}
}

- (CGFloat)dividerThickness
{
	return 9;
}

- (void)drawDividerInRect:(NSRect)aRect
{
	if ([self isVertical]) return;
	
	NSGraphicsContext* gc = [NSGraphicsContext currentContext];
	
	// YES this view is flipped!
	//BOOL isFlipped = [self isFlipped];
	
	[gc setShouldAntialias:NO];
	
	// gradient
	NSBezierPath *bgPath = [NSBezierPath bezierPathWithRect:aRect];
	NSColor *startColor = [NSColor colorWithCalibratedRed:0.988f green:0.988f blue:0.988f alpha:1.0f];
	NSColor *endColor = [NSColor colorWithCalibratedRed:0.875f green:0.875f blue:0.875f alpha:1.0f];
	
	NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
	[gradient drawInBezierPath:bgPath angle:90.0f];

	// top and bottom lines
	NSColor *topColor = [NSColor colorWithCalibratedRed:0.647f green:0.647f blue:0.647f alpha:1.0f];
	NSColor *bottomColor = [NSColor colorWithCalibratedRed:0.333f green:0.333f blue:0.333f alpha:1.0f];
	
	CGFloat width = aRect.size.width;
	CGFloat height = aRect.size.height;
	
	// offset by 1 otherwise gets obliterated from above
	bgPath = [NSBezierPath bezierPathLineFrom:NSMakePoint(aRect.origin.x, aRect.origin.y+1) to: NSMakePoint(aRect.origin.x + width, aRect.origin.y+1)];
	[topColor set];		
	[bgPath stroke];
 
	bgPath = [NSBezierPath bezierPathLineFrom:NSMakePoint(aRect.origin.x, aRect.origin.y + height) to: NSMakePoint(aRect.origin.x + width, aRect.origin.y + height)];
	[bottomColor set];
	[bgPath stroke];
	
	// let super draw circle icon
	[super drawDividerInRect:aRect];
}

// CATransition delegate
- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
	#pragma unused(theAnimation)
	#pragma unused(flag)
	
	if ([self wantsLayer]) {
		[self setWantsLayer:NO];	// maybe better to set animation dict nil instead?
	}
}

// CATransition delegate
- (void)animationDidStart:(CAAnimation *)theAnimation
{
	#pragma unused(theAnimation)
}
@end

@implementation MGSMainSplitview(Private)


/*
- (void)startLayerTimer
{
	if ([self wantsLayer]) {
		_layerTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(layerTimerExpired:) userInfo:nil repeats:YES];
		MLog(DEBUGLOG, (@"startLayerTimer");
	}
}

- (void)layerTimerExpired:(NSTimer *)theTimer
{
	//if ([_transition endProgress] == 1.0) {
		MLog(DEBUGLOG, (@"layerTimerExpired");
		[self setWantsLayer:NO];
		[_layerTimer invalidate];
		_layerTimer = nil;
	//}
}
*/
@end

