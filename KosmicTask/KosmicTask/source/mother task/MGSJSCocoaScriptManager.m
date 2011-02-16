//
//  MGSJSCocoaScriptManager.m
//  KosmicTask
//
//  Created by Jonathan on 10/12/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSJSCocoaScriptManager.h"
#import <JSCocoa/JSCocoa.h>

@implementation MGSJSCocoaScriptManager

/*
 
 - setupEnvironment:
 
 */
- (BOOL) setupEnvironment:(MGSScriptRunner *)scriptRunner
{
#pragma unused(scriptRunner)
	
	return YES;
}


/*
 
 - loadScriptAtPath:runClass:runFunction:withArguments:
 
 */
- (id) loadScriptAtPath:(NSString*)scriptPath runClass:(NSString*)className runFunction:(NSString*)functionName withArguments:(NSArray*)arguments 
{
#pragma unused(className)
	
	id executeResult = nil;
	
	// establish connection
	jsCocoa = [JSCocoa new];

	// evaluate the script file
	if (![jsCocoa evalJSFile:scriptPath]) {
		self.error = @"Error loading and evaluating script file.";
		return nil;
	}

	// call our required function
	JSValueRef returnValue = [jsCocoa callJSFunctionNamed:functionName withArgumentsArray:arguments];
	
	executeResult = [jsCocoa toObject:returnValue];
	
	return executeResult;
}

/*
 
 - executorClassName
 
 */
- (NSString *)executorClassName
{
	return @"MGSJSCocoaExecutor";
}

@end
