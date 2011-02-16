//
//  NSViewController_Mugginsoft.m
//  Mother
//
//  Created by Jonathan on 19/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "NSViewController_Mugginsoft.h"


@implementation NSViewController (Mugginsoft)

/*
 
 notification object is view's window
 
 */
- (BOOL)notificationObjectIsWindow:(NSNotification *)notification
{
	return [notification object] == [[self view] window] ? YES : NO;
}
@end
