//
//  MGSActionActivityTextView.m
//  KosmicTask
//
//  Created by Mitchell Jonathan on 01/02/2012.
//  Copyright (c) 2012 Mugginsoft. All rights reserved.
//

#import "MGSActionActivityTextView.h"

@implementation MGSActionActivityTextView

/*
 
 - initWithFrame:
 
 */
- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        
        // we want a transparent textview that displays the activity view behind it.
        [self setDrawsBackground:NO];
        [(NSScrollView *)[self superview] setDrawsBackground:NO];
    }
    
    return self;
}

/*
 
 - isOpaque
 
 */
- (BOOL)isOpaque
{
	return NO;
}

@end
