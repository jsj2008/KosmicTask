//
//  MGSActionActivityView.m
//  Mother
//
//  Created by Jonathan on 16/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
//
// Progress indicator code based on:
//
//  AMIndeterminateProgressIndicatorCell.m
//  IPICellTest
//
//  Created by Andreas on 23.01.07.
//  Copyright 2007 Andreas Mayer. All rights reserved.
//

//	2007-03-10	Andreas Mayer
//	- removed -keyEquivalent and -keyEquivalentModifierMask methods
//		(I thought those were required by NSTableView/Column. They are not.
//		Instead I was using NSButtons as a container for the cells in the demo project.
//		Replacing those with plain NSControls did fix the problem.)
//	2007-03-24	Andreas Mayer
//	- will now spin in the same direction in flipped and not flipped views
#import "MGSMother.h"
#import "MGSAppController.h"
#import "MGSActionActivityView.h"
#import "NSPointFunctions_CocoaDevUsersAdditions.h"
#import "GlossyGradient.h"
#import "NSString_Mugginsoft.h"
#import "NSString_Bezier_Mugginsoft.h"
#import "MGSTextView.h"
#import "MGSActionActivityTextView.h"
#import <Quartz/Quartz.h>

#define MGS_VIEW_DEBUG
#define MGS_VIEW_WANTS_LAYER NO

#define ConvertAngle(a) (fmod((90.0-(a)), 360.0))

#define MASTER_ALPHA_MAX 1.000f
#define MASTER_ALPHA_MIN 0.101f

#define DEG2RAD  0.017453292519943295f
#define MAX_BLEND_RADIUS 3.0f

#define SS_ROUND_PROGRESS 0
#define SS_CIRCLE_DOTS 1

enum _mgsFadeType {
    kMGSFadeTypeIn,
    kMGSFadeTypeOut
} typedef mgsFadeType;

NSPoint MGSMakePointWithPolarOffset(NSPoint pt0, CGFloat radius, CGFloat radians) {
	NSPoint pt = NSMakePoint(pt0.x, pt0.y);
	
	pt.x += radius * cosf(radians);
	pt.y += radius * sinf(radians);
	
	return pt;
}

// class extension
@interface MGSActionActivityView()
- (NSColor *)alphaColor:(NSColor *)color;
- (void)alphaTimerExpired:(NSTimer*)theTimer;
-(BOOL)ispoint:(NSPoint)aPoint inCircleWithCenter:(NSPoint)aCenter radius:(CGFloat)aRadius;
- (BOOL)isEventInCircle:(NSEvent *)theEvent;
- (BOOL)viewIsDimmed;
- (void)scheduleFade:(mgsFadeType)fade;
- (BOOL)isMouseInCircle;
- (BOOL)hasText;
- (void)scrollContentBoundsChanged:(NSNotification *)note;
@end

@interface MGSActionActivityView (Private)
- (void)drawPausedInRect:(NSRect)rect;
- (void)drawReadyInRect:(NSRect)rect;
- (void)drawProcessingInRect:(NSRect)rect;
- (void)saveBezierState;
- (void)restoreBezierState;
- (void)drawCentreInRect:(NSRect)rect;
- (void)drawTerminatedInRect:(NSRect)rect;
- (void)drawUnavailableInRect:(NSRect)rect;
- (NSRect)validateDrawRect:(NSRect)rect;
- (void)drawRectFromCache:(NSRect)rect;
- (void)drawSpinner;
- (void)updateAnimatedRect;
@end


@implementation MGSActionActivityView


@synthesize activity = _activity;
@synthesize backgroundFillColor = _backgroundFillColor;
@synthesize foregroundColor = _fillColor;
@synthesize hasDropShadow = _hasDropShadow;
@synthesize target, action, runMode = _runMode, respectRunMode = _respectRunMode, delegate = _delegate;

#pragma mark -
#pragma mark initialisation
/*
 
 init with frame
 
 */
- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		[self initialise];
		
		_hasDropShadow = YES;
    }
    return self;
}


/*
 
 init with coder
 
 */

- (id)initWithCoder:(NSCoder *)aCoder
{
	self = [super initWithCoder:aCoder];
	[self initialise];
	return self;
}

/*
 
 initialise
 
 */
