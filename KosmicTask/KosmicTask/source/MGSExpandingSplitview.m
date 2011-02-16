//
//  MGSExpandingSplitview.m
//  KosmicTask
//
//  Created by Jonathan on 28/12/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import "MGSExpandingSplitview.h"

@interface MGSExpandingSplitview()
- (void)autoSizeHeight;
- (CGFloat)heightOfSubviews;
- (void)subviewFrameDidChange:(NSNotification *)aNote;
@end

@implementation MGSExpandingSplitview

/*
 
 did add subview
 
 */
-(void)didAddSubview:(NSView *)subview
{
	[subview setPostsFrameChangedNotifications:YES]; 
	[[NSNotificationCenter defaultCenter] addObserver:self 
										selector:@selector(subviewFrameDidChange:) 
										name:NSViewFrameDidChangeNotification 
										object:subview];
}

/*
 
 will remove subview
 
 */
- (void)willRemoveSubview:(NSView *)subview
{
	[subview setPostsFrameChangedNotifications:NO];
	[[NSNotificationCenter defaultCenter] removeObserver:self 
										name:NSViewFrameDidChangeNotification 
										object:subview];
}

/*
 
 subview frame did change
 
 */
- (void)subviewFrameDidChange:(NSNotification *)aNote
{
	#pragma unused(aNote)
	
	[self autoSizeHeight];
}
/*
 
 auto size height view so that all subviews are fully visible
 
 */
- (void)autoSizeHeight
{
	// now change the splitview size
	NSSize size = [self frame].size;
	size.height = [self heightOfSubviews];
	
	// method - (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize
	// will be triggered which in turn will call -adjustSubviews.
	[self setFrameSize:size];
	[self setNeedsDisplay:YES];
}

/*
 
 height of subviews
 
 */
- (CGFloat)heightOfSubviews
{
	NSInteger subviewCount = [[self subviews] count];
	CGFloat height = 0;
	
	// start with first view.
	// calculate total height of all subviews
	for (int i = 0; i < subviewCount; i++) {
		NSView *view = [[self subviews] objectAtIndex:i];
		NSRect frame = [view frame];
		
		// increment height
		height += frame.size.height + [self dividerThickness];
	}
	height -= [self dividerThickness];

	return height;
}
/*
 
 layout our subviews
 
 manual resize of subviews when resize splitview
 
 NOTE: uses a flipped coordinate system
 
 subview at index 0 is topmost.
 origin is top left.
 
 notes:
 
 the view frames do not seem to be observed so changing them directly does not trigger this message.
 always call autosize height when have adjusted subviews.
 */
- (void)adjustSubviews
{
	// calc vertical size change
	NSRect splitViewFrame = [self frame];
	CGFloat nextOriginY = 0.0f;
	
	// if view height does not match subviews height then make it so
	if ((NSInteger)[self heightOfSubviews] != (NSInteger)splitViewFrame.size.height) {
		[self autoSizeHeight];
		return;
	}
	
	// position our views.
	// note that we only ensure that the subviews width matches
	// the splitview width.
	// the height of the subviews must be set before the splitview itself is resized.
	NSUInteger subviewCount = [[self subviews] count];
	
	// start with first view.
	// position it top left.
	// position remaining views below it separated by the divider thickness.
	for (NSUInteger viewIndex = 0; viewIndex < subviewCount; viewIndex++) {
		NSView *view = [[self subviews] objectAtIndex:viewIndex];
		NSRect frame = [view frame];
		
		// resize width, keep existing height
		frame.size.width = splitViewFrame.size.width;
		
		// set origin
		frame.origin.x = 0;
		frame.origin.y = nextOriginY;
				
		[view setFrame:frame];
		[view setNeedsDisplay:YES];
		
		// calc next origin
		nextOriginY += frame.size.height + [self dividerThickness];
	}
}

@end
