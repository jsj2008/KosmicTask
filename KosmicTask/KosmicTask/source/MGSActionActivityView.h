//
//  MGSActionActivityView.h
//  Mother
//
//  Created by Jonathan on 16/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSTaskSpecifier.h"
#import "MGSMotherModes.h"

enum _mgsFadeType {
    kMGSFadeTypeNone,
    kMGSFadeTypeIn,
    kMGSFadeTypeOut
};
typedef NSInteger mgsFadeType;

@protocol MGSActionActivityViewDelegate <NSObject>

@required
- (void)viewDidMoveToWindow;

@end

@class MGSTextView;

@interface MGSActionActivityView : NSView {
	MGSTaskActivity _activity;
	eMGSMotherRunMode _runMode;
	BOOL _respectRunMode;
	id <MGSActionActivityViewDelegate> _delegate;
	double doubleValue;
	NSTimeInterval animationDelay;
	BOOL displayedWhenStopped;
	BOOL spinning;
	NSColor *_fillColor;
	NSColor *_centreColor;
	NSColor *_backgroundFillColor;

	NSGradient *_centreGradient;
	NSColor *_centreColorGradientStart;
	NSColor *_centreColorGradientEnd;
	
	NSGradient *_centreGradientHighlight;
	NSColor *_centreColorActiveGradientStart;
	NSColor *_centreColorActiveGradientEnd;
	
	NSGradient *_centreGradientAlt;
	NSColor *_centreColorAltGradientEnd;
	NSColor *_centreColorAltGradientStart;
	
						   
	NSColor *_pausedSpinnerColor;
	NSColor *_spinnerColor;

	NSBezierPath *_bezierPath;
	NSBezierPath *_centreBezierPath;
	NSSize _shadowSize;
	BOOL _depressed;
	NSColor *_depressedBackgroundColor;
	
	CGFloat _minSize;
	NSPoint _centerPoint;
	
	CGFloat _outerRadius;
	CGFloat _innerRadius;
	CGFloat _circleRadius;
	CGFloat _circleLineWidth;
	
	NSLineCapStyle _bezierLineCapStyle;
	CGFloat _bezierLineWidth;
	NSInteger _spinnerStyle;
	
	NSRect _cacheRect;
	NSImage *_imageCache;
    NSImage *_spinnerCache;
	NSBitmapImageRep *_imageRep;
	NSRect _animatedCircleRect;
	BOOL _useImageCache;
    BOOL _useSpinnerCache;
	BOOL _canClick;
	
	BOOL _hasDropShadow;
	NSTrackingArea *_trackingArea;
	id target;
	SEL action;
    
    MGSTextView *_textView;
    NSScrollView *_textScrollview;
    CGFloat _masterAlpha;
    CGFloat _spinnerAlpha;
    NSTimer *_alphaTimer;
    BOOL _useLayers;
    BOOL _updateCursor;
    mgsFadeType _activeFadeType;
}

- (void)initialise;

- (double)doubleValue;
- (void)setDoubleValue:(double)value;

- (NSTimeInterval)animationDelayForActivity;
- (NSTimeInterval)animationDelay;
- (void)setAnimationDelay:(NSTimeInterval)value;

- (BOOL)isDisplayedWhenStopped;
- (void)setDisplayedWhenStopped:(BOOL)value;

- (BOOL)isSpinning;
- (void)setSpinning:(BOOL)value;

- (void)clearDisplayCache;
- (void)updateAnimation;

- (void)appendText:(NSString *)text;
- (void)clearText;
- (NSString *)text;

@property MGSTaskActivity activity;
@property eMGSMotherRunMode runMode;
@property (copy) NSColor *backgroundFillColor;
@property (copy) NSColor *foregroundColor;
@property BOOL hasDropShadow;
@property BOOL respectRunMode;
@property id <MGSActionActivityViewDelegate> delegate;

@property id target;
@property SEL action;

@end
