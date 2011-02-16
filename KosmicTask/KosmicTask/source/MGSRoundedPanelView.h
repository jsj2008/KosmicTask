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

@interface MGSRoundedPanelView : MGSRoundedView <MGSSubviewClicking> {
@private
	IBOutlet id delegate;
	BOOL _isHighlighted;
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

}


@property id delegate;
@property BOOL isHighlighted;
@property BOOL drawFooter;
@property CGFloat footerHeight;
@property CGFloat bannerHeight;
@property CGFloat maxXMargin;
@property CGFloat minXMargin;
@property CGFloat minYMargin;
@property CGFloat maxYMargin;
@property BOOL hasConnector;
@property (copy) NSColor *bannerStartColor;	// lightest gradient color - top
@property (copy) NSColor *bannerMidColor;		// mid hue color
@property (copy) NSColor *bannerEndColor;		// darkest color

- (void)subviewClicked:(NSView *)aView;

@end

