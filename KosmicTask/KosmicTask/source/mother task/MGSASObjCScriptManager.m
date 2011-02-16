//
//  MGSASObjCScriptManager.m
//  KosmicTask
//
//  Created by Jonathan on 15/05/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSASObjCScriptManager.h"
#import <AppleScriptObjC/AppleScriptObjC.h>
#import "KosmicTaskController.h"

@interface NSObject (LoadScript)
- (id)scriptObject;
- (id)resultObject;
- (BOOL)keepTaskAlive;

@end

/*
 
 http://lists.apple.com/archives/applescript-users/2009/Aug/msg00341.html
 
 */
@implementation MGSASObjCScriptManager

/*
 
 - executorClassName
 
 */
- (NSString *)executorClassName
{
	return @"MGSAppleScriptExecutor";
}

/*
 
 - setupEnvironment
 
 */
- (BOOL) setupEnvironment:(MGSScriptRunner *)scriptRunner
{	
#pragma unused(scriptRunner)
	
	NSBundle *bundle = [NSBundle mainBundle];
	
	[bundle loadAppleScriptObjectiveCScripts];
	
	return YES;
}

/*
 
 - loadScriptAtPath:runFunction:withArguments:
 
 */
- (id) loadScriptAtPath:(NSString*)scriptPath runClass:(NSString*)className runFunction:(NSString*)functionName withArguments:(NSArray*)arguments 
{
	// load script at path and execute
	id object = [super loadScriptAtPath:scriptPath runClass:className runFunction:functionName withArguments:arguments];

	id scriptObject = nil;
	id resultObject = nil;

	// get script object
	if ([object respondsToSelector:@selector(scriptObject)]) {
		scriptObject = [object performSelector:@selector(scriptObject)];
	}
	
	// get result object
	if ([object respondsToSelector:@selector(resultObject)]) {
		resultObject = [object performSelector:@selector(resultObject)];
	}
	
	// if the KosmicTaskController shared object declares keepTaskAlive == YES then
	// we want to keep the script alive
	if ([[KosmicTaskController sharedController] keepTaskAlive]) {
		
		// return the script object
		return scriptObject;
	}

	// return the result object
	return resultObject;
}

@end
