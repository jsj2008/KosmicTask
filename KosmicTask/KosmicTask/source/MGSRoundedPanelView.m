//
//  MGSRoundedPanelView.m
//  Mother
//
//  Created by Jonathan on 23/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "mlog.h"
#import "MGSRoundedPanelView.h"
#import "NSApplication_Mugginsoft.h"

@interface MGSRoundedPanelView ()
- (void)drawRectForParameterStyle:(NSRect)aRect;
@end

@interface MGSRoundedPanelView (Private)
- (void)appendFooterPath:(NSBezierPath *)bp;
@end

const char MGSContextFirstResponder;

//#define OBSERVE_FIRST_RESPONDER

@implementation MGSRoundedPanelView

/*Initializing View Instances Created in Interface Builder
 View instances that are created in Interface Builder don't call initWithFrame: when their nib files are loaded, 
 which often causes confusion. Remember that Interface Builder archives an object when it saves a nib file, 
 so the view instance will already have been created and initWithFrame: will already have been called.
 
 The awakeFromNib method provides an opportunity to provide initialization of a view when it is created as 
 a result of a nib file being loaded. When a nib file that contains a view object is loaded, each view 
 instance receives an awakeFromNib message when all the objects have been unarchived. 
 This provides the object an opportunity to initialize any attributes that are not archived with 
 the object in Interface Builder. The DraggableItemView class is extremely simple, and doesn't implement awakeFromNib.
 
 There are two exceptions to the initWithFrame: behavior when creating view instances in Interface Builder. 
 Its important to understand these exceptions to ensure that your views initialize properly.
 
 If you have not created an Interface Builder palette for your custom view, there are two techniques
 you can use to create instances of your subclass within Interface Builder. The first is using the Custom 
 View proxy item in the Interface Builder containers palette. This view is a stand-in for your custom view,
 allowing you to position and size the view relative to other views. You then specify the subclass of NSView 
 that the view represents using the inspector. When the nib file is loaded by the application, the custom view
 proxy creates a new instance of the specified view subclass and initializes it using the initWithFrame: method,
 passing along any autoresizing flags as necessary. The view instance then receives an awakeFromNib message.
 
 The second technique is to specify a custom class is used when your custom view subclass inherits from a view
 that Interface Builder provides support for directly. For example, you can create an NSScrollView instance in
 Interface Builder and specify that a custom subclass (MyScrollView) should be used instead, again using the inspector.
 In this case, when the nib file is loaded by the application, the view instance has already been created and the 
 MyScrollView implementation of initWithFrame: is never called. 
 The MyScrollView instance receives an awakeFromNib message and can configure itself accordingly.
 */

@synthesize delegate;
@synthesize isHighlighted = _isHighlighted;
@synthesize isDragTarget = _isDragTarget;
@synthesize drawFooter = _drawFooter;
@synthesize footerHeight = _footerHeight;
@synthesize bannerHeight = _bannerHeight;
@synthesize maxXMargin = _maxXMargin;
@synthesize minXMargin = _minXMargin;
@synthesize minYMargin = _minYMargin;
@synthesize maxYMargin = _maxYMargin;
@synthesize hasConnector = _hasConnector;
@synthesize bannerStartColor = _bannerStartColor;
@synthesize bannerMidColor = _bannerMidColor;
@synthesize bannerEndColor = _bannerEndColor;
@synthesize panelStyle = _panelStyle;

/*
 
 + highlightColor
 
 */
+ (NSColor *)highlightColor
{
    return [NSColor colorWithCalibratedRed:0.953f green:0.275f blue:0.282f alpha:0.8f];
}

/*
 
 + dragTargetOutlineColor
 
 */
+ (NSColor *)dragTargetOutlineColor
{
    return [NSColor colorWithCalibratedRed:0.275f green:0.953f blue:0.282f alpha:0.8f];
}
/*
 
 init with frame
 
 */
- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		
		[self setShowDragRect:YES];
		_gradientType = MGSViewGradientBanner;
		_isHighlighted = NO;
		_drawFooter = NO;
		_wasFirstResponder = NO;
		_observeFirstResponder = NO;
		_footerHeight = 30.0f;
		_maxXMargin = 8;
		_minXMargin = 8;
		_minYMargin = 13;
		_maxYMargin = 1;
		_bannerHeight = 25.0f;
		_hasConnector = NO;
		_bannerStartColor = [NSColor colorWithCalibratedRed:0.83f green:0.83f blue:0.83f alpha:1.0f];
		_bannerMidColor = [NSColor colorWithCalibratedRed:0.875f green:0.875f blue:0.875f alpha:1.0f];
		_bannerEndColor = [NSColor colorWithCalibratedRed:0.800f green:0.800f blue:0.800f alpha:1.0f];	
        _panelStyle = kMGSRoundedPanelViewStyleParameter;
        
