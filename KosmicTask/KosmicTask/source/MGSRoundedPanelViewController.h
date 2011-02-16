//
//  MGSRoundedPanelViewController.h
//  Mother
//
//  Created by Jonathan on 23/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MGSRoundedPanelView;
@class MGSRoundedPanelViewController;

@protocol MGSRoundedPanelViewControllerDelegate <NSObject>
- (void)controllerViewClicked:(MGSRoundedPanelViewController *)controller;
@end


@interface MGSRoundedPanelViewController : NSViewController {
@private
	IBOutlet NSTextField *bannerLeftLabel;				// left banner value
	IBOutlet NSTextField *bannerRightLabel;				// right banner value

	// layout
	IBOutlet NSView *bannerView;						// banner view	
	IBOutlet NSView *topView;							// top view
	IBOutlet NSView *middleView;						// placeholder for middle view
	IBOutlet NSView *bottomView;						// bottom view
	IBOutlet NSImageView *dragThumb;					// drag thumb
	IBOutlet NSImageView *middleDragThumb;				// middle drag thumb
	
	NSString *_bannerLeft;								// left banner text
	NSString *_bannerRight;								// right banner text
	id _delegate;

	CGFloat _minHeight;									// min view drag height
	CGFloat _maxHeight;									// max view drag height
	CGFloat _minMiddleHeight;							// min middle view drag height
	CGFloat _maxMiddleHeight;							// max middle view drag height
	CGFloat _minBottomHeight;							// min bottom view drag height
	CGFloat _maxBottomHeight;							// max bottom view drag height
	BOOL _canDragHeight;								// YES if can drag view height between max and min
	BOOL _canDragMiddleView;							// YES if can drag middle view 
	
	BOOL _dragThumbHidden;								// YES if bottom drag thumb hidden
	BOOL _middleDragThumbHidden;						// YES if middle drag thumb hidden
	BOOL _allowHighlight;								// YES if highlighting is permitted
	NSCursor *_resizeCursor;							// resize cursor to use when view height modification validation fails
	CGFloat _middleViewTopYOffset;	// needed to ensure correct view positioning when drag views quickly
}

@property id delegate;
@property NSTextField *bannerLeftLabel;				// left banner value
@property NSTextField *bannerRightLabel;	
@property (copy) NSString *bannerLeft;
@property (copy) NSString *bannerRight;
@property NSView *bannerView;							// banner view	
@property NSView *topView;								// top view
@property NSView *middleView;							// placeholder for middle view
@property NSView *bottomView;
@property NSImageView *dragThumb;						// drag thumb
@property NSImageView *middleDragThumb;					// middle drag thumb

@property CGFloat minHeight;							// min view drag height
@property CGFloat maxHeight;							// max view drag height
@property CGFloat minMiddleHeight, maxMiddleHeight;		// middle view height limits
@property CGFloat minBottomHeight, maxBottomHeight;		// bottom view height limits
@property BOOL canDragHeight;
@property BOOL canDragMiddleView;
@property BOOL dragThumbHidden;
@property BOOL middleDragThumbHidden;
@property BOOL allowHighlight;
@property NSCursor *resizeCursor;

- (NSRect)dragThumbRect;					// NSRect for bottom drag thumb
- (NSRect)middleDragThumbRect;				// NSRect for middle drag thumb
- (BOOL)isHighlighted;						// YES if view highlighted
- (void)setIsHighlighted:(BOOL)value;		//
- (void)setBannerRightBackgroundColor:(NSColor *)color;
- (void)modifyBottomViewHeightBy:(CGFloat)heightDelta;
- (CGFloat)canModifyBottomViewHeightBy:(CGFloat)heightDelta;
- (void)modifyMiddleViewHeightBy:(CGFloat)heightDelta;
- (CGFloat)canModifyMiddleViewHeightBy:(CGFloat)heightDelta;
- (CGFloat)canModifyView:(NSView *)subView heightBy:(CGFloat)heightDelta minHeight:(CGFloat)minHeight maxHeight:(CGFloat)maxHeight;
- (void)logMe;
- (MGSRoundedPanelView *)roundedPanelView;
- (void)updateFooterPosition;
- (void)cacheMiddleViewTopYOffset;
@end