- (void)initialise
{
	_activity = MGSReadyTaskActivity;
	_runMode = kMGSMotherRunModePublic;
	_respectRunMode = YES;
	_canClick = YES;
	
	[self setDisplayedWhenStopped:YES];
	[self setDoubleValue:0.0];
	_backgroundFillColor = [NSColor colorWithCalibratedRed:0.988f green:0.988f blue:0.988f alpha:1.0f];
	_fillColor = [NSColor colorWithCalibratedWhite:(float)MIN(sqrt(3)*0.25, 0.8) alpha:1.0f];
	_centreColor = _fillColor;

	_depressedBackgroundColor = [NSColor colorWithCalibratedRed:0.8f green:0.8f blue:0.8f alpha:1.0f];

	// default centre colour gradient
	_centreColorGradientEnd = [NSColor colorWithCalibratedRed:0.066f green:0.541f blue:0.871f alpha:0.7f];
	_centreColorGradientStart = [NSColor colorWithCalibratedRed:0.082f green:0.325f blue:0.666f alpha:0.7f];
	_centreGradient = [[NSGradient alloc] initWithStartingColor:_centreColorGradientStart endingColor:_centreColorGradientEnd];
	
	// active centre colour gradient
	_centreColorActiveGradientEnd = [NSColor colorWithCalibratedRed:0.588f green:0.788f blue:0.0f alpha:0.9f];
	_centreColorActiveGradientStart = [NSColor colorWithCalibratedRed:0.412f green:0.675f blue:0.0f alpha:0.9f];
	_centreGradientHighlight = [[NSGradient alloc] initWithStartingColor:_centreColorActiveGradientStart endingColor:_centreColorActiveGradientEnd];

	// alt centre colour gradient
	_centreColorAltGradientEnd = [NSColor colorWithCalibratedRed:0.914f green:0.000f blue:0.196f alpha:0.7f];
	_centreColorAltGradientStart = [NSColor colorWithCalibratedRed:0.608f green:0.000f blue:0.102f alpha:0.7f];
	_centreGradientAlt = [[NSGradient alloc] initWithStartingColor:_centreColorAltGradientStart endingColor:_centreColorAltGradientEnd];
	
	_pausedSpinnerColor = [NSColor colorWithCalibratedRed:0.7f green:0.0f blue:0.0f alpha:0.9f];
	_spinnerColor = [NSColor whiteColor];
	_bezierPath = [NSBezierPath bezierPath];
	
	//[self setAnimationDelay:5.0/60.0];
	//_spinnerStyle = SS_ROUND_PROGRESS;
	
	_spinnerStyle = SS_CIRCLE_DOTS;
	[self setAnimationDelay:5.0/5.0];
	
	[self clearDisplayCache];
	_useImageCache = NO;
	
	
	// in docs see "Using Tracking-Area Objects".
    // this view probably won't be the first responder hence the need for
    // NSTrackingActiveAlways
	_trackingArea = [[NSTrackingArea alloc] initWithRect:[self frame]
												options: (NSTrackingMouseEnteredAndExited | 
                                                          NSTrackingMouseMoved |
														  NSTrackingActiveWhenFirstResponder |
														  NSTrackingActiveInKeyWindow |
														  NSTrackingActiveInActiveApp |
                                                          NSTrackingInVisibleRect |
                                                          NSTrackingActiveAlways)
												  owner:self userInfo:nil];
	[self addTrackingArea:_trackingArea];
	
	_shadowSize = NSMakeSize(0, -4);
	
	// send nil targeted action to toggle run state
	[self setTarget:nil];
	[self setAction:@selector(toggleRunState:)];
       
    _masterAlpha = 1.0f;
    
    _useLayers = MGS_VIEW_WANTS_LAYER;
}

#pragma mark -
#pragma mark Text display
/*
 
 - textView
 
 */
- (MGSTextView *)textView
{
    // lazy allocation
    if (!_textView) {
             
        // we may be a subclass ?
        if ([self isKindOfClass:[NSTextView class]]) {
            _textView = (id)self;
        }
        // if we are embedded in a textview use it
        else if ([[self superview] isKindOfClass:[NSTextView class]]) {
            
            // get the text view
            _textView = (id)[self superview];
            
            // set scrollview background drawing behaviour
            [[self enclosingScrollView] setDrawsBackground:NO];
            
            // observe changes to the scrollview content bounds.
            // see "How Scroll Views Work" in the docs
            [[[self enclosingScrollView] contentView] setPostsBoundsChangedNotifications:YES];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollContentBoundsChanged:) name:NSViewBoundsDidChangeNotification object:[[self enclosingScrollView] contentView]];
            
            // turn on layer backed views for this view
            // and all subviews.
            //
            // this works up to a point but the cpu usage can be very high
            if (NO) {
                [_textView setWantsLayer:YES];
            }

            // add a filter
            if (_useLayers) {
                
                // create layer for textview and all subviews
                [_textView setWantsLayer:YES];

                // this works but the overhead is high - cpu usage increase from 4 -> 40%
                CIFilter *filter = [CIFilter filterWithName:@"CIColorBurnBlendMode"];
                [self setCompositingFilter:filter];
            }

        } 
        // add an NSTextView Subclass
        else {
             
            /*
             
             we add a transparent textview + scroll as sub views of the activity view
             
             */
            
            // configure the scroll view 
            NSRect scrollFrame = [self frame];
            scrollFrame.origin.x = 0;
            scrollFrame.origin.y = 0;
            
            _textScrollview = [[NSScrollView alloc] initWithFrame:scrollFrame];
            NSSize contentSize = [_textScrollview contentSize];
            
            // create and configure scroll view
            [_textScrollview setBorderType:NSNoBorder];
            [_textScrollview setHasVerticalScroller:YES];
            [_textScrollview setHasHorizontalScroller:NO];
            [_textScrollview setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
            [_textScrollview setDrawsBackground:NO];
            
            // create and configure text view
            _textView = [[MGSActionActivityTextView alloc] initWithFrame:NSMakeRect(0, 0,
                                                                       contentSize.width, contentSize.height)];
            [_textView setMinSize:NSMakeSize(0.0, 0.0)];
            [_textView setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
            [_textView setVerticallyResizable:YES];
            [_textView setHorizontallyResizable:NO];
            [_textView setAutoresizingMask:NSViewWidthSizable];
            [[_textView textContainer] setContainerSize:NSMakeSize(contentSize.width, FLT_MAX)];
            [[_textView textContainer] setWidthTracksTextView:YES];
            
            // if not selectable or editable then mouse events pass through to superview
            [_textView setEditable:NO];
            [_textView setSelectable:NO];
            
            // add text view to scroll view
            [_textScrollview setDocumentView:_textView];
            
            // add scrollview as subview
            [self addSubview:_textScrollview];
                   
            // use layers?
            if (_useLayers) {
                
                // create layer for textview and all subviews
                [self setWantsLayer:YES];
                
                // add a filter
                // this works but the overhead is high - cpu usage increase from 4 -> 40%
                CIFilter *filter = [CIFilter filterWithName:@"CIColorBurnBlendMode"];
                [_textScrollview setCompositingFilter:filter];
            }
        }
    }
    return _textView; 
}

