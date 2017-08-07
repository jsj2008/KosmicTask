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
		self.defBuildOptions = @"-nofilelisting -nologo -nosummary -process";
#else
		self.initBuildProcessType = kMGSInProcess;
		self.initSeparateSyntaxChecker = NO;
		self.defBuildOptions = @"";
#endif
		self.initExecutorProcessType = kMGSInProcess;
		self.initExecutorAcceptsOptions = NO;
		self.initBuildAcceptsOptions = NO;
		self.initExecutableFormat = kMGSSource;
		self.initLanguageShipsWithOS = YES;
		self.defCanBuild = YES;
		
		
		// interface
		self.initSupportsScriptFunctions = YES;
		
		// Cocoa
		self.initIsCocoaBridge = NO;
		
		// Result representation
		self.initNativeObjectsAsResults = NO;
		self.initNativeObjectsAsYamlSupport = YES;
		
		self.defSourceFileExtensions = [NSArray arrayWithObjects: @"js", nil];
		
		self.defScriptType = @"JavaScript";
		self.defTaskRunnerClassName = @"MGSJavaScriptRunner";
		self.defTaskProcessName = @"KosmicTaskJavaScriptRunner";
		self.initCanIgnoreBuildWarnings = YES;
	}
	
	return self;
}

@end
