//
//  MGSProgressTableView.m
//  Mother
//
//  Created by Jonathan on 19/09/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSProgressTableView.h"


@implementation MGSProgressTableView

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
