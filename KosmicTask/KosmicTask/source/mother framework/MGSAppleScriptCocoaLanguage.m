//
//  MGSAppleScriptCocoaLanguage.m
//  KosmicTask
//
//  Created by Jonathan on 10/11/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSAppleScriptCocoaLanguage.h"


@implementation MGSAppleScriptCocoaLanguage

/*
 
 - init
 
 */
- (id)init
{
	self = [super init];
	if (self) {
		self.initBuildProcessType = kMGSOutOfProcess;
		self.initExternalBuildPath = @"/usr/bin/osacompile";;
		self.initExecutorProcessType = kMGSInProcess;
		self.initSeparateSyntaxChecker = NO;
		self.initExecutorAcceptsOptions = NO;
		self.initBuildAcceptsOptions = NO;
		self.initExecutableFormat = kMGSCompiled;
		self.initLanguageShipsWithOS = YES;
		self.initBuildOptions = @"-l AppleScript -d";
		
		// interface
		self.initSupportsScriptFunctions = YES;
		self.initSupportsClasses = YES;
		self.initSupportsClassFunctions = YES;	
		self.initRequiredClass = @"KosmicTask";
		self.initRequiredClassFunction  = @"KosmicTask";
		self.initRequiredScriptFunction = @"KosmicTask";
		
		// Cocoa
		self.initIsCocoaBridge = YES;
		
		// Result representation
		self.initNativeObjectsAsResults = YES;
		self.initNativeObjectsAsYamlSupport = NO;
		
		self.initIsOsaLanguage = YES;
		self.initScriptType = @"AppleScript Cocoa";
		self.initScriptTypeFamily = @"AppleScript";
		self.initTaskRunnerClassName = @"MGSAppleScriptCocoaRunner";
		self.initTaskProcessName = @"KosmicTaskAppleScriptCocoaRunner";
		self.initBuildResultFlags = kMGSScriptSourceRTF | kMGSCompiledScript;
		
		self.initValidForOSVersion = [self validateOSVersion:10 minor:6 bugFix:0];
	}
	
	return self;
}

@end
