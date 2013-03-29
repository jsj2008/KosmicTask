//
//  MGSAppleScriptLanguage.m
//  KosmicTask
//
//  Created by Jonathan on 10/11/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSAppleScriptLanguage.h"


@implementation MGSAppleScriptLanguage

/*
 
 - init
 
 */
- (id)init
{
	self = [super init];
	if (self) {
		
		self.initBuildProcessType = kMGSInProcess;
		self.initExecutorProcessType = kMGSInProcess;
		self.initSeparateSyntaxChecker = NO;
		self.initExecutorAcceptsOptions = NO;
		self.initBuildAcceptsOptions = NO;
		self.initExecutableFormat = kMGSCompiled;
		self.initLanguageShipsWithOS = YES;
		
		// interface
		self.initSupportsDirectParameters = YES;
		self.initSupportsScriptFunctions = YES;
		self.initDefaultScriptFunction = @"KosmicTask";
		
		// Cocoa
		self.initIsCocoaBridge = NO;
		
		// Result representation
		self.initNativeObjectsAsResults = YES;
		self.initNativeObjectsAsYamlSupport = NO;
		
		self.initSourceFileExtensions = [NSArray arrayWithObjects:@"applescript", nil];
		
		self.initIsOsaLanguage = YES;
		self.initScriptType = @"AppleScript";
		self.initTaskRunnerClassName = @"MGSAppleScriptRunner";
		self.initTaskProcessName = @"KosmicTaskAppleScriptRunner";
		self.initBuildResultFlags = kMGSScriptSourceRTF | kMGSCompiledScript;
        
        // code template processing
        self.initInputArgumentName = kMGSInputArgumentName;
        self.initInputArgumentCase = kMGSInputArgumentCamelCase;
        self.initInputArgumentStyle = kMGSInputArgumentWhitespaceRemoved;
	}
	
	return self;
}

/*
 
 - taskFunctionCodeTemplateName:
 
 */
- (NSString *)taskFunctionCodeTemplateName:(NSDictionary *)taskInfo
{
#pragma unused(taskInfo)
    
    NSString *templateName = nil;
    NSNumber *onRun = [taskInfo objectForKey:@"onRun"];
    if (onRun) {
        switch ([onRun integerValue]) {
                
            // if just calling the script them always
            // use the run handler so that arguments can be passed if required.
            case kMGSOnRunCallScript:
                templateName = @"task-run-handler";
                break;
                
            default:
                break;

        }
    }

    if (!templateName) {
        templateName = [super taskFunctionCodeTemplateName:taskInfo];
    }
    
    return templateName;

}

@end
