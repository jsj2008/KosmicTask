//
//  MGSTaskSearchView.m
//  KosmicTask
//
//  Created by Jonathan on 14/01/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSTaskSearchView.h"


@implementation MGSTaskSearchView

@synthesize delegate;

/*
 
 - viewDidMoveToSuperview
 
 */
- (void)viewDidMoveToSuperview
{
	if (delegate && [delegate respondsToSelector:@selector(viewDidMoveToSuperview:)]) {
		[delegate viewDidMoveToSuperview:self];
	}
}


@end