/*
 
 - appendText
 
 */
- (void)appendText:(NSString *)text
{
    
    // if our text view is empty then
    // fade out the activity view if mouse not in circle
    if (![self hasText] ) {       
        
        BOOL mouseInCircle = [self isMouseInCircle];

        if (!mouseInCircle) {
            [self scheduleFade:kMGSFadeTypeOut];
        }
        
        // set scroller to end
        [[[self enclosingScrollView] verticalScroller] setFloatValue:1.0];
    } 
    
    // append text
    [self.textView setText:text append:YES options:nil];
}

/*
 
 - clearText
 
 */
- (void)clearText
{
    if (_textView) {
        [_textView setString:@""];
        _masterAlpha = 1.0f;
    }
    //[self setAlphaValue:1.0]; 
}

/*
 
 - hasText
 
 */
- (BOOL)hasText
{
    if (_textView && [[_textView string] length] > 0) {
        return YES;
    }
    
    return NO;
}

/*
 
 - scrollContentBoundsChanged:
 
 */
- (void)scrollContentBoundsChanged:(NSNotification *)note
{
    #pragma unused(note)

    // set our frame equal to the document visible rect
    NSRect viewRect = [[_textView enclosingScrollView] documentVisibleRect];   
    [self setFrame:viewRect];
    
#ifdef MGS_VIEW_DEBUG
    NSLog(@"document view visible rect: x=%f y=%f width=%f height=%f", viewRect.origin.x, viewRect.origin.y, viewRect.size.width, viewRect.size.height);
    
    viewRect = [_textView frame];
    NSLog(@"text view frame rect: x=%f y=%f width=%f height=%f", viewRect.origin.x, viewRect.origin.y, viewRect.size.width, viewRect.size.height);
#endif
}
#pragma mark -
#pragma mark NSView
/*
 
 is opaque
 
 */
- (BOOL)isOpaque
{
	return NO;
}


/*
 
 view did move to window
 
 */
- (void)viewDidMoveToWindow
{
	if (_delegate) {
		[_delegate viewDidMoveToWindow];
	}
}

/*
 
 we want to accept first responder status and respond to events and actions
 
 */
- (BOOL)acceptsFirstResponder {
    return YES;
}

#pragma mark -
#pragma mark Hit testing
/*
 
 - ispoint:inCircleWithCenter:radius
 
 */
-(BOOL)ispoint:(NSPoint)aPoint inCircleWithCenter:(NSPoint)aCenter radius:(CGFloat)aRadius 
{
    CGFloat squareDistance = (aCenter.x - aPoint.x) * (aCenter.x - aPoint.x) +
    (aCenter.y - aPoint.y) * (aCenter.y - aPoint.y);
    return squareDistance <= aRadius * aRadius;
}

/*
 
 - isEventInCircle:
 
 */
- (BOOL)isEventInCircle:(NSEvent *)theEvent 
{
    NSPoint event_location = [theEvent locationInWindow];
    NSPoint local_point = [self convertPoint:event_location fromView:nil];
        
    return [self ispoint:local_point inCircleWithCenter:_centerPoint radius:_outerRadius];
}

/*
 
 - isMouseInCircle
 
 */
- (BOOL)isMouseInCircle
{

    if (![self window]) {
        return NO;
    }
    
    NSPoint mouse_location = [[self window] mouseLocationOutsideOfEventStream];
    NSPoint local_point = [self convertPoint:mouse_location fromView:nil];
    
    return [self ispoint:local_point inCircleWithCenter:_centerPoint radius:_outerRadius];
}

#pragma mark -
#pragma mark NSView mouse
/*
 
 we want to accept first mouse event
 
 */
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	#pragma unused(theEvent)
    return YES;
}


/*
 
 mouse down
 
 */
- (void)mouseDown:(NSEvent *)theEvent 
{
	#pragma unused(theEvent)
	
	if (!_canClick) {
		return;
	}
	
    // detect if we have clicked within the circle
    if ([self isEventInCircle:theEvent]) {
        _useImageCache = NO; // dump the cache otherwise no redraw
        _depressed = YES;
        [self setNeedsDisplay:YES];
        [self displayIfNeeded];
    }
}

/*
 
 mouse up
 
 */
- (void)mouseUp:(NSEvent *)theEvent 
{
	#pragma unused(theEvent)
	
	if (!_canClick) {
		return;
	}
	
	_depressed = NO;
	[self setNeedsDisplay:YES];
    [self displayIfNeeded];
    
    // send the action if appropriate
    if ([self isEventInCircle:theEvent]) {
        [NSApp sendAction:[self action] to:[self target] from:[self window]];
    }
}

#pragma mark -
#pragma mark NSTrackingArea mouse
/*
 
 mouse entered
 
 */
- (void)mouseEntered:(NSEvent *)theEvent 
{
#pragma unused(theEvent)
    
}

/*
 
 mouse moved
 
 */
