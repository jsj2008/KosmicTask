//
//  MGSRubyLanguage.m
//  KosmicTask
//
//  Created by Jonathan on 11/11/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//
#import "MGSRubyLanguage.h"

@implementation MGSRubyLanguage

/*
 
 - init
 
 */
- (id)init
{
	self = [super init];
	if (self) {
		self.initBuildProcessType = kMGSOutOfProcess;
		self.initExecutorProcessType = kMGSOutOfProcess;
		self.initSeparateSyntaxChecker = NO;
		self.initExecutorAcceptsOptions = YES;
		self.initBuildAcceptsOptions = NO;
		self.initExecutableFormat = kMGSSource;
		self.defExternalExecutorPath = MGS_RUBY_LANG_PATH;
		self.defExternalBuildPath = MGS_RUBY_LANG_PATH;
		self.initLanguageShipsWithOS = YES;
		self.defBuildOptions = @"-c";
		
		// interface
		self.initSupportsDirectParameters = YES;
		
		// Cocoa
		self.initIsCocoaBridge = NO;
		
		// Result representation
		self.initNativeObjectsAsResults = NO;
		self.initNativeObjectsAsYamlSupport = YES;
		
		self.defSourceFileExtensions = [NSArray arrayWithObjects:@"rb", @"ruby", nil];
		
		self.defScriptType = @"Ruby";
		self.defTaskRunnerClassName = @"MGSRubyScriptRunner";
		self.defTaskProcessName = @"KosmicTaskRubyRunner";
		self.initCanIgnoreBuildWarnings = YES;

	}
	
	return self;
}

@end
