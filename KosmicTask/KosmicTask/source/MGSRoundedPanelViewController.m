//
//  MGSRoundedPanelViewController.m
//  Mother
//
//  Created by Jonathan on 23/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSRoundedPanelViewController.h"
#import "MGSRoundedPanelView.h"
/*
 
 abstract class designed to be subclassed
 
 */
@implementation MGSRoundedPanelViewController

@synthesize delegate = _delegate;
@synthesize bannerLeft = _bannerLeft;
@synthesize bannerRight = _bannerRight;
@synthesize minHeight = _minHeight;
@synthesize maxHeight = _maxHeight;
@synthesize canDragHeight = _canDragHeight;
@synthesize canDragMiddleView = _canDragMiddleView;
@synthesize dragThumbHidden = _dragThumbHidden;
@synthesize middleDragThumbHidden = _middleDragThumbHidden;
@synthesize bannerView, topView, middleView, bottomView, bannerLeftLabel, bannerRightLabel, dragThumb, middleDragThumb;
@synthesize allowHighlight = _allowHighlight;
@synthesize minMiddleHeight = _minMiddleHeight, maxMiddleHeight = _maxMiddleHeight;
@synthesize minBottomHeight = _minBottomHeight, maxBottomHeight = _maxBottomHeight;
@synthesize resizeCursor = _resizeCursor;

/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	// indent text
	[[bannerLeftLabel cell] setBackgroundStyle:NSBackgroundStyleRaised];
	
	// enable ellipsis truncating of text fields
	[[bannerLeftLabel cell] setLineBreakMode:NSLineBreakByTruncatingTail];	// can do in IB too
	
	self.allowHighlight = YES;
	
	// remaining bindings
	[self.dragThumb	bind:NSHiddenBinding toObject:self withKeyPath:@"dragThumbHidden" options:nil];
	[self.middleDragThumb bind:NSHiddenBinding toObject:self withKeyPath:@"middleDragThumbHidden" options:nil];
}


- (void)cacheMiddleViewTopYOffset
{
	_middleViewTopYOffset = [[self view] frame].size.height - [self.middleView frame].size.height - [self.middleView frame].origin.y;

}
/*
 
 set can drag height
 
 */
- (void)setCanDragHeight:(BOOL)value
{
	_canDragHeight = value;
	self.dragThumbHidden = !_canDragHeight;
}

/*
 
 set can drag middle view
 
 */
- (void)setCanDragMiddleView:(BOOL)value
{
	_canDragMiddleView = value;
	self.middleDragThumbHidden = !_canDragMiddleView;
}

/*
 
 drag thumb rect
 
 */
- (NSRect)dragThumbRect
{
	if (_dragThumbHidden) {
		return NSZeroRect;
	}
	
	return [dragThumb frame];
}
/*
 
 middle drag thumb rect
 
 */
- (NSRect)middleDragThumbRect
{
	if (_middleDragThumbHidden) {
		return NSZeroRect;
	}
	
	return [middleDragThumb frame];
}

/*
 
 is highlighted
 
 */
- (BOOL)isHighlighted
{
	return [(MGSRoundedPanelView *)[self view] isHighlighted];
}

/*
 
 set is highlighted
 
 */
- (void)setIsHighlighted:(BOOL)value
{
	if (self.allowHighlight) {
		[(MGSRoundedPanelView *)[self view] setIsHighlighted:value];
	}
}

/*
 
 - isDragTarget
 
 */
- (BOOL)isDragTarget
{
	return [(MGSRoundedPanelView *)[self view] isDragTarget];
}

/*
 
 - setIsDragTarget:
 
 */
- (void)setIsDragTarget:(BOOL)value
{
	//if (self.allowHighlight) {
		[(MGSRoundedPanelView *)[self view] setIsDragTarget:value];
	//}
}
/*
 
 set banner right background color
 
 */
- (void)setBannerRightBackgroundColor:(NSColor *)color
{
	[bannerRightLabel setBackgroundColor:color];
}

/*
 
 mouse down
 
 */
- (void)mouseDown:(NSEvent *)theEvent
{
	#pragma unused(theEvent)
	
	// highlight view on mouse down
	//[self setIsHighlighted:YES];
}
/*
 
 modify bottom view height
 
 this may be called to override the effect of the views
 autoresizing of its subviews
 
 the overall view height remains the same.
 the middle view height is decreased accordingly
 */
