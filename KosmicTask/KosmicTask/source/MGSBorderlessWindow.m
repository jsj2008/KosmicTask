//
//  MGSBorderlessWindow.m
//  Mother
//
//  Created by Jonathan on 27/04/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
// adapted from:
//  TransparentWindow.m
//  RoundedFloatingPanel
//
//  Created by Matt Gemmell on Thu Jan 08 2004.
//  <http://iratescotsman.com/>
////

#import "MGSBorderlessWindow.h"


@implementation MGSBorderlessWindow

- (id)initWithContentRect:(NSRect)contentRect 
                styleMask:(unsigned int)aStyle 
                  backing:(NSBackingStoreType)bufferingType 
                    defer:(BOOL)flag {
    
	#pragma unused(bufferingType)
	#pragma unused(aStyle)
	#pragma unused(flag)
	
    if ((self = [super initWithContentRect:contentRect 
								styleMask:NSBorderlessWindowMask 
								  backing:NSBackingStoreBuffered 
									defer:NO])) {
        [self setLevel: NSStatusWindowLevel];
        //[self setBackgroundColor: [NSColor clearColor]];
        [self setAlphaValue:1.0f];
        //[self setOpaque:NO];
        [self setHasShadow:NO];
        
        return self;
    }
    
    return nil;
}


- (BOOL) canBecomeKeyWindow
{
    return YES;
}


- (void)mouseDragged:(NSEvent *)theEvent
{
	#pragma unused(theEvent)
	
    NSPoint currentLocation;
    NSPoint newOrigin;
    NSRect  screenFrame = [[NSScreen mainScreen] frame];
    NSRect  windowFrame = [self frame];
    
    currentLocation = [self convertBaseToScreen:[self mouseLocationOutsideOfEventStream]];
    newOrigin.x = currentLocation.x - initialLocation.x;
    newOrigin.y = currentLocation.y - initialLocation.y;
    
    if( (newOrigin.y + windowFrame.size.height) > (NSMaxY(screenFrame) - [NSMenuView menuBarHeight]) ){
        // Prevent dragging into the menu bar area
		newOrigin.y = NSMaxY(screenFrame) - windowFrame.size.height - [NSMenuView menuBarHeight];
    }
    /*
	 if (newOrigin.y < NSMinY(screenFrame)) {
	 // Prevent dragging off bottom of screen
	 newOrigin.y = NSMinY(screenFrame);
	 }
	 if (newOrigin.x < NSMinX(screenFrame)) {
	 // Prevent dragging off left of screen
	 newOrigin.x = NSMinX(screenFrame);
	 }
	 if (newOrigin.x > NSMaxX(screenFrame) - windowFrame.size.width) {
	 // Prevent dragging off right of screen
	 newOrigin.x = NSMaxX(screenFrame) - windowFrame.size.width;
	 }
	 */
    
    [self setFrameOrigin:newOrigin];
}


- (void)mouseDown:(NSEvent *)theEvent
{    
    NSRect windowFrame = [self frame];
    
    // Get mouse location in global coordinates
    initialLocation = [self convertBaseToScreen:[theEvent locationInWindow]];
    initialLocation.x -= windowFrame.origin.x;
    initialLocation.y -= windowFrame.origin.y;
}


@end
