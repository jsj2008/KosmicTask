//
//  MGSFilledView.m
//  Mother
//
//  Created by Jonathan on 27/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSFilledView.h"


@implementation MGSFilledView
@synthesize fillColor = _fillColor;

/*
 
 init with frame
 
 */
- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		_fillColor = [NSColor colorWithCalibratedRed:0.988f green:0.988f blue:0.988f alpha:1.0f];
    }
    return self;
}

/*
 
 draw rect
 
 */
- (void)drawRect:(NSRect)rect {
	[_fillColor set];
	NSRectFill(rect);
}

@end
