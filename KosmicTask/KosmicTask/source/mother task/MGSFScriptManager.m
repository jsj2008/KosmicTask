//
//  MGSFScriptManager.m
//  KosmicTask
//
//  Created by Jonathan on 06/08/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSFScriptManager.h"
#import <FScript/FScript.h>
#import "BlockStackElem.h"	// on user search path
#import "NSError_Mugginsoft.h"
#import "KosmicTaskController.h"

@implementation MGSFScriptManager

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
#pragma unused(functionName)
#pragma unused(className)
	
	id executeResult = nil;
		
	FSBlock *block = nil;
	NSString *source = [NSString stringWithContentsOfFile:scriptPath encoding:NSUTF8StringEncoding error:NULL];
	
	// create block and execute 
	// see http://www.fscript.org/documentation/EmbeddingFScriptIntoCocoa/index.htm
	@try {
		block = [source asBlock];
		executeResult = [block valueWithArguments:arguments];
		
	} @catch (NSException* e) {		
		self.error =[e reason];
	}
	
	// if we are keeping the task alive then the block is the return value
	if ([[KosmicTaskController sharedController] keepTaskAlive]) {
		return block;
	} 
	
	return executeResult;
}



@end
