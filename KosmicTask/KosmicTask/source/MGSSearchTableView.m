//
//  MGSSearchTableView.m
//  Mother
//
//  Created by Jonathan on 03/12/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSSearchTableView.h"


@implementation MGSSearchTableView

/*
 
 resign first responder
 
 */
- (BOOL)resignFirstResponder
{
	// clear selection before resigning first responder
	[self deselectAll:self];
	return YES;
}

@end
