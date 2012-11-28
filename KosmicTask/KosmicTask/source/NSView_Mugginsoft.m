//
//  NSView_Mugginsoft.m
//  Mother
//
//  Created by Jonathan on 12/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
//  A simple category to assist with the animatioon of views
//
#import "NSView_Mugginsoft.h"

#define CHANGE_ENABLED_STATE 0 
#define RETAIN_ENABLED_STATE 1

@implementation NSView (Mugginsoft)
//
// outline code from http://www.borkware.com/quickies/one?topic=NSWindow
// also see http://www.cocoadev.com/index.pl?AMViewAnimation
// and http://www.cocoadev.com/index.pl?NSViewFade
- (void) replaceSubview:(NSView *)oldView with:(NSView *)newView withEffect:(NSView_animate)effect
{
	/*
	 NSDictionary *oldFadeOut = nil;
	 if (oldView != nil) {
	 oldFadeOut = [NSDictionary dictionaryWithObjectsAndKeys:
	 oldView, NSViewAnimationTargetKey,
	 NSViewAnimationFadeOutEffect,
	 NSViewAnimationEffectKey, nil];
	 }
	 
	 NSDictionary *newFadeIn = [NSDictionary dictionaryWithObjectsAndKeys:
	 newView, NSViewAnimationTargetKey,
	 NSViewAnimationFadeInEffect,
	 NSViewAnimationEffectKey, nil];
	 
	 NSArray * animations = [NSArray arrayWithObjects: newFadeIn, oldFadeOut, nil];
	 NSViewAnimation *animation = [[NSViewAnimation alloc] initWithViewAnimations: animations];
	 
	 [animation setAnimationBlockingMode: NSAnimationBlocking];
	 [animation setDuration: 1.0]; // or however long you want it for
	 
	 [animation startAnimation]; // because it's blocking, once it returns, we're done
	 */
	//
	// hiding views in the splitview causes it to collapse which can cause all sorts of strange redraw problesm
	// apply view effect to old view
	// So not much good for splitView
	// see http://developer.apple.com/samplecode/CocoaSlides/
	// for low down on replacing views with animation
	// and http://www.cocoabuilder.com/archive/message/cocoa/2008/1/8/196027
	// interface builder is broken in this regard
	if (effect == NSView_animateEffectFade) {
		[newView setHidden:YES];				
		[oldView setHidden:YES withFade:YES];
	}
	[self replaceSubview:oldView with:newView];
	//
	// apply view effect to new view
	//
	if (effect == NSView_animateEffectFade) {
		[newView setHidden:NO withFade:YES];
	}
}
/**
 Hides or unhides an NSView, making it fade in or our of existance.
 @param hidden YES to hide, NO to show
 @param fade if NO, just setHidden normally.
 */
- (IBAction)setHidden:(BOOL)hidden withFade:(BOOL)fade {
	if(!fade) {
		// The easy way out.  Nothing to do here...
		[self setHidden:hidden];
	} else {
		if(!hidden) {
			// If we're unhiding, make sure we queue an unhide before the animation
			//[self setHidden:NO];
		}
		
		// setup the animation dictionary
		NSMutableDictionary *animDict = [NSMutableDictionary dictionaryWithCapacity:2];
		[animDict setObject:self forKey:NSViewAnimationTargetKey];
		[animDict setObject:(hidden ? NSViewAnimationFadeOutEffect : NSViewAnimationFadeInEffect) forKey:NSViewAnimationEffectKey];
		
		// setup the animation itself
		NSViewAnimation *anim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:animDict]];
		[anim setAnimationBlockingMode: NSAnimationNonblocking];	// non blocking gives better performance it seems
		[anim setDuration:1.0];
		
		// go
		[anim startAnimation];
	}
}

- (void) replaceSubview:(NSView *)oldView withViewSizedAsOld:(NSView *)newView 
{
	// this seems to make more sense
	[self replaceSubview:oldView withViewFrameAsOld:newView];
	return;
	
	[newView setFrameSize:[oldView frame].size];	// make newView same size as oldView
	[self replaceSubview:oldView with:newView];
}

/*
 
 - replaceSubview:withViewFrameAsOld:
 
 */
- (void)replaceSubview:(NSView *)oldView withViewFrameAsOld:(NSView *)newView 
{
    NSAssert(oldView, @"existing subview ref is nil");
    NSAssert(newView, @"new subview ref is nil");

	[newView setFrame:[oldView frame]];	// make newView frame as oldView
    [self replaceSubview:oldView with:newView];
}

// resize the view and add subview beneath
// on success the total height of self + subview = height of self before
// if self is not a subview the message ends
- (void)resizeAndAddSubviewBeneath:(NSView *)subView 
{
	NSView *parentView = [self superview];
	if (!parentView) {
		return;
	}
	
	// reduce view height and adjust origin to accomodate
	// subview beneath
	CGFloat yDelta = [subView frame].size.height;
	NSRect frame = [self frame];
	frame.size.height -= yDelta;
	frame.origin.y += yDelta;
	[self setFrame:frame];	// must setNeedsDisplay
	[self setNeedsDisplay:YES];
	
	// add subview beneath view
	// what about the flipping state?
	[parentView addSubview:subView positioned:NSWindowBelow relativeTo:self];
	
	// make the subview the same width as the view
	NSRect subFrame = [subView frame];
	subFrame.size.width = frame.size.width;
	[subView setFrame:subFrame];	
	[subView setNeedsDisplay:YES];
}

