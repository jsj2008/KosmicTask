//
//  MGSViewButtonCell.m
//  Mother
//
//  Created by Jonathan on 07/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSViewButtonCell.h"


@implementation MGSViewButtonCell

- (BOOL)startTrackingAt:(NSPoint)startPoint inView:(NSView *)controlView
{
	#pragma unused(startPoint)
	#pragma unused(controlView)
	
	return NO;
}
- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint
			  inView:(NSView *)controlView mouseIsUp:(BOOL)flag
{
	#pragma unused(lastPoint)
	#pragma unused(stopPoint)
	
    if (flag == YES) {
        [controlView setNeedsDisplay:YES];
    }
}

@end
