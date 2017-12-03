//
//  MGSRoundedPanelView.h
//  Mother
//
//  Created by Jonathan on 23/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MGSRoundedView.h"
#import "MGSActionExecuteWindow.h"

enum _MGSRoundedPanelViewStyle {
    kMGSRoundedPanelViewStyleParameter = 0,
    kMGSRoundedPanelViewStyleEmptyParameter = 1,
};
typedef NSUInteger MGSRoundedPanelViewStyle;

@interface MGSRoundedPanelView : MGSRoundedView <MGSSubviewClicking> {
@private
	IBOutlet id __unsafe_unretained delegate;
	BOOL _isHighlighted;
    BOOL _isDragTarget;
	BOOL _drawFooter;
	BOOL _wasFirstResponder;
	BOOL _observeFirstResponder;
	
	CGFloat _footerHeight;
	CGFloat _bannerHeight;
	CGFloat _minX;
	CGFloat _midX;
	CGFloat _maxX;
	CGFloat _minY;
	//CGFloat midY = NSMidY(bgRect);
	CGFloat _maxY;
	CGFloat _maxXMargin;
	CGFloat _minXMargin;
	CGFloat _minYMargin;
	CGFloat _maxYMargin;
	
	NSPoint _bodyLeftBottom, _bodyRightBottom;
	NSPoint _bannerMiddleTop, _bannerLeftBottom, _bannerRightBottom;
	NSPoint _footerLeftTop, _footerRightTop;
	
	NSColor *_bannerStartColor;
	NSColor *_bannerMidColor;
	NSColor *_bannerEndColor;	
	
	BOOL _hasConnector;
    MGSRoundedPanelViewStyle _panelStyle;
}

@property (nonatomic) MGSRoundedPanelViewStyle panelStyle;
@property (unsafe_unretained) id delegate;
@property (nonatomic) BOOL isHighlighted;
@property (nonatomic) BOOL isDragTarget;
@property (nonatomic) BOOL drawFooter;
@property (nonatomic) CGFloat footerHeight;
@property CGFloat bannerHeight;
@property CGFloat maxXMargin;
@property CGFloat minXMargin;
@property CGFloat minYMargin;
@property CGFloat maxYMargin;
@property BOOL hasConnector;
@property (copy) NSColor *bannerStartColor;	// lightest gradient color - top
@property (copy) NSColor *bannerMidColor;		// mid hue color
@property (copy) NSColor *bannerEndColor;		// darkest color

+ (NSColor *)highlightColor;
+ (NSColor *)dragTargetOutlineColor;
- (void)subviewClicked:(NSView *)aView;


@end

