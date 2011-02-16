/*
 *  SendAppleEventToSelf.m
 *  NDScriptTest
 *
 *  Created by Nathan Day on 26/03/05.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "SendAppleEventToSelf.h"

@implementation SendAppleEventToSelf

- (SendAppleEventTarget *)sendAppleEventTargetWithMessage:(NSString *)aMessage
{
	return [[SendAppleEventToSelfTarget alloc] initWithMessage:aMessage owner:self];
}

@end

@implementation SendAppleEventToSelfTarget

+ (NSString *)targetApplicationName
{
	return @"NDScriptTest";
}

@end