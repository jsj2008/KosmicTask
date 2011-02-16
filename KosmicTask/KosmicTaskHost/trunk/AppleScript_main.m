/*
 *  AppleScript_main.m
 *  KosmicTaskHost
 *
 *  Created by Jonathan on 28/04/2010.
 *  Copyright 2010 mugginsoft.com. All rights reserved.
 *
 */
#import <Cocoa/Cocoa.h>
#import <AppleScriptObjC/AppleScriptObjC.h>

int main(int argc, const char *argv[])
{
	// load ASObjC scripts
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[NSBundle mainBundle] loadAppleScriptObjectiveCScripts];
	[pool drain];
	
	// read from stdin
	
	return NSApplicationMain(argc, (const char **) argv);
}