#ifdef OBSERVE_FIRST_RESPONDER 		

		NSUInteger major, minor, bugfix;
		[NSApplication getSystemVersionMajor:&major minor:&minor bugFix:&bugfix];
		
		if (major >= 10 && minor >= 6) {
			_observeFirstResponder = YES;
		}
#endif
		
	}
	return self;
}

/*
 
 draw rect
 
 NSView override
 
 note when drawing 1 pixel antialiased lines:
 
 see: http://www.cocoabuilder.com/archive/message/cocoa/2008/4/17/204399
 
 Because strokes are drawn centred on the coordinate of the path, 
 so a 1-pixel line extends 0.5 of a pixel above and below the coordinate. 
 Offsetting by 0.5 makes it draw such that the exact pixel is filled.
 
 Graham Cox wrote:
 Offsetting by 0.5 makes it draw such that the exact pixel is filled.
 
 When a bezier path is more complicated it can become very ugly to add 0.5 to all coordinates.
 To avoid this the NSBezierPath class offers the method - transformUsingAffineTransform: 
 So you can create a bezier path "as usual" and before rendering (stroke etc.) you
 apply a tranformation:
 
 NSBezierPath *bezierPath = [NSBezierPath bezierPath];
 NSAffineTransform *transform = [NSAffineTransform transform];
 // build the bezierPath
 [transform translateXBy: 0.5 yBy: 0.5];
 [bezierPath transformUsingAffineTransform: transform];
 [bezierPath stroke];
 
 And: if the bezier path shall always be drawn 1 pixel wide, independent
 */
- (void)drawRect:(NSRect)aRect
{
	#pragma unused(aRect)
	
    switch (_panelStyle) {
 
        case kMGSRoundedPanelViewStyleEmptyParameter:
            [[NSColor whiteColor] set];
            NSRectFill(aRect);
        break;
    
        default:
        case kMGSRoundedPanelViewStyleParameter:
            [self drawRectForParameterStyle:aRect];
            break;
    }
}	

/*
 
 - drawRectForParameterStyle:
 
 */
