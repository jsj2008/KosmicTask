//
//  STEPluginManager.m
//  AwesomeTextEditor
//
//  Created by Steven Degutis on 3/24/10.
//  Copyright 2010 Big Nerd Ranch, Inc. All rights reserved.
//
// http://www.informit.com/blogs/blog.aspx?uk=Ask-Big-Nerd-Ranch-Adding-Python-Scripting-to-Cocoa-apps
//
#import "MGSPythonScriptManager.h"

// python framework no longer in the SDK.
// must have xcode command line tools installed.
#import <Python.h>

@interface MGSPythonScriptExecutor : NSObject < MGSScriptExecutor> {
}
@end


@implementation MGSPythonScriptManager

/*
 
 - setupEnvironment
 
 */
- (BOOL) setupEnvironment:(MGSScriptRunner *)scriptRunner
{
	
	// check if already initialised
	if (Py_IsInitialized()) {
		return YES;
	}
	
	// just in case /usr/bin/ is not in the user's path, although it should be
	//
	// note that serious problems were encountered due to the fact that a Python 2.5.2 framework
	// was installed in /Library/Frameworks. removing this resolved problem
	//
	Py_SetProgramName((char *)[[scriptRunner launchPath] UTF8String]);
	
	// set up the basic python environment.
	Py_Initialize();
	
	// get path to our python entrypoint
	NSString *scriptPath = [[scriptRunner resourcesPath] stringByAppendingPathComponent:@"MGSPythonScriptExecutor.py"];
	
	// load the main script into the python runtime
	FILE *mainFile = fopen([scriptPath UTF8String], "r");
	return (PyRun_SimpleFile(mainFile, (char *)[[scriptPath lastPathComponent] UTF8String]) == 0);
}

/*
 
 - executorClassName
 
 */
- (NSString *)executorClassName
{
	return @"MGSPythonScriptExecutor";
}

@end
