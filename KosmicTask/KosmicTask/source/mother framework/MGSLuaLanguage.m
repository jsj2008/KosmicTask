//
//  MGSLuaLanguage.m
//  KosmicTask
//
//  Created by Jonathan on 07/03/2011.
//  Copyright 2011 mugginsoft.com. All rights reserved.
//

#import "MGSLuaLanguage.h"


@implementation MGSLuaLanguage

/*
 
 - init
 
 */
- (id)init
{
	self = [super init];
	if (self) {
		self.initBuildProcessType = kMGSOutOfProcess;
		self.initExecutorProcessType = kMGSOutOfProcess;
		self.initSeparateSyntaxChecker = YES;
		self.initExecutorAcceptsOptions = YES;
		self.initBuildAcceptsOptions = NO;
		self.initExecutableFormat = kMGSSource;
		self.initLanguageShipsWithOS = NO;
		
		// interface
		self.initSupportsDirectParameters = YES;

		// build
		self.initCanBuild = YES;
		self.initBuildProcessType = kMGSOutOfProcess;
		self.initSeparateSyntaxChecker = YES;
		self.initBuildOptions = @"-p";		
		
		// Result representation
		self.initNativeObjectsAsResults = NO;
		self.initNativeObjectsAsYamlSupport = NO;
		
		self.initSourceFileExtensions = [NSArray arrayWithObjects: @"lua", nil];	
		self.initScriptType = @"Lua";
		self.initScriptTypeFamily = @"Lua";
		self.initTaskRunnerClassName = @"MGSLuaScriptRunner";
		self.initTaskProcessName = @"KosmicTaskLuaRunner";
		self.initCanIgnoreBuildWarnings = YES;
	}
	
	return self;
}

@end