- (void)drawRectForParameterStyle:(NSRect)aRect
{
    #pragma unused(aRect)
    
	NSGraphicsContext* gc = [NSGraphicsContext currentContext];
	[gc setShouldAntialias:YES];
	
	// want to offset by 0.5 to get single antialiased lines on path
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform translateXBy: 0.5f yBy: 0.5f];
	
	// ignore the rect arg and redraw entire control background
	// using aRect here was causing a morning wasting problem
	// though I did get to investigate subclassing NSButton, NSControl and NSButtonCell!
	NSRect bgRect = [self bounds];
	float radius = 15.0f;
	
	
	_minX = NSMinX(bgRect);
	_midX = NSMidX(bgRect);
	_maxX = NSMaxX(bgRect);
	_minY = NSMinY(bgRect);
	//CGFloat midY = NSMidY(bgRect);
	_maxY = NSMaxY(bgRect);
	
	_maxX -= _maxXMargin;
	_minX += _minXMargin;
	_minY += _minYMargin;
	_maxY -= _maxYMargin;
	
	CGFloat bannerHeight = 25.0f;
	CGFloat bannerY = _maxY - bannerHeight;
    
	// declare points to be used for body
	_bodyLeftBottom = NSMakePoint(_minX, _minY);
	_bodyRightBottom = NSMakePoint(_maxX, _minY);
	
	//=============================
	// define view top banner path
	//=============================
	NSBezierPath *bgBannerPath = [NSBezierPath bezierPath];
	_bannerRightBottom = NSMakePoint(_maxX, bannerY);
	_bannerMiddleTop = NSMakePoint(_midX, _maxY);
	_bannerLeftBottom = NSMakePoint(_minX, bannerY);
	
	// Right edge and top-right curve
	[bgBannerPath moveToPoint:_bannerRightBottom];
	[bgBannerPath appendBezierPathWithArcFromPoint:NSMakePoint(_maxX, _maxY)
										   toPoint:_bannerMiddleTop
											radius:radius];
	
	// Top edge and top-left curve
	[bgBannerPath appendBezierPathWithArcFromPoint:NSMakePoint(_minX, _maxY)
										   toPoint:_bannerLeftBottom
											radius:radius];
	
	[bgBannerPath lineToPoint:_bannerLeftBottom];	// arc does not extend to toPoint
	NSBezierPath *bgBannerOutlinePath = [bgBannerPath copy];		// use as top of our outline
	[bgBannerPath closePath];
	[bgBannerPath transformUsingAffineTransform: transform];
    
	//===============================
	// define view bottom footer path
	//===============================
	NSBezierPath *bgFooterPath = nil;
	// declare points to be used for footer
	_footerLeftTop = NSMakePoint(_minX, _footerHeight);
	_footerRightTop = NSMakePoint(_maxX, _footerHeight);
    
	
	bgFooterPath = [NSBezierPath bezierPath];
	[bgFooterPath moveToPoint:_footerLeftTop];
	[self appendFooterPath:bgFooterPath];
	[bgFooterPath closePath];
	[bgFooterPath transformUsingAffineTransform: transform];
	
	//===========================
	// define view outline path
	//===========================
	NSBezierPath *bgOutlinePath = [NSBezierPath bezierPath];
	[bgOutlinePath appendBezierPath:bgBannerOutlinePath];	// start with banner outline
	[bgOutlinePath lineToPoint:_footerLeftTop];
	[self appendFooterPath:bgOutlinePath]; // append the footer path
	[bgOutlinePath closePath];
	[bgOutlinePath transformUsingAffineTransform: transform];
	
	
	//================================
	// draw outline and shadow
	//================================
	
	// prepare to receive shadow
	[gc saveGraphicsState];
	
	// Create the shadow
	NSShadow* theShadow = [[NSShadow alloc] init];
	[theShadow setShadowOffset:NSMakeSize(0, -4)];
	[theShadow setShadowBlurRadius:4.0f];
	
	// Use a partially transparent color for shapes that overlap.
	[theShadow setShadowColor:[[NSColor blackColor]
							   colorWithAlphaComponent:0.3f]];
	
	[theShadow set];
	
	// fill the outline.
	// the shadow will be automatically applied
	NSColor *fillColor = [NSColor colorWithCalibratedRed:0.961f green:0.961f blue:0.961f alpha:1.0f];
	[fillColor set];
	[bgOutlinePath fill];
	
	// restore state - remove shadow
	[gc restoreGraphicsState];
    
	// draw outline border
	NSColor *borderColor = [NSColor colorWithCalibratedRed:0.502f green:0.502f blue:0.502f alpha:1.0f];
	[borderColor set];
	[bgOutlinePath stroke];
	
	
	//================================
	// draw the footer
	//================================
	if (_drawFooter) {
		NSColor *footerColor = [NSColor colorWithCalibratedRed:0.902f green:0.902f blue:0.902f alpha:1.0f];
		[footerColor set];
		[bgFooterPath fill];
		
		// footer gradient colors
		NSColor *footerStart = [NSColor colorWithCalibratedRed:0.769f green:0.769f blue:0.769f alpha:1.0f];
		NSColor *footerEnd = footerColor;
		
		// draw gradient under footer
		NSRect footerGradientRect = NSMakeRect(_footerLeftTop.x, _footerLeftTop.y - 4, _footerRightTop.x - _footerLeftTop.x, 4);
		NSGradient *footerGradient = [[NSGradient alloc] initWithColorsAndLocations:footerStart, (CGFloat)0.0,
									  footerEnd, (CGFloat)1.0,
									  nil];
		[footerGradient drawInRect:footerGradientRect angle:-90];
        
		// draw footer border
		[borderColor set];
		[bgFooterPath stroke];
	}
	
	//================================
	// draw banner
	//================================
	// fill banner
	NSGradient *gradient = [[NSGradient alloc] initWithColorsAndLocations:_bannerStartColor, (CGFloat)0.0,
							_bannerMidColor, (CGFloat)0.5,
							_bannerEndColor, (CGFloat)0.55,
							_bannerMidColor, (CGFloat)1.0,
							nil];
	[gradient drawInBezierPath:bgBannerPath angle:-90.0f];
	
	// draw banner border
	[borderColor set];
	[bgBannerPath stroke];
	
	//================================
	// draw outline
	//================================
	if (_isHighlighted || _isDragTarget) {
		NSColor *highlightColor = nil;
        
        if (_isHighlighted) {
            highlightColor = [[self class] highlightColor];
        }
        
        if (_isDragTarget) {
            highlightColor = [[self class] dragTargetOutlineColor];
        }
        
		[bgOutlinePath setLineWidth:3];
		[highlightColor set];
		[bgOutlinePath stroke];
	}
    
}
/*
 
 is highlighted
 
 */
- (void)setIsHighlighted:(BOOL)value
{
	_isHighlighted = value;
	[self setNeedsDisplay:YES];
}

/*
 
 - setIsDragTarget:
 
 */
- (void)setIsDragTarget:(BOOL)value
{
	_isDragTarget = value;
	[self setNeedsDisplay:YES];
}

/*
 
 draw footer
 
 */
- (void)setDrawFooter:(BOOL)value
{
	_drawFooter = value;
	[self setNeedsDisplay:YES];
}
/*
 
 - mouseDown:
 
 */
