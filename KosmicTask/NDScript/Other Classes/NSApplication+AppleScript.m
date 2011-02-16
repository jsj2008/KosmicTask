/*
 *  NSApplication+AppleScript.m category
 *  NDScriptData
 *
 *  Created by Nathan Day on 17/12/04.
 *  Copyright (c) 2002 Nathan Day6. All rights reserved.
 */

#import "NSApplication+AppleScript.h"


@implementation NSApplication (AppleScript)

- (LoggingObject *)loggingObject
{
	return [[self delegate] loggingObject];
}

@end