- (void)mouseMoved:(NSEvent *)theEvent 
{
    // check if mouse is in circle
    BOOL mouseIsInCircle = [self isEventInCircle:theEvent];

    // is text displayed?
    if ([self hasText]) {
        
        // if view is dimmed
        if ([self viewIsDimmed]) {
            
            // if mouse within circle
            if (mouseIsInCircle) {
                
                // fade the view in
                [self scheduleFade:kMGSFadeTypeIn];
            } 
        } else {
            
            // mouse is outside circle
            if (!mouseIsInCircle) {
                
                // fade the view out
                [self scheduleFade:kMGSFadeTypeOut];
            }
        }
    }
    
    // update cursor
    if (YES) {
        NSCursor *cursor = nil;
        if (mouseIsInCircle) {
            if ([NSCursor currentCursor] != [NSCursor arrowCursor]) {
                cursor = [NSCursor arrowCursor];
            }
            [cursor set];
        } else {
            [[self superview] mouseMoved:theEvent];
        }
        
    }
    
    if (NO) {
        [self displayIfNeeded]; 
    }
}

/* 
 
 mouse exited
 
 */
- (void)mouseExited:(NSEvent *)theEvent 
{
#pragma unused(theEvent)
	
    if (NO) {
        [self setNeedsDisplay:YES];
        [self displayIfNeeded]; 
    }
}

#pragma mark -
#pragma mark Drawing
/*
 
 clear display cache
 
 */
- (void)clearDisplayCache
{
    
#ifdef MGS_VIEW_DEBUG
    NSLog(@"Invalidating display cache.");
#endif
    
	_cacheRect = NSZeroRect;
	_imageCache = nil;
}


/*
 
 draw rect
 
 On Mac OS X version 10.2 and earlier, 
 the Application Kit automatically clips any drawing you perform in this method to this rectangle. 
 
 On Mac OS X version 10.3 and later, the Application Kit automatically clips drawing to a list of 
 non-overlapping rectangles that more rigorously specify the area needing drawing. 
 You can invoke the getRectsBeingDrawn:count: method to retrieve this list of rectangles and use them to constrain your drawing more tightly, 
 if you wish. Moreover, the needsToDrawRect: 
 method gives you a convenient way to test individual objects for intersection with the rectangles in the list. 
 See Cocoa Drawing Guide for information and references on drawing.
 
 */
- (void)drawRect:(NSRect)rect 
{	
	//MLog(DEBUGLOG, @"%@: draw rect", [self className]);	
	
	if (_useImageCache) {
		
		// validate our rect
		rect = [self validateDrawRect:rect];

		// if cache exists use it to update rect.
		// otherwise draw into our rect
		if (_imageCache) {
			[self drawRectFromCache:rect];
			[self drawSpinner];
			return;
		} 

		// draw to image cache
		_cacheRect  = [self bounds];
		_imageCache = [[NSImage alloc] initWithSize:_cacheRect.size];
		[_imageCache lockFocus];
		
	}
	
	// draw entire bounds rect
	rect = [self bounds];
	
	// fill background
	if (1) {
		[_backgroundFillColor set];
		// NSRectFill(rect);
	} else {
		// gradient
		NSBezierPath *bgPath = [NSBezierPath bezierPathWithRect:rect];
		NSColor *endColor = [NSColor colorWithCalibratedRed:0.988f green:0.988f blue:0.988f alpha:1.0f];
		NSColor *startColor = [NSColor colorWithCalibratedRed:0.875f green:0.875f blue:0.875f alpha:1.0f];
		
		NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
		[gradient drawInBezierPath:bgPath angle:90.0f];
	}
	
	_minSize = MIN(rect.size.width, rect.size.height);
	_centerPoint = NSMakePoint(NSMidX(rect), NSMidY(rect));
	
	if (_minSize >= 32.0) {
		_outerRadius = _minSize*0.38f;
		_innerRadius = _minSize*0.23f;
	} else {
		_outerRadius = _minSize*0.48f;
		_innerRadius = _minSize*0.27f;
	}

	_circleRadius = (_outerRadius + _innerRadius) /2 ;
	_circleLineWidth = (_outerRadius - _innerRadius)/2;
	
	// prepare to receive shadow
	NSShadow* theShadow;
	
	// Create the shadow
	if (_hasDropShadow) {

		[[NSGraphicsContext currentContext] saveGraphicsState];
		
		theShadow = [[NSShadow alloc] init];
		[theShadow setShadowOffset: _shadowSize];
		[theShadow setShadowBlurRadius:4.0f];
		
		// Use a partially transparent color for shapes that overlap.
		[theShadow setShadowColor:[self alphaColor:[[NSColor blackColor]
								   colorWithAlphaComponent:0.3f]]];
		
		[theShadow set];
	}
	
	switch (_activity) {
			
		case MGSUnavailableTaskActivity:
			[self drawUnavailableInRect: rect];
			break;

		case MGSPausedTaskActivity:	
			[self drawPausedInRect: rect];
			break;
			
		case MGSProcessingTaskActivity:
			[self drawProcessingInRect: rect];
			break;
		
		case MGSTerminatedTaskActivity:
			[self drawTerminatedInRect: rect];
			break;
			
		case MGSReadyTaskActivity:
		default:
			[self drawReadyInRect: rect];
			break;
			
	}

	if (_hasDropShadow) {
		[[NSGraphicsContext currentContext] restoreGraphicsState];
	}
	
	if (_useImageCache) {
		[_imageCache unlockFocus];
		
		// refresh view from cache
		[self drawRectFromCache:rect];
	}
	
	// update and draw spinner
	[self updateAnimatedRect];
	[self drawSpinner];
}


/*
 
 is displayed when stopped
 
 */
- (BOOL)isDisplayedWhenStopped
{
	return displayedWhenStopped;
}

/*
 
 set displayed when stopped
 
 */
- (void)setDisplayedWhenStopped:(BOOL)value
{
	if (displayedWhenStopped != value) {
		displayedWhenStopped = value;
	}
}

/*
 
 is spinning
 
 */
- (BOOL)isSpinning
{
	return spinning;
}

/*
 
 set is spinning
 
 */
- (void)setSpinning:(BOOL)value
{
	if (spinning != value) {
		spinning = value;
		[self clearDisplayCache];
		[self setNeedsDisplay:YES];
	}
}

#pragma mark -
#pragma mark Color and alpha
/*
 
 - alphaColor:
 
 */
- (NSColor *)alphaColor:(NSColor *)color
{
    if (_masterAlpha > 0.99) {
        return color;
    }
    
    // we want don't want to darken whites
    if (NO) {
        CGFloat red, green, blue, alpha;
        
        // this method raises if the color is not registered with an NSColorSpace.
        [color getRed:&red green:&green blue:&blue alpha:&alpha];
        if (red > 0.8 && blue > 0.8 && green > 0.8) {
            return color;
        }
    }
    
    CGFloat newAlpha = _masterAlpha * [color alphaComponent];
    NSColor *paleColor = [color colorWithAlphaComponent:newAlpha];
    
    return paleColor;
}

/*
 
 - alphaTimerExpired:
 
 */
- (void)alphaTimerExpired:(NSTimer*)theTimer
{
   
    if ([self wantsLayer] && NO) {
       
        // change the backing layer alpha
        CGFloat layerAlpha = [[self layer] opacity];
        layerAlpha -= 0.1f;
        [self setAlphaValue:layerAlpha];
        
    } else {
        
        BOOL fadeComplete = NO;
        
        NSDictionary *fadeInfo = [theTimer userInfo];
        CGFloat startAlpha = [[fadeInfo objectForKey:@"startAlpha"] floatValue];
        CGFloat endAlpha = [[fadeInfo objectForKey:@"endAlpha"] floatValue];
        CGFloat alphaDelta = [[fadeInfo objectForKey:@"alphaDelta"] floatValue];
        
        // mutate the master alpha value
        if (startAlpha < endAlpha) {
            _masterAlpha += alphaDelta;
            if (_masterAlpha >= endAlpha) {
                fadeComplete = YES;
            }
        } else {
             _masterAlpha -= alphaDelta;
            if (_masterAlpha <= endAlpha) {
                fadeComplete = YES;
            }
        }
        
        // on fade completion
        if (fadeComplete) {
            
            // keep alpha within limits
            _masterAlpha = endAlpha;
            
            // invalidate the timer
            [theTimer invalidate];
            _alphaTimer = nil;
        }
        
        // we need to redraw the cache with the new master alpha applied
        [self clearDisplayCache];
        _useImageCache = false;   
        [self setNeedsDisplay:YES];
        
    }
}

/*
 
 - viewIsDimmed
 
 */
- (BOOL)viewIsDimmed
{
    return (_masterAlpha < 0.99f);
}


#pragma mark -
#pragma mark Animation
/*
 
 update animation
 
 */
- (void)updateAnimation
{
	// use the cache
	if (_useImageCache) {
		
		if (1) {
			// standard method
			// use invalidated rects
			[self setNeedsDisplayInRect:_animatedCircleRect];
			[self updateAnimatedRect];
			[self setNeedsDisplayInRect:_animatedCircleRect];
			[self displayIfNeeded];
		} else {
			// custom method
			// direct animation - some artefacts
			// seems to relate to size of rect being slightly larger
			// clip rect effect?
			// anyhow the graphics state is obbviously a bit different
			[self lockFocus];
			[[NSGraphicsContext currentContext] setShouldAntialias:NO];
			//NSRect rect  = NSMakeRect(_animatedCircleRect.origin.x-10, _animatedCircleRect.origin.y-10, _animatedCircleRect.size.width+20, _animatedCircleRect.size.height+20);
			//[self drawRectFromCache:rect];
			[self drawRectFromCache:_animatedCircleRect];
			[self updateAnimatedRect];
			[self drawSpinner];
			[[NSGraphicsContext currentContext] flushGraphics];
			[self unlockFocus];
		}
	} else {
		
		// update the whole view
		[self setNeedsDisplay:YES];
	}
}

/*
 
 animation delay
 
 */
- (NSTimeInterval)animationDelay
{
	return animationDelay;
}

/*
 
 set animation delay
 
 */
- (void)setAnimationDelay:(NSTimeInterval)value
{
	//if (animationDelay != value) {
    animationDelay = value;
	//}
}

/*
 
 - scheduleFade:
 
 */
- (void)scheduleFade:(mgsFadeType)fade
{
    // invalidate any existing timer
    if (_alphaTimer) {
        [_alphaTimer invalidate];
        _alphaTimer = nil;
    }
    
    // configure the fade
    CGFloat startAlpha = 1.0f, endAlpha = 1.0f;
    switch (fade) {
        case kMGSFadeTypeIn:
            
            // if already at max alpha then do not attempt fade
            if (_masterAlpha >= MASTER_ALPHA_MAX) return;
            
            // fade in from current alpha to max alpha
            startAlpha = _masterAlpha;
            endAlpha = MASTER_ALPHA_MAX;
            break;
            
        case kMGSFadeTypeOut:
            
            // if already at min alpha then do not attempt fade
            if (_masterAlpha <= MASTER_ALPHA_MIN) return;

            // fade out from current alpha to min alpha
            startAlpha = _masterAlpha;
            endAlpha = MASTER_ALPHA_MIN;

            break;
            
        default:
            NSAssert(NO, @"invalid fade type");
    }
    
    // build fade info
    NSDictionary *fadeInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithFloat:startAlpha], @"startAlpha", 
                [NSNumber numberWithFloat:endAlpha], @"endAlpha",
                [NSNumber numberWithFloat:0.1f], @"alphaDelta",
                nil];

    // schedule new timer
    _alphaTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(alphaTimerExpired:) userInfo:fadeInfo repeats:YES];
    
}
#pragma mark -
#pragma mark Accessors
/*
 
 -doubleValue
 
 */