- (void)mouseDown:(NSEvent *)theEvent
{	
	if (delegate && [delegate respondsToSelector:@selector(mouseDown:)]) {
		[delegate mouseDown:theEvent];
	}
	
	// pass on up the responder chain
	[super mouseDown:theEvent];
}

/*
 
 - mouseUp:
 
 */
- (void)mouseUp:(NSEvent *)theEvent
{
	if (delegate && [delegate respondsToSelector:@selector(mouseUp:)]) {
		[delegate mouseUp:theEvent];
	}
	
	// pass on up the responder chain
	[super mouseUp:theEvent];
}

/*
 
 - mouseDragged:
 
 */
- (void)mouseDragged:(NSEvent *)theEvent
{
	if (delegate && [delegate respondsToSelector:@selector(mouseDragged:)]) {
		[delegate mouseDragged:theEvent];
	}
	
	// pass on up the responder chain
	[super mouseDragged:theEvent];
}

/*
 
 footer height
 
 */
- (void)setFooterHeight:(CGFloat)height
{
	_footerHeight = height;
	[self setNeedsDisplay:YES];
}

/*
 
 view did move to window
 
 */
- (void)viewDidMoveToWindow
{
	
	// we want to track clicking/activation of subviews
#ifndef OBSERVE_FIRST_RESPONDER	
	
		if ([self window]) {
			if ([[self window] respondsToSelector:@selector(addClickView:)]) {
				[(id)[self window] addClickView:self];
			}
		}
	
#else
		NSWindow *window = nil;

		// first responder is KVO compliant on 10.6 and above
		if (!_observeFirstResponder) return;
		
		if ([self window]) {
			
			[[self window] addObserver:self forKeyPath:@"firstResponder" options:NSKeyValueObservingOptionNew context:(void *)&MGSContextFirstResponder];
		} else {
			if (window) {
				@try {
					[window removeObserver:self forKeyPath:@"firstResponder"];
				}
				@catch (NSException * e) {
					MLogInfo(@"Exception: %@", [e reason]);
				}
			}
		}
	}
#endif

	[super viewDidMoveToWindow];
}

/*
 
 subview clicked
 
 */
- (void)subviewClicked:(NSView *)aView 
{
	#pragma unused(aView)
	
	if (delegate && [delegate respondsToSelector:@selector(subviewClicked:)]) {
		[delegate subviewClicked:aView];
	}
}

#pragma mark -
#pragma mark Accessors

/*
 
 - setPanelStyle:
 
 */
- (void)setPanelStyle:(MGSRoundedPanelViewStyle)panelStyle
{
    _panelStyle = panelStyle;
    [self setNeedsDisplay:YES];
}
#pragma mark -
#pragma mark KVO

/*
 
 observe value for key path
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	#pragma unused(keyPath)
	#pragma unused(object)
	#pragma unused(change)
			
	if (context == &MGSContextFirstResponder) {
		
		NSResponder *firstResponder = [[self window] firstResponder];
		
		if (![firstResponder isKindOfClass:[NSView class]]) {
			if (_wasFirstResponder || _isHighlighted) {
				_wasFirstResponder = NO;
				[self setIsHighlighted:NO];
			}
			return;
		}
		
		if ([(NSView *)firstResponder isDescendantOf:self]) {
			if (!_wasFirstResponder) {
				_wasFirstResponder = YES;
				[self setIsHighlighted:YES];
			}
		} else {
			if (_wasFirstResponder || _isHighlighted) {
				_wasFirstResponder = NO;
				[self setIsHighlighted:NO];
			} 
		}
	}
	
	
}
@end

@implementation MGSRoundedPanelView (Private)
/*
 
 append footer path
 
 */
- (void)appendFooterPath:(NSBezierPath *)bp
{
	CGFloat connectorWidth = 30;
	
	NSPoint footerConnectorLeft, footerConnectorMiddle, footerConnectorRight;
	footerConnectorLeft = NSMakePoint(_midX - connectorWidth/2, _minY);
	footerConnectorMiddle = NSMakePoint(_midX, _minY - 6);
	footerConnectorRight = NSMakePoint(_midX + connectorWidth/2, _minY);
	
	[bp appendBezierPathWithArcFromPoint:_bodyLeftBottom 
										   toPoint:footerConnectorLeft 
											radius:3];
	
	// define connector path
	if (_hasConnector) {
		[bp lineToPoint:footerConnectorLeft];
		[bp lineToPoint:footerConnectorMiddle];
		[bp lineToPoint:footerConnectorRight];
	}
	
	[bp appendBezierPathWithArcFromPoint:_bodyRightBottom 
										   toPoint:_footerRightTop 
											radius:3];	
	[bp lineToPoint:_footerRightTop];
}
@end

