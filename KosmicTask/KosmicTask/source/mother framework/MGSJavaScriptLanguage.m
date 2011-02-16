//
//  MGSJavaScriptLanguage.m
//  KosmicTask
//
//  Created by Jonathan on 11/11/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSJavaScriptLanguage.h"


@implementation MGSJavaScriptLanguage

/*
 
 - init
 
 */
- (id)init
{
	self = [super init];
	if (self) {
#if ( TARGET_CPU_X86 | TARGET_CPU_X86_64 )
		self.initBuildProcessType = kMGSOutOfProcess;
		self.initSeparateSyntaxChecker = YES;
		self.initBuildOptions = @"-nofilelisting -nologo -nosummary -process";
#else
		self.initBuildProcessType = kMGSInProcess;
		self.initSeparateSyntaxChecker = NO;
		self.initBuildOptions = @"";
#endif
		self.initExecutorProcessType = kMGSInProcess;
		self.initExecutorAcceptsOptions = NO;
		self.initBuildAcceptsOptions = NO;
		self.initExecutableFormat = kMGSSource;
		self.initLanguageShipsWithOS = YES;
		self.initCanBuild = YES;
		
		
		// interface
		self.initSupportsScriptFunctions = YES;
		
		// Cocoa
		self.initIsCocoaBridge = NO;
		
		// Result representation
		self.initNativeObjectsAsResults = NO;
		self.initNativeObjectsAsYamlSupport = YES;
		
		self.initSourceFileExtensions = [NSArray arrayWithObjects: @"js", nil];
		
		self.initScriptType = @"JavaScript";
		self.initTaskRunnerClassName = @"MGSJavaScriptRunner";
		self.initTaskProcessName = @"KosmicTaskJavaScriptRunner";
		self.initCanIgnoreBuildWarnings = YES;
	}
	
	return self;
}

@end