- (double)doubleValue
{
	return doubleValue;
}

/*
 
 - setDoubleValue:
 
 */
- (void)setDoubleValue:(double)value
{
	//if (doubleValue != value) {
    doubleValue = value;
    if (doubleValue > 1.0) {
        doubleValue = 1.0;
    } else if (doubleValue < 0.0) {
        doubleValue = 0.0;
    }
	//}
}

/*
 
 set object value
 
 */
- (void)setObjectValue:(id)value
{
	if ([value respondsToSelector:@selector(boolValue)]) {
		[self setSpinning:[value boolValue]];
	} else {
		[self setSpinning:NO];
	}
}


/*
 
 set activity
 
 */
- (void)setActivity:(MGSTaskActivity)activity
{
	_activity = activity;
	[self clearDisplayCache];
	
	// image cache
	// only use cache for animated activities
	switch (_activity) {
		case MGSPausedTaskActivity:	
		case MGSProcessingTaskActivity:
			_useImageCache = YES;
			break;
			
		default:
			_useImageCache = NO;
			break;
			
	}
	
	switch (_activity) {
		case MGSUnavailableTaskActivity:	
			_canClick = NO;
			break;
			
		default:
			_canClick = YES;
			break;
	}
	
	[self setNeedsDisplay:YES];
}

/*
 
 set run mode
 
 */
- (void)setRunMode:(eMGSMotherRunMode)mode
{
	_runMode = mode;
	[self clearDisplayCache];
	[self setNeedsDisplay:YES];
}

@end

@implementation MGSActionActivityView (Private)

/*
 
 draw paused in rect
 
 */
- (void)drawPausedInRect:(NSRect)rect 
{
	[self drawCentreInRect:rect];
}


/*
 
 draw processing in rect
 
 */
- (void)drawProcessingInRect:(NSRect)rect 
{
	[self drawCentreInRect:rect];
}

/*
 
 draw terminated in rect
 
 */
- (void)drawTerminatedInRect:(NSRect)rect 
{
	[self drawCentreInRect:rect];
}


/*
 
 draw ready in rect
 
 */
- (void)drawReadyInRect:(NSRect)rect 
{
	[self drawCentreInRect:rect];
}
/*
 
 draw unavailable in rect
 
 */
- (void)drawUnavailableInRect:(NSRect)rect 
{
	[self drawCentreInRect:rect];
}

/*
 
 draw centre in rect
 
 */
