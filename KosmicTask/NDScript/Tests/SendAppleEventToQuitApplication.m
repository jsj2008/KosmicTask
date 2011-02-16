/*
 *  SendAppleEventToQuitApplication.m
 *  NDScriptTest
 *
 *  Created by Nathan Day on 2/04/05.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "SendAppleEventToQuitApplication.h"


@implementation SendAppleEventToQuitApplication

- (void)run
{
	NDComponentInstance		* theComponentInstance = [[NDComponentInstance alloc] init];
	NDScriptContext			* theScriptA = [NDScriptContext scriptDataWithSource:@"tell application \"TextEdit\"\n\tactivate\n\tif (count of every document) is 0 then make new document at end of every document\n\tset text of first document to \"Test one\"\nend tell" componentInstance:theComponentInstance],
		* theScriptB = [NDScriptContext scriptDataWithSource:@"tell application \"TextEdit\"\n\tactivate\n\tif (count of every document) is 0 then make new document at end of every document\n\tset text of first document to \"Test two\"\nend tell" componentInstance:theComponentInstance];
	[theComponentInstance setAppleEventSendTarget:theComponentInstance currentProcessOnly:YES];
	
	[theScriptA execute];
	NSRunAlertPanel(@"Pause", @"Pausing so you can quit TextEdit and see if the next AppleScript can still send AppleEvents to TextEdit", @"OK", nil, nil );	
	[theScriptB execute];
	
	[theComponentInstance release];
	[super finished];
}

@end
