//
//  NSWindow_Mugginsoft.m
//  Mother
//
//  Created by Jonathan on 24/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "NSWindow_Mugginsoft.h"


@implementation NSWindow (Mugginsoft)

/*
 
 end all editing in window
 
 */
- (BOOL)endEditing:(BOOL)force
{
	id firstResponder = [self firstResponder];
	
	// gracefully end all editing in a window named aWindow 
	if ([self makeFirstResponder:self])  { 
		// All editing is now ended and delegate messages sent etc. 
	} else if (force) { 
		// For some reason the text object being edited will not resign 
		// first responder status so force an end to editing anyway.
        // This is probably a bad idea as the first responder is probably refusing to resign
        // its status because of a pending or failed validation.
        // forcing the edit can leave our model in an invalid state.
		[self endEditingFor:nil]; 
	} else {
        return NO;
    }
	
	// restore the first responder once editing completed.
	// this is required in situations where this message is sent from
	// - (void)windowDidResignKey:(NSNotification *)notification.
	// a panel, such as the find panel, may be being displayed.
	// it will require the window's firstResponder to be maintained.
	[self makeFirstResponder:firstResponder];
    
    return YES;
}

// from http://www.cocoabuilder.com/archive/message/cocoa/2004/11/11/121369

/*
 
 window toolbar height
 
 */
- (float) toolbarHeight
{
    return NSHeight([NSWindow contentRectForFrameRect:[self frame]
											styleMask:[self styleMask]]) -
	NSHeight([[self contentView] frame]);
}

/*
 
 window title bar height
 
 */
- (float) titleBarHeight
{
    return NSHeight([self frame]) -
	NSHeight([[self contentView] frame]) -
	[self toolbarHeight];
}


/*
 
 minimal window height
 window reduced to height of toolbar
 
 */
- (float)minimalWindowHeight
{
    NSToolbar *toolbar;
    float toolbarHeight = 0.0f;
    NSRect windowFrame;
	
    toolbar = [self toolbar];
	
    if(toolbar && [toolbar isVisible])
    {
        windowFrame = [self frame];
        toolbarHeight = NSHeight(windowFrame)
		- NSHeight([[self contentView] frame]);
    }
	
    return toolbarHeight;
}

#define kIconSpacing 8.0f // h-space between the icon and the toolbar button

/*
 
 add icon to toolbar
 
 */
- (NSImageView*) addIconToTitleBar:(NSImage*) icon
{
	id superview = nil;
	NSRect rightButtonFrame = [self standardWindowRightButtonFrame:&superview];
	if (!superview) return nil;
	
    NSRect iconFrame;
    
    iconFrame.size = [icon size];
    iconFrame.origin.y = NSMaxY([superview frame]) -
	(iconFrame.size.height + ceilf(([self
									titleBarHeight] - iconFrame.size.height) / 2.0f));
    iconFrame.origin.x = NSMinX(rightButtonFrame) - iconFrame.size.width -
	kIconSpacing;
    
    NSImageView* iconView = [[NSImageView alloc] initWithFrame:iconFrame];
    [iconView setImage:icon];
    [iconView setEditable:NO];
    [iconView setImageFrameStyle:NSImageFrameNone];
    [iconView setImageScaling:NSScaleNone];
    [iconView setImageAlignment:NSImageAlignCenter];
    [iconView setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    [superview addSubview:iconView];
	
    return iconView;
}

/*
 
 standard window right button frame
 
 */
- (NSRect)standardWindowRightButtonFrame:(NSView **)superview
{
	*superview = nil;
	NSRect rightButtonFrame = NSZeroRect;
	
	// rightmost button is tool bar button if present
	NSButton *toolbarButton = [self standardWindowButton:NSWindowToolbarButton];
	if (toolbarButton) {
		*superview = [toolbarButton superview];
		rightButtonFrame = [toolbarButton frame];
	} else {
		
		// otherwise create empty frame
		NSButton *zoomButton = [self standardWindowButton:NSWindowZoomButton];
		*superview = [zoomButton superview];
		rightButtonFrame = [*superview frame];
		rightButtonFrame.origin.x = rightButtonFrame.size.width;
		rightButtonFrame.size.width = 0;
	}
	
	return rightButtonFrame;
}
/*
 
 add view to toolbar
 
 */
- (void) addViewToTitleBar:(NSView*)view xoffset:(CGFloat)xoffset
{
	id superview = nil;
	NSRect rightButtonFrame = [self standardWindowRightButtonFrame:&superview];
	if (!superview) return;
	
    NSRect iconFrame;
    
    iconFrame.size = [view bounds].size;
    iconFrame.origin.y = NSMaxY([superview frame]) -
	(iconFrame.size.height + ceilf(([self
									titleBarHeight] - iconFrame.size.height) / 2.0f));
    iconFrame.origin.x = NSMinX(rightButtonFrame) - iconFrame.size.width -
	kIconSpacing;
    
	if (xoffset > 0) {
		iconFrame.origin.x -= (xoffset + kIconSpacing);
	}
	
    [view setFrame:iconFrame];
    //[iconView setEditable:NO];
    //[iconView setImageFrameStyle:NSImageFrameNone];
    //[iconView setImageScaling:NSScaleNone];
    //[iconView setImageAlignment:NSImageAlignCenter];
    [view setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    [superview addSubview:view];
	
    return;
}


@end
