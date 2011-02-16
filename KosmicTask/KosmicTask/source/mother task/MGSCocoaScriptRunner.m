//
//  MGSCocoaScriptRunner.m
//  KosmicTask
//
//  Created by Jonathan on 12/05/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSCocoaScriptRunner.h"


@implementation MGSCocoaScriptRunner

#pragma mark -
#pragma mark Operations

/*
 
 - execute 
 
 we have two options here:
 
 1. in process
 
 we can try and transform ourselves into an application.
 
 [NSApplication sharedApplication];
 [NSApp setDelegate:self];
 [NSBundle loadNibNamed:@"myMain" owner:NSApp];
 // run until NSApp - stop: or terminate: sent.
 // only NSApp - stop: will cause run loop to return here.
 [NSApp run];
 
 The above works but it becomes more diffificult if we say want to have the
 app show a GUI on demand using LSUIElement in the info.plist.
 
 It appears that showing a dialog works anyhow!
 
 2. out of process
 
 Spawn a wholly separate agent app to do our bidding.
 
 This can have LSUIElement = 1 so that it can show panels if desired
 However, we have to observe our spawned process in some way
 and retrieve task results.
 
 */
- (BOOL) execute
{
	// create a shared application object
	[NSApplication sharedApplication];
	
	// set our delegate
	[NSApp setDelegate:self];
	
	// load nib
	//[NSBundle loadNibNamed:@"myMain" owner:NSApp];
	
	// run until NSApp - stop: or terminate: sent.
	// only NSApp - stop: will cause run loop to return here.
	// But, only checks for stop request after an actual event has been
	// processed - timers do not count in this regard.
	[NSApp run];
	
	return YES;
}


/*
 
 - stop:
 
 */
- (void)stop:(id)sender
{
#pragma unused(sender)
	
	// form result dict
	NSMutableDictionary *resultDict = [NSMutableDictionary dictionaryWithCapacity:2];
	
	[resultDict setObject:@"NSApplicationMain did return" forKey:MGSScriptKeyResultObject];
	
	// add result dict to reply
	[self.replyDict setObject:resultDict forKey:MGSScriptKeyResult];
	
	// will stop run loop after next actual event object dispatched.
	// a timer doesn't count here
	[NSApp stop:self];
	
	// send a dummy event to trigger stopping
	NSEvent *event = [NSEvent otherEventWithType:NSApplicationDefined 
										location:NSMakePoint(0,0)
								   modifierFlags:0
									   timestamp:0 
									windowNumber:0 
										 context:nil
										 subtype:1 
										   data1:1 
										   data2:1];
	[NSApp postEvent:event atStart:YES];
}

@end
