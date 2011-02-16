//
//  MGSWaitViewController.m
//  Mother
//
//  Created by Jonathan on 12/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSWaitViewController.h"


@implementation MGSWaitViewController

/*
 
 - clear
 
 */
- (void)clear
{
	[progress stopAnimation:self];
	[progress setHidden:YES];
	[text setHidden:YES];
	[[self view] display];
}
@end
