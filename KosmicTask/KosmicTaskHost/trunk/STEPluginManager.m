//
//  ATEPluginManager.m
//  AwesomeTextEditor
//
//  Created by Steven Degutis on 3/24/10.
//  Copyright 2010 Big Nerd Ranch, Inc. All rights reserved.
//
// http://www.informit.com/blogs/blog.aspx?uk=Ask-Big-Nerd-Ranch-Adding-Python-Scripting-to-Cocoa-apps
//
#import "STEPluginManager.h"

#import <Python/Python.h>


@interface NSObject (PythonPluginInterface)

- (BOOL) loadModuleAtPath:(NSString*)path
			 functionName:(NSString*)funcName
				arguments:(NSArray*)args;

@end



@implementation STEPluginManager

/*
 
 + sharedManager
 
 */
+ (STEPluginManager*) sharedManager {
	static STEPluginManager *sharedManager = nil;
	
	if (!sharedManager) {
		sharedManager = [[STEPluginManager alloc] init];
	}
	
	return sharedManager;
}

/*
 
 - setupPythonEnvironment
 
 */
- (BOOL) setupPythonEnvironment 
{
	
	// check if already initialised
	if (Py_IsInitialized()) {
		return YES;
	}
	
	// just in case /usr/bin/ is not in the user's path, although it should be
	Py_SetProgramName("/usr/bin/python");
	
	// set up the basic python environment.
	Py_Initialize();
	
	// get path to our python entrypoint
	NSString *scriptPath = [[NSBundle mainBundle] pathForResource:@"STEPluginExecutor" ofType:@"py"];
	
	// load the main script into the python runtime
	FILE *mainFile = fopen([scriptPath UTF8String], "r");
	return (PyRun_SimpleFile(mainFile, (char *)[[scriptPath lastPathComponent] UTF8String]) == 0);
}

/*
 
 - loadScriptAtPath:runFunction:withArguments:
 */
- (BOOL) loadScriptAtPath:(NSString*)scriptPath runFunction:(NSString*)functionName withArguments:(NSArray*)arguments 
{
	Class executor = NSClassFromString(@"STEPluginExecutor");
	
	return [executor loadModuleAtPath:scriptPath
						 functionName:functionName
							arguments:arguments];
}


/*
 
 - runScript:
 
 */
- (IBAction) runScript:(NSMenuItem*)sender 
{
	// fetch the path from where our app delegate stored it
	NSString *path = [sender representedObject];
	
	STEPluginManager *pluginManager = [STEPluginManager sharedManager];
	BOOL success = [pluginManager loadScriptAtPath:path
									   runFunction:@"main"
									 withArguments:[NSArray arrayWithObjects:nil]];
	
	if (!success)
		NSRunAlertPanel(@"Script Failed", @"The script could not be completed.", nil, nil, nil);
}

@end
