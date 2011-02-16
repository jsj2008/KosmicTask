//
//  MGSOutputRequestView.m
//  KosmicTask
//
//  Created by Jonathan on 30/12/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import "MGSOutputRequestView.h"


@implementation MGSOutputRequestView

@synthesize delegate;

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
