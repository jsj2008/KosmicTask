//
//  MGSF_ScriptLanguage.m
//  KosmicTask
//
//  Created by Jonathan on 11/11/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSF_ScriptLanguage.h"


@implementation MGSF_ScriptLanguage

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
		self.initExecutableFormat = kMGSSource;
		self.initLanguageShipsWithOS = NO;
		self.defCanBuild = YES;
		
		// Cocoa
		self.initIsCocoaBridge = YES;
		
		// Result representation
		self.initNativeObjectsAsResults = YES;
		self.initNativeObjectsAsYamlSupport = NO;
		
		// interface
		self.initSupportsDirectParameters = YES;
		self.defScriptType = @"F-Script Cocoa";
		self.defScriptTypeFamily = @"F-Script";
		self.defTaskRunnerClassName = @"MGSFScriptRunner";
		self.defTaskProcessName = @"KosmicTaskF-ScriptRunner";
		self.initCanIgnoreBuildWarnings = YES;
	}
	
	return self;
}

@end
