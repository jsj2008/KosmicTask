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
	IBOutlet NSTextField *__weak bannerLeftLabel;				// left banner value
	IBOutlet NSTextField *__weak bannerRightLabel;				// right banner value

	// layout
	IBOutlet NSView *__weak bannerView;						// banner view	
	IBOutlet NSView *__weak topView;							// top view
	IBOutlet NSView *__weak middleView;						// placeholder for middle view
	IBOutlet NSView *__weak bottomView;						// bottom view
	IBOutlet NSImageView *__weak dragThumb;					// drag thumb
	IBOutlet NSImageView *__weak middleDragThumb;				// middle drag thumb
	
	NSString *_bannerLeft;								// left banner text
	NSString *_bannerRight;								// right banner text
	id __weak _delegate;

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
	NSCursor *__weak _resizeCursor;							// resize cursor to use when view height modification validation fails
	CGFloat _middleViewTopYOffset;	// needed to ensure correct view positioning when drag views quickly
}

@property (weak) id delegate;
@property (weak) NSTextField *bannerLeftLabel;				// left banner value
@property (weak) NSTextField *bannerRightLabel;	
@property (copy) NSString *bannerLeft;
@property (copy) NSString *bannerRight;
@property (weak) NSView *bannerView;							// banner view	
@property (weak) NSView *topView;								// top view
@property (weak) NSView *middleView;							// placeholder for middle view
@property (weak) NSView *bottomView;
@property (weak) NSImageView *dragThumb;						// drag thumb
@property (weak) NSImageView *middleDragThumb;					// middle drag thumb

@property CGFloat minHeight;							// min view drag height
@property CGFloat maxHeight;							// max view drag height
@property CGFloat minMiddleHeight, maxMiddleHeight;		// middle view height limits
@property CGFloat minBottomHeight, maxBottomHeight;		// bottom view height limits
@property (nonatomic) BOOL canDragHeight;
@property (nonatomic) BOOL canDragMiddleView;
@property BOOL dragThumbHidden;
@property BOOL middleDragThumbHidden;
@property BOOL allowHighlight;
@property (weak) NSCursor *resizeCursor;

- (NSRect)dragThumbRect;					// NSRect for bottom drag thumb
- (NSRect)middleDragThumbRect;				// NSRect for middle drag thumb
- (BOOL)isHighlighted;						// YES if view highlighted
- (void)setIsHighlighted:(BOOL)value;		//
- (BOOL)isDragTarget;
- (void)setIsDragTarget:(BOOL)value;
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
