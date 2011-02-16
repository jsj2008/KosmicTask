//
//  MGSLuaCocoaLanguage.m
//  KosmicTask
//
//  Created by Jonathan on 08/12/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSLuaCocoaLanguage.h"

#define MGS_LUA_COCOA_BUILD_WITH_LUAC

@implementation MGSLuaCocoaLanguage

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
		
		// build
//#ifdef MGS_LUA_COCOA_BUILD_WITH_LUAC
		self.initBuildProcessType = kMGSOutOfProcess;
		self.initSeparateSyntaxChecker = YES;
		self.initBuildOptions = @"-p";		
//#else
//		self.initCanbuild = NO;
//#endif
		// Cocoa
		self.initIsCocoaBridge = YES;
		
		// Result representation
		self.initNativeObjectsAsResults = YES;
		self.initNativeObjectsAsYamlSupport = NO;
		
		// interface
		self.initSupportsScriptFunctions = YES;
		
		self.initSourceFileExtensions = [NSArray arrayWithObjects: @"lua", nil];	
		self.initScriptType = @"Lua Cocoa";
		self.initScriptTypeFamily = @"Lua";
		self.initTaskRunnerClassName = @"MGSLuaCocoaRunner";
		self.initTaskProcessName = @"KosmicTaskLuaCocoaRunner";
		self.initCanIgnoreBuildWarnings = YES;
	}
	
	return self;
}

@end
