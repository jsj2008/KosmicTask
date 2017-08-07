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
		self.defCanBuild = YES;
		self.initBuildProcessType = kMGSOutOfProcess;
		self.initSeparateSyntaxChecker = YES;
		self.defBuildOptions = @"-p";		
		
		// Result representation
		self.initNativeObjectsAsResults = NO;
		self.initNativeObjectsAsYamlSupport = YES;
		
		self.defSourceFileExtensions = [NSArray arrayWithObjects: @"lua", nil];	
		self.defScriptType = @"Lua";
		self.defScriptTypeFamily = @"Lua";
		self.defTaskRunnerClassName = @"MGSLuaScriptRunner";
		self.defTaskProcessName = @"KosmicTaskLuaRunner";
		self.initCanIgnoreBuildWarnings = YES;
	}
	
	return self;
}

@end
