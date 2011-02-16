//
//  MGSNumbersSendPlugin.m
//  Mother
//
//  Created by Jonathan on 22/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
// NO applescript support as yet
//
#import "MGSNumbersSendPlugin.h"


@implementation MGSNumbersSendPlugin

/*
 
 target app name
 
 */
- (NSString *)targetAppName
{
	return @"Numbers.app";
}

/* 
 
 menu item string
 
 */
- (NSString *)menuItemString
{
	return NSLocalizedString(@"Numbers", @"Send plugin menu item string");
}
@end
