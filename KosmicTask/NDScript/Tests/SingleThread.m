/*
 *  SingleThread.m
 *  NDScriptTest
 *
 *  Created by Nathan Day on 26/03/05.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "SingleThread.h"

@implementation SingleThread

+ (unsigned int)numberOfThreads
{
	return 1;
}

- (SendAppleEventTarget *)sendAppleEventTargetWithMessage:(NSString *)aMessage
{
	return [[SingleThreadTarget alloc] initWithMessage:aMessage owner:self];
}

@end

@implementation SingleThreadTarget

+ (NSString *)targetApplicationName
{
	return @"NDScriptTest";
}

+ (unsigned int)numberOfAppleScriptrepeats
{
	return 100;
}

@end