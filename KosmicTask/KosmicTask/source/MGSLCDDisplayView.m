//
//  MGSLCDDisplayView.m
//  Mother
//
//  Created by Jonathan on 11/08/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSLCDDisplayView.h"

#define MGS_MIN_INTENSITY_OPACITY_DELTA 0.8f

@implementation MGSLCDDisplayView

@synthesize maxIntensity = _maxIntensity;

/*
 
 init with frame
 
 */
- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		_displayImage = [NSImage imageNamed:@"LCD display blue.png"];
		_activeDisplayImage = [NSImage imageNamed:@"LCD display green.png"];
		_unavailableDisplayImage = [NSImage imageNamed:@"LCD display red.png"];
		self.maxIntensity = YES;
		_active = NO;
		_available = YES;
    }
    return self;
}

/*
 
 set active
 
 */
- (void)setActive:(BOOL)newValue
{
	_active = newValue;
	[self setNeedsDisplay:YES];
}
/*
 
 set available
 
 */
- (void)setAvailable:(BOOL)newValue
{
	_available = newValue;
	[self setNeedsDisplay:YES];
}
/*
 
 draw rect
 
 */
- (void)drawRect:(NSRect)rect {
	NSImage *image = nil;
	
	if (_available) {
		if (!_active) {
			image = _displayImage;
		} else {
			image = _activeDisplayImage;
		}
	} else {
		image = _unavailableDisplayImage;
	}
	
	[image drawInRect:rect fromRect:rect operation:NSCompositeSourceOver fraction:_opacityDelta];
}

/*
 
 set max intensity
 
 */
- (void)setMaxIntensity:(BOOL)value
{
	_maxIntensity = value;
	_opacityDelta = _maxIntensity ? 1.0f : MGS_MIN_INTENSITY_OPACITY_DELTA;
	[self setNeedsDisplay:YES];
}
 
@end
