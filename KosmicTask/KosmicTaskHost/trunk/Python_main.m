/*
 *  Python_main.c
 *  KosmicTaskHost
 *
 *  Created by Jonathan on 28/04/2010.
 *  Copyright 2010 mugginsoft.com. All rights reserved.
 *
 */
#import <Cocoa/Cocoa.h>
#import "STEPluginManager.h"

int main(int argc, const char *argv[])
{
	if (![[STEPluginManager sharedManager] setupPythonEnvironment])
		NSLog(@"error: python environment could not be set up.");
	
	return NSApplicationMain(argc, (const char **) argv);
}