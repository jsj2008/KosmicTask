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
-(void)endEditing
{
	
	// gracefully end all editing in a window named aWindow 
	if([self makeFirstResponder:self]) 
	{ 
		// All editing is now ended and delegate messages sent etc. 
	} 
	else 
	{ 
		// For some reason the text object being edited will not resign 
		// first responder status so force an end to editing anyway 
		[self endEditingFor:nil]; 
	}
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


#define kIconSpacing 8.0 // h-space between the icon and the toolbar button

/*
 
 add icon to toolbar
 
 */
- (NSImageView*) addIconToTitleBar:(NSImage*) icon
{
    id superview = [[self standardWindowButton:NSWindowToolbarButton]
					superview];
    NSRect toolbarButtonFrame = [[self
								  standardWindowButton:NSWindowToolbarButton] frame];
    NSRect iconFrame;
    
    iconFrame.size = [icon size];
    iconFrame.origin.y = NSMaxY([superview frame]) -
	(iconFrame.size.height + ceil(([self
									titleBarHeight] - iconFrame.size.height) / 2.0));
    iconFrame.origin.x = NSMinX(toolbarButtonFrame) - iconFrame.size.width -
	kIconSpacing;
    
    NSImageView* iconView = [[[NSImageView alloc] initWithFrame:iconFrame]
							 autorelease];
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
 
 add view to toolbar
 
 */
- (void) addViewToTitleBar:(NSView*)view xoffset:(CGFloat)xoffset
{
	CGFloat minX = 0.0;
	
    id superview = [[self standardWindowButton:NSWindowToolbarButton] superview];
	if (superview) {
		NSRect toolbarButtonFrame = [[self standardWindowButton:NSWindowToolbarButton] frame];
		minX = NSMinX(toolbarButtonFrame);
	} else {
		superview = [[self standardWindowButton:NSWindowCloseButton] superview];
		minX = [superview bounds].size.width;
	}
	if (!superview) {
		return;
	}
	
    NSRect iconFrame;
    
    iconFrame.size = [view bounds].size;
    iconFrame.origin.y = NSMaxY([superview frame]) - (iconFrame.size.height + ceil(([self titleBarHeight] - iconFrame.size.height) / 2.0));
    iconFrame.origin.x = minX - iconFrame.size.width - kIconSpacing;
    
	if (xoffset > 0) {
		iconFrame.origin.x -= (xoffset + kIconSpacing);
	}
	
    [view setFrame:iconFrame];
    [view setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    [superview addSubview:view];
	
    return;
}


@end
