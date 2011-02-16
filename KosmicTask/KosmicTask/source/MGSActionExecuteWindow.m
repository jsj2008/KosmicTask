//
//  MGSActionExecuteWindow.m
//  Mother
//
//  Created by Jonathan on 02/09/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSActionExecuteWindow.h"
#import "MGSNotifications.h"
#import "MGSTaskSpecifier.h"
#import "NSWindow_Mugginsoft.h"
#import "MGSNetClient.h"
#import "MGSNetClientContext.h"
#import "MGSMotherModes.h"

@implementation MGSActionExecuteWindow

/*
 
 NSWindow designated initialiser
 
 */
- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)windowStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation
{
	if ((self = [super initWithContentRect:contentRect styleMask:windowStyle backing:bufferingType defer:deferCreation])) {
		_clickViews = [NSHashTable hashTableWithWeakObjects];
	}
	
	return self;
}

/*
 
 set title bar icon
 
 */
- (void)setTitleBarIcon:(NSImage *)image
{
	[self removeTitleBarIcon];
	_titleBarImageView = [self addIconToTitleBar:[image copy]];
	[_titleBarImageView setToolTip:NSLocalizedString(@"SSL status", @"tool tip for security icon in top right window corner")];
}

/*
 
 remove title bar icon
 
 */
- (void)removeTitleBarIcon
{
	if (_titleBarImageView) {
		[_titleBarImageView removeFromSuperview];
	}
}


/*
 
 validate menu item
 
 */

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	#pragma unused(menuItem)
	
	return YES;
 }

/*
 
 mother action
 
 */
- (MGSTaskSpecifier *)selectedActionSpecifier
{
	if ([self delegate] && [[self delegate] respondsToSelector:@selector(selectedActionSpecifier)]) {
		return [[self delegate] performSelector:@selector(selectedActionSpecifier)];
	}
	
	return nil;
}

/*
 
 send event
 
 This action method dispatches mouse and keyboard events sent to the window by the NSApplication object.
 
 */
- (void)sendEvent:(NSEvent *)event
{

	// look for mouse down
	if ([event type] == NSLeftMouseDown) {
		
		// look for deepest subview
		NSView *deepView = [[self contentView] hitTest:[event locationInWindow]];
		if (deepView) {
			for (NSView *aClickView in _clickViews) {
				if ([deepView isDescendantOf:aClickView]) {
					[(id)aClickView subviewClicked:deepView];
					break;
				}
			}
		}			
	}
	
	[super sendEvent:event];

}

/*
 
 add a click view
 
 click view must be a sub view of the NSWindow contentView
 
 */
- (void)addClickView:(NSView *)aView
{
	if ([aView isDescendantOf:[self contentView]] && [aView respondsToSelector:@selector(subviewClicked:)]) {
		
		// _clickViews will maintain a weak ref to aView so we don't need
		// to remove it
		[_clickViews addObject:aView];
	}
}

@end
