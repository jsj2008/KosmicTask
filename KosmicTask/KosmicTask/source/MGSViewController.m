//
//  MGSViewController.m
//  Mother
//
//  Created by Jonathan on 27/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSViewController.h"

@implementation MGSViewController
@synthesize delegate = _delegate;

/*
 
 awake from nib
 
 */
- (void)awakeFromNib
{
	// tell the view's delegate that we are loaded.
	if (_delegate && [_delegate respondsToSelector:@selector(viewDidLoad:)]) {
		[_delegate viewDidLoad:[self view]];
	}
}
@end