- (void)drawCentreInRect:(NSRect)rect 
{
	#pragma unused(rect)
	
	[_bezierPath appendBezierPathWithOvalInRect:NSMakeRect(_centerPoint.x - _circleRadius, _centerPoint.y - _circleRadius, 2 * _circleRadius, 2 * _circleRadius)];

	if (_depressed) {
		[_depressedBackgroundColor set];
		[_bezierPath fill];
	}
	
	[[self alphaColor:_fillColor] set];
	[self saveBezierState];

	// draw circle
	[_bezierPath setLineWidth:_circleLineWidth];
	[_bezierPath stroke];
	[self restoreBezierState];
	
	
	[[self alphaColor:_centreColor] set];
	
	// compute points
	CGFloat xOrigin = _centerPoint.x;
	CGFloat yOrigin = _centerPoint.y;
	
	
	// compute equilateral triangle pt0, pt2, pt3
	CGFloat r = _innerRadius * 0.66f;
	NSPoint pt0, pt1, pt2, pt3, pt4;	
	NSPoint pt5, pt6, pt7, pt8, pt9;
	CGFloat width;
	
	// compute corner blend radius
	CGFloat blendRadius = r/15;
	if (blendRadius > MAX_BLEND_RADIUS) blendRadius = MAX_BLEND_RADIUS;
	
	// setup gradients
	NSGradient *gradient = _centreGradient;
	NSColor *glossyColor = [self alphaColor:_centreColorGradientStart];

	// define pt 0
	pt0 = NSMakePoint(xOrigin + r, yOrigin + 0);	

	BOOL pathDefined = NO;
	
	// if respect run mode then try and define path
	if (_respectRunMode) {
		pathDefined = YES;
		NSAffineTransform* xformTranslate = [NSAffineTransform transform];
		
		switch (_runMode) {
				
			case kMGSMotherRunModeConfigure:;
				gradient = _centreGradient;
				glossyColor = [self alphaColor:_centreColorGradientStart];
				
				r = _innerRadius * 0.9f;
				// centered gear
				r *= cosf(DEG2RAD * 30);
				CGFloat depthFactor = 2;
				width = r * cosf(DEG2RAD * 45)*(1 - 1/depthFactor) / (1 + cosf(DEG2RAD * 45));
				pt1 = NSMakePoint(0 + 0, 0 + r);
				pt2 = NSMakePoint(pt1.x + width, pt1.y);
				pt3 = NSMakePoint(pt2.x, pt2.y - r/depthFactor);
				pt4 = MGSMakePointWithPolarOffset(pt3, r/depthFactor, DEG2RAD * 45);
				pt5 = MGSMakePointWithPolarOffset(pt4, width, DEG2RAD * -45);
				pt6 = MGSMakePointWithPolarOffset(pt5, width, DEG2RAD * -45);
				pt7 = MGSMakePointWithPolarOffset(pt6, r/depthFactor, DEG2RAD * 225);
				pt8 = NSMakePoint(0 + r, pt7.y);
				pt9 = NSMakePoint(0 + r, 0);
				
				NSAffineTransform* xformRotate = [NSAffineTransform transform];
				[xformRotate rotateByDegrees:90];
				
				// tried appending a complete bezier path segment but it didn't quite work out.
				// note that we use a lower level of symmetry by drawing to pt5 and rotating 8 times
				[_bezierPath moveToPoint:pt1];
				for (int i = 0; i <4; i++) {
					[_bezierPath appendBezierPathWithArcFromPoint:pt2 toPoint:pt3 radius:blendRadius];
					[_bezierPath appendBezierPathWithArcFromPoint:pt3 toPoint:pt4 radius:blendRadius];
					[_bezierPath appendBezierPathWithArcFromPoint:pt4 toPoint:pt5 radius:blendRadius];
					[_bezierPath appendBezierPathWithArcFromPoint:pt5 toPoint:pt6 radius:blendRadius];
					[_bezierPath appendBezierPathWithArcFromPoint:pt6 toPoint:pt7 radius:blendRadius];
					[_bezierPath appendBezierPathWithArcFromPoint:pt7 toPoint:pt8 radius:blendRadius];
					[_bezierPath appendBezierPathWithArcFromPoint:pt8 toPoint:pt9 radius:blendRadius];
					[_bezierPath lineToPoint:pt9];
					
					if (i<3) {
						[_bezierPath transformUsingAffineTransform:xformRotate];
					}
				}
				
				[_bezierPath appendBezierPathWithOvalInRect:NSMakeRect( -r/(2*depthFactor), -r/(2*depthFactor), r/depthFactor, r/depthFactor)];
				
				// centre path
				[xformTranslate translateXBy:xOrigin yBy:yOrigin];
				[_bezierPath transformUsingAffineTransform:xformTranslate];
				
				
			break;
			
			case 10000:
								
				// glossy text
				if (NO) {
					// get required font
					NSFont *font = [NSFont fontWithName:@"Lucida Grande" size:80.0f];
					font = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSBoldFontMask];

					// get bezier path rep of our string
					_bezierPath = [@"KosmicTask" bezierWithFont: font];

					NSRect bounds = [_bezierPath bounds];
					NSPoint centreBounds = NSMakePoint(bounds.origin.x + bounds.size.width/2, bounds.origin.y + bounds.size.height/2);
					
					// centre path
					[xformTranslate translateXBy:xOrigin - centreBounds.x yBy:yOrigin - centreBounds.y];
					[_bezierPath transformUsingAffineTransform:xformTranslate];
				} else {
					pathDefined = NO;
				}
				
				break;
				
			default:
				pathDefined = NO;
				break;
		}
	}
	
	// if path not defined
	if (!pathDefined) {
		
		// create path
		switch (_activity) {
				
			// ready/processing
			case MGSReadyTaskActivity:;
			case MGSTerminatedTaskActivity:;
				
				// centered equilateral triangle vertices
				CGFloat a = DEG2RAD * 120;
				pt2 = NSMakePoint(xOrigin + r * cosf(a), yOrigin + r * sinf(a));
				a *= 2;
				pt3 = NSMakePoint(xOrigin + r * cosf(a), yOrigin + r * sinf(a));

				[_bezierPath moveToPoint:pt0];
				[_bezierPath appendBezierPathWithArcFromPoint:pt2 toPoint:pt3 radius:blendRadius];
				[_bezierPath appendBezierPathWithArcFromPoint:pt3 toPoint:pt0 radius:blendRadius];
				[_bezierPath appendBezierPathWithArcFromPoint:pt0 toPoint:pt2 radius:blendRadius];
				[_bezierPath closePath];
				
				break;
				
			// paused/terminated
			case MGSPausedTaskActivity:;
			case MGSProcessingTaskActivity:;
				gradient = _centreGradientHighlight;
				glossyColor = [self alphaColor:_centreColorActiveGradientStart];
				
				// centered square
				r *= cosf(DEG2RAD * 30);
				pt1 = NSMakePoint(xOrigin + r, yOrigin + r);
				pt2 = NSMakePoint(xOrigin - r, yOrigin + r);
				pt3 = NSMakePoint(xOrigin - r, yOrigin - r);
				pt4 = NSMakePoint(xOrigin + r, yOrigin - r);
				width = 2 * r * .38f;
				
				// processing - draw pause symbol
				if (_activity == MGSProcessingTaskActivity) {

					
					NSRect rect1 = NSMakeRect(pt3.x, pt3.y, width, 2 * r);
					[_bezierPath appendBezierPathWithRoundedRect:rect1 xRadius:blendRadius yRadius:blendRadius];

					NSRect rect2 = NSMakeRect(pt4.x - width, pt4.y, width, 2 * r);
					[_bezierPath appendBezierPathWithRoundedRect:rect2 xRadius:blendRadius yRadius:blendRadius];

				// paused - draw restart symbol
				} else if (_activity == MGSPausedTaskActivity) {
					
					NSRect rect1 = NSMakeRect(pt3.x, pt3.y, width, 2 * r);
					[_bezierPath appendBezierPathWithRoundedRect:rect1 xRadius:blendRadius yRadius:blendRadius];

					// triangle vertices
					width = (pt1.x -pt2.x) * .5f;
					pt5 = NSMakePoint(pt4.x + width/2, yOrigin);	
					pt6 = NSMakePoint(pt1.x - width, pt1.y);
					pt7 = NSMakePoint(pt6.x, pt4.y);
					
					[_bezierPath moveToPoint:pt5];
					[_bezierPath appendBezierPathWithArcFromPoint:pt6 toPoint:pt7 radius:blendRadius];
					[_bezierPath appendBezierPathWithArcFromPoint:pt7 toPoint:pt5 radius:blendRadius];
					[_bezierPath appendBezierPathWithArcFromPoint:pt5 toPoint:pt6 radius:blendRadius];
					[_bezierPath closePath];
					
				} else {
					
					// terminated
					NSRect squareRect = NSMakeRect(pt3.x, pt3.y, 2 * r, 2 * r);
					[_bezierPath appendBezierPathWithRoundedRect:squareRect xRadius:blendRadius yRadius:blendRadius];
				}
				
				break;

			// unavailable
			case MGSUnavailableTaskActivity:;
				gradient = _centreGradientAlt;
				glossyColor = [self alphaColor:_centreColorAltGradientStart];
				
				// centered horizontal line
				r *= cosf(DEG2RAD * 30);
				width = 2 * r * .38f;
				pt3 = NSMakePoint(xOrigin - r, yOrigin - width/2);

				NSRect squareRect = NSMakeRect(pt3.x, pt3.y, 2 * r, width);
				[_bezierPath appendBezierPathWithRoundedRect:squareRect xRadius:blendRadius yRadius:blendRadius];
				
				break;
		
				
				
			default:
				return;
		}
	}
    
	// fill the path
	if (YES) {
		
		[_bezierPath fill]; // gradient fill below doesn't generate shadow
		
		if (NO) {
			// draw simple gradient
			[gradient drawInBezierPath:_bezierPath angle:90];	// doesn't generate shadow
		} else {
			
			// apply bezier clipping path and draw glossy gradient
			NSGraphicsContext* gc = [NSGraphicsContext currentContext];	
			[_bezierPath addClip];	// add receiver to current clipping path
			DrawGlossGradient([gc graphicsPort], glossyColor, [_bezierPath bounds]);
		}
	} else {
		[_bezierPath stroke];
	}
	
	[self restoreBezierState];		
	[[self alphaColor:_fillColor] set];
}


