//
//  MGSView.m
//  Mother
//
//  Created by Jonathan on 16/10/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSView.h"


@implementation MGSView

@synthesize delegate;

/*
 
 view did move to superview
 
 */
- (void)viewDidMoveToSuperview
{
	if (delegate && [delegate respondsToSelector:@selector(viewDidMoveToSuperview:)]) {
		[delegate viewDidMoveToSuperview:self];
	}
}

/*
 
 view did move to window
 
 */
- (void)viewDidMoveToWindow
{
	if (delegate && [delegate respondsToSelector:@selector(view:didMoveToWindow:)]) {
		[delegate view:self didMoveToWindow:[self window]];
	}
}

@end
