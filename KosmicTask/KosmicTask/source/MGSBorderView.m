//
//  MGSBorderView.m
//  KosmicTask
//
//  Created by Jonathan on 30/06/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSBorderView.h"

char MGSDrawContext;

@implementation MGSBorderView

@synthesize borderColor = _borderColor;
@synthesize borderFlags = _borderFlags;

/*
 
 - initWithFrame:
 
 */
- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        _borderColor = [NSColor grayColor];
        _borderFlags = (kMGSBorderViewTop | kMGSBorderViewLeft | kMGSBorderViewBottom | kMGSBorderViewRight);
        
        [self addObserver:self forKeyPath:@"borderColor" options:0 context:&MGSDrawContext];
        [self addObserver:self forKeyPath:@"borderFlags" options:0 context:&MGSDrawContext];
    }
    return self;
}

#pragma mark -
#pragma mark KVO

/*
 
 - observeValueForKeyPath:ofObject:change:context:
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
#pragma unused(keyPath)
#pragma unused(object)
#pragma unused(change)
    
    if (context == &MGSDrawContext ) {
        [self setNeedsDisplay:YES];
    }
}

#pragma mark -
#pragma mark Drawing
/*
 
 draw rect
 
 */
- (void)drawRect:(NSRect)rect {
	
	rect = [self bounds];
    
	NSGraphicsContext* gc = [NSGraphicsContext currentContext];
	
	[gc setShouldAntialias:NO];

	// border
	NSBezierPath *bzPath = [NSBezierPath bezierPath];

    NSPoint p1 = rect.origin;
    NSPoint p2 = NSMakePoint(rect.origin.x + rect.size.width - 1, p1.y);
    NSPoint p3 = NSMakePoint(p2.x, rect.origin.y + rect.size.height - 1);
    NSPoint p4 = NSMakePoint(p1.x, p3.y);
    
    if (_borderFlags & kMGSBorderViewTop) {
        [bzPath moveToPoint:p1];
        [bzPath lineToPoint:p2];
    }
    if (_borderFlags & kMGSBorderViewRight) {
        [bzPath moveToPoint:p2];
        [bzPath lineToPoint:p3];
    }
    if (_borderFlags & kMGSBorderViewBottom) {
        [bzPath moveToPoint:p3];
        [bzPath lineToPoint:p4];
    }
    if (_borderFlags & kMGSBorderViewLeft) {
        [bzPath moveToPoint:p4];
        [bzPath lineToPoint:p1];
    }
	[self.borderColor set];
	[bzPath stroke];
}

@end