// resize the view and remove subview beneath
// on success the total height of self  = height of self + subview before
// if self is not a subview the message ends
- (void)resizeAndRemoveSubviewBeneath:(NSView *)subView 
{
	NSView * parentView = [self superview];
	if (!parentView) {
		return;
	}
	
	if ([subView isDescendantOf:parentView]) {
		[subView removeFromSuperview];
		CGFloat yDelta = [subView frame].size.height;
		NSRect frame = [self frame];
		frame.size.height += yDelta;
		frame.origin.y -= yDelta;
		[self setFrame:frame];	// must setNeedsDisplay
		[self setNeedsDisplay:YES];
	}
}

/*
 
 set controls enabled
 
 */
- (void)setControlsEnabled:(BOOL)enabled
{
	[self setControlsEnabled:enabled retainState:YES recurseSubviews:YES];
}
/*
 
 set enabled state of all view controls.
 
 recurses down through all subview hierarchies.
 
 */
- (void)setControlsEnabled:(BOOL)enabled retainState:(BOOL)retainState recurseSubviews:(BOOL)recurse
{
	Class controlClass = [NSControl class];
	
	for (NSView *view in [self subviews]) {
		// or [currentView respondsToSelector:@selector(setEnabled:)]
		// except that only NSControl has setTag (NSView has tag only)
		if ([view isKindOfClass:controlClass]) {
			
			NSControl *control = (NSControl *)view;
			
			// remember control enabled state
			if (retainState) {
				[control setTag: enabled == [control isEnabled] ? RETAIN_ENABLED_STATE : CHANGE_ENABLED_STATE];
				
				if ([control tag] != RETAIN_ENABLED_STATE) {
					[control setEnabled:enabled];
				}
			} else {
				[control setEnabled:enabled];
			}
		}
		
		// recurse through subviews
		if (recurse) {
			[view setControlsEnabled:enabled retainState:retainState recurseSubviews:recurse];
		}
	}
}

/*
 
 - mgs_captureImage
 
 */
- (NSImage *)mgs_captureImage
{
	NSWindow* offscreenWindow = nil;
	NSRect frame = [self frame];

	if (![self window]) {
		NSRect offscreenRect = NSMakeRect(-10000, -10000,
										  frame.size.width, frame.size.height);
		offscreenWindow = [[NSWindow alloc]
									 initWithContentRect:offscreenRect
									 styleMask:NSBorderlessWindowMask
									 backing:NSBackingStoreRetained
									 defer:NO];
		
		[offscreenWindow setContentView:self];
		[[offscreenWindow contentView] display]; // Draw to the backing  buffer
	}
	
	// capture view image
	[self lockFocus];
	NSBitmapImageRep* viewRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect: NSMakeRect(0,0,frame.size.width,frame.size.height)];
	[self unlockFocus];
	NSImage *image = [[NSImage alloc] initWithSize:[viewRep size]];
	[image addRepresentation:viewRep];
	
	// Clean up and delete the window, which is no longer needed.
	if (offscreenWindow) {
		[self removeFromSuperview];
	}
	
	return image;
}

/*
 
 - mgs_captureImageView
 
 */
- (NSImageView *)mgs_captureImageView
{
	NSImage *image = [self mgs_captureImage];
	if (!image) return nil;
	
	// create image view
	NSImageView *imageView = [[NSImageView alloc] initWithFrame:[self frame]];
	[imageView setImage:image];
	
	return imageView;
}

/*
 
 - mgs_fadeToSiblingView:duration:
 
 uses NSViewAnimation
 
 core animation requires layer backed views which if I remember correctly 
 can cause issues for complex view hierarchies

 */
- (void)mgs_fadeToSiblingView:(NSView *)siblingView duration:(NSTimeInterval)duration
{
	if ([self wantsLayer] && [siblingView wantsLayer]) {
		// core animation will not block so an animation delegate will need to
		// be defined ro process views after the transition has completed
		[[self superview] setWantsLayer:YES];
		[[[self superview] animator] replaceSubview:self with:siblingView];
	} else {
		NSDictionary *fadeOutDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
										   self, NSViewAnimationTargetKey,
										   NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey,
										   nil];
		
		NSDictionary *fadeInDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
										  siblingView, NSViewAnimationTargetKey,
										  NSViewAnimationFadeInEffect, NSViewAnimationEffectKey,
										  nil];
		
		NSArray *animationArray = [NSArray arrayWithObjects:
								   fadeOutDictionary,
								   fadeInDictionary,
								   nil];
		
		NSViewAnimation *viewAnimation = [[NSViewAnimation alloc] initWithViewAnimations:animationArray];
		[viewAnimation setDuration:duration];
		[viewAnimation setAnimationBlockingMode: NSAnimationBlocking];
		[viewAnimation startAnimation];
	}
	
}
@end