/*
 
 draw spinner in rect
 
 */
- (void)drawSpinner
{
	if ([self isSpinning]) {
		
		if (_activity == MGSPausedTaskActivity) {
			[[self alphaColor:_pausedSpinnerColor] set];
		} else {
			[_spinnerColor set];
		}
		[_bezierPath appendBezierPathWithOvalInRect:_animatedCircleRect];
		[_bezierPath fill];

		//MLog(DEBUGLOG, @"%@: circle rect origin.x =%f, origin.y = %f, size.width = %f, size.height = %f", [self className], _animatedCircleRect.origin.x, _animatedCircleRect.origin.y, _animatedCircleRect.size.width, _animatedCircleRect.size.height);
								
		[self restoreBezierState];
	}
	
}

/*
 
 update animated rect
 
 */
- (void)updateAnimatedRect
{
	float flipFactor = ([self isFlipped] ? 1.0f : -1.0f);		
	int step = (int)round(([self doubleValue]/(5.0/60.0)));
	
	float a; // angle
	NSPoint inner;
	
	if ([self isSpinning]) {
		a = (270+(step* 30))*DEG2RAD;
	} else {
		a = 270*DEG2RAD;
	}
	a = flipFactor*a;
	
	inner = NSMakePoint(_centerPoint.x+cosf(a)*_circleRadius, _centerPoint.y+sinf(a)*_circleRadius);
	
	CGFloat offset = _circleLineWidth/2 * .8f;
	_animatedCircleRect = NSMakeRect(inner.x - offset, inner.y - offset, 2 * offset, 2 * offset);
}

/*
 
 save bezier state
 
 */
- (void)saveBezierState
{
	_bezierLineCapStyle = [_bezierPath lineCapStyle];
	_bezierLineWidth = [_bezierPath lineWidth];	
}

/*
 
 restore bezier state
 
 */
- (void)restoreBezierState
{
	[_bezierPath setLineCapStyle:_bezierLineCapStyle];
	[_bezierPath setLineWidth:_bezierLineWidth];
	
	[_bezierPath removeAllPoints];
}

/*
 
 validate the draw rect
 
 */
- (NSRect)validateDrawRect:(NSRect)rect
{
	NSRect boundsRect = [self bounds];
	
	// if bounds rect and cache rect are not equal then
	// the cache will have to be updated
	if (!NSEqualSizes(boundsRect.size, _cacheRect.size)) {
		[self clearDisplayCache];
	}
	
	// if no display cache available then need to draw bounds into cache
	if (!_imageCache) {
		rect = boundsRect;
        
#ifdef MGS_VIEW_DEBUG
        NSLog(@"Display cache rect set to view bounds.");
#endif
        
	}
	
	return rect;
}


/*
 
 draw rect from cache
 
 */
- (void)drawRectFromCache:(NSRect)rect
{
	//MLog(DEBUGLOG, @"%@: rect drawn from cache", [self className]);
	//MLog(DEBUGLOG, @"%@: rect origin.x =%f, origin.y = %f, size.width = %f, size.height = %f", [self className], rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);

	[_imageCache drawInRect:rect fromRect:rect operation:NSCompositeSourceOver fraction:1.0];
}
@end
