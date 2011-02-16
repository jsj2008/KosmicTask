//
//  MGSWindowFooterView.m
//  Mother
//
//  Created by Jonathan on 08/10/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSWindowFooterView.h"


@implementation MGSWindowFooterView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}


- (void)drawRect:(NSRect)rect {
	
	[super drawRect:rect];
	[[NSColor colorWithCalibratedWhite: 0.592f alpha: 1.0f] set]; 
	NSRect boundsRect = [self bounds];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(boundsRect.origin.x, boundsRect.origin.y + boundsRect.size.height-0.5f) toPoint:NSMakePoint(boundsRect.origin.x + boundsRect.size.width, boundsRect.origin.y + boundsRect.size.height-0.5f)];
}

@end