- (void)modifyBottomViewHeightBy:(CGFloat)heightDelta
{
	
	//NSLog(@"height delta = %f", heightDelta);
	NSRect viewFrame = [[self view] frame];
	NSRect middleFrame = [self.middleView frame];
	NSRect bottomFrame = [self.bottomView frame];
	NSRect dragFrame = [self.middleDragThumb frame];
	
	//NSLog(@"BEFORE middle frame x = %f y = %f width = %f height = %f", middleFrame.origin.x, middleFrame.origin.y, middleFrame.size.width, middleFrame.size.height);
	//NSLog(@"BEFORE bottom frame x = %f y = %f width = %f height = %f", bottomFrame.origin.x, bottomFrame.origin.y, bottomFrame.size.width, bottomFrame.size.height);
	
	dragFrame .origin.y += heightDelta;
	
	middleFrame.origin.y += heightDelta;
	
#pragma mark some trouble resizing here when drag quickly
	//middleFrame.size.height = topFrame.origin.y - middleFrame.origin.y;
	middleFrame.size.height = viewFrame.size.height - _middleViewTopYOffset - middleFrame.origin.y;
	
	bottomFrame.size.height += heightDelta;
	
	[self.middleView setFrame:middleFrame];
	[self.middleView setNeedsDisplay:YES];
	[self.bottomView setFrame:bottomFrame];
	[self.bottomView setNeedsDisplay:YES];
	[self.middleDragThumb setFrame:dragFrame];
	[self.middleDragThumb setNeedsDisplay:YES];
	
	//NSLog(@"AFTER middle frame x = %f y = %f width = %f height = %f", middleFrame.origin.x, middleFrame.origin.y, middleFrame.size.width, middleFrame.size.height);
	//NSLog(@"AFTER bottom frame x = %f y = %f width = %f height = %f", bottomFrame.origin.x, bottomFrame.origin.y, bottomFrame.size.width, bottomFrame.size.height);
	
	[self updateFooterPosition];
}

/*
 
 can modify bottom height by
 
 default returns 0 - cannot modify height
 
 */
- (CGFloat)canModifyBottomViewHeightBy:(CGFloat)heightDelta
{
	return [self canModifyView:bottomView heightBy:heightDelta minHeight:_minBottomHeight maxHeight:_maxBottomHeight];
}
/*
 
 modify middle height by
 
 default does nothing - designed to be overridden
 
 */
- (void)modifyMiddleViewHeightBy:(CGFloat)heightDelta
{
	#pragma unused(heightDelta)
	
	return;
}
/*
 
 can modify middle height by
 
 */
- (CGFloat)canModifyMiddleViewHeightBy:(CGFloat)heightDelta
{
	return [self canModifyView:middleView heightBy:heightDelta minHeight:_minMiddleHeight maxHeight:_maxMiddleHeight];
}

/*
 
 can modify view height by
 
 valiates if view height can be modified by heightDelta.
 if so returns heightDelta.
 if not it returns max allowable heightDelta.
 
 */
- (CGFloat)canModifyView:(NSView *)subView heightBy:(CGFloat)heightDelta minHeight:(CGFloat)minHeight maxHeight:(CGFloat)maxHeight
{
	NSRect frame = [subView frame];
	CGFloat height = frame.size.height;
	CGFloat newHeight = height + heightDelta;
	
	self.resizeCursor = nil;
	
	if (newHeight < minHeight) {
		if (height > minHeight) {
			newHeight = minHeight;	// make min height
		} else {
			newHeight = height;		// new height is same as old
			self.resizeCursor = [NSCursor resizeDownCursor];
		}
	}
	else if (newHeight > maxHeight) {
		if (height < maxHeight) {
			newHeight = maxHeight;	// make max height
		} else {
			newHeight = height;		// new height is same as old
			self.resizeCursor = [NSCursor resizeUpCursor];
		}
	}
	
	// return our acceptable delta
	return newHeight - height;
}

/*
 
 log the view
 
 */
- (void)logMe
{
	NSLog(@"%@", [self className]);
	//MLogRect(@"banner view rect = ", [bannerView frame]);
	//MLogRect(@"top view rect = ", [topView frame]);
	MLogRect(@"middle view rect = ", [middleView frame]);
	//MLogRect(@"bottom view rect = ", [bottomView frame]);
}

/*
 
 upate the footer position
 
 */
- (void)updateFooterPosition
{
	// if drawing footer determine its height
	if ([self roundedPanelView].drawFooter) {
		
		// draw footer above bottom view
		NSRect frame = self.bottomView.frame;
		[[self roundedPanelView] setFooterHeight:frame.origin.y + frame.size.height];
	}	
}

/*
 
 rounded panel view
 
 */
- (MGSRoundedPanelView *)roundedPanelView
{
	if ([[self view] isKindOfClass:[MGSRoundedPanelView class]]) {
		return (MGSRoundedPanelView *)[self view];
	} else {	
		return nil;
	}
}

/*
 
 view or subview clicked
 
 */
- (void)subviewClicked:(NSView *)aView
{
#pragma unused(aView)
	
	//[self setIsHighlighted:YES];
	
	// inform delegate that subview clicked
	if (self.delegate && [self.delegate respondsToSelector:@selector(controllerViewClicked:)]) {
		[self.delegate controllerViewClicked:self];
	}
}
@end
