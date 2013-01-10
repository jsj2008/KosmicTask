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
	}
	
	return self;
}

#pragma mark -
#pragma mark Code generation

/*
 
 - taskInputsCodeTemplate
 
 */
- (NSString *)taskInputsCodeTemplate:(NSDictionary *)taskInfo
{
#pragma unused(taskInfo)
    
    NSString *template = [super taskInputsCodeTemplate:taskInfo];
    return template;
}

/*
 
 - taskBodyCodeTemplate:
 
 */
- (NSString *)taskBodyCodeTemplate:(NSDictionary *)taskInfo
{
    #pragma unused(taskInfo)
    
    NSString *template = [super taskBodyCodeTemplate:taskInfo];
    return template;
}

/*
 
 - codeProperties
 
 */
- (NSDictionary *)codeProperties
{
    return @{MGSInputStyle:@"function"};
}
@end
