/*
 *  BaseTestClass.m
 *  NDScriptData
 *
 *  Created by Nathan Day on 19/12/04.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "BaseTestClass.h"
#import "ApplicationDelegate.h"

@implementation BaseTestClass

- (id)initWithLoggingObject:(LoggingObject *)aLoggingObject
{
	if( (self = [self init]) != nil )
	{
		NSParameterAssert( aLoggingObject != nil );
		log = aLoggingObject;
	}
	return self;
}

- (void)run
{
	NSLog( @"Method run must be implemented" );
}

- (void)finished
{
	[[[NSApplication sharedApplication] delegate] finishedTest:nil];
}	

@end
