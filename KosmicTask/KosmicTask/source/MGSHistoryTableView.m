//
//  MGSHistoryTableView.m
//  Mother
//
//  Created by Jonathan on 20/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSHistoryTableView.h"


@implementation MGSHistoryTableView

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
