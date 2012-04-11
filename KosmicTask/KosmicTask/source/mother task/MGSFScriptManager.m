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
    FSInterpreterResult *interpreterResult = nil;
	NSString *source = [NSString stringWithContentsOfFile:scriptPath encoding:NSUTF8StringEncoding error:NULL];
    BOOL useInterpreter = NO;
	id keepAlive = nil;
    
	// create block and execute 
	// see http://www.fscript.org/documentation/EmbeddingFScriptIntoCocoa/index.htm
	@try {
        if (useInterpreter) {
            interpreterResult = [[FSInterpreter interpreter] execute:source];
            executeResult = [interpreterResult result];
            
            keepAlive = executeResult;
        } else {
            
            // this fails if the block has an exception handler unless the code is formatted like so
            // [[1/0 ] onException:[:e| sys beep. stderr print:e description]]

            block = [source asBlock];
            executeResult = [block valueWithArguments:arguments];
            
            keepAlive = block;
		}
        
	} @catch (NSException* e) {		
		self.error =[e reason];
	}
	
	// if we are keeping the task alive then the block is the return value
	if ([[KosmicTaskController sharedController] keepTaskAlive]) {
		return keepAlive;
	} 
	
	return executeResult;
}



@end
