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
		self.initExternalExecutorPath = MGS_RUBY_LANG_PATH;
		self.initExternalBuildPath = MGS_RUBY_LANG_PATH;
		self.initLanguageShipsWithOS = YES;
		self.initBuildOptions = @"-c";
		
		// interface
		self.initSupportsDirectParameters = YES;
		
		// Cocoa
		self.initIsCocoaBridge = NO;
		
		// Result representation
		self.initNativeObjectsAsResults = NO;
		self.initNativeObjectsAsYamlSupport = YES;
		
		self.initSourceFileExtensions = [NSArray arrayWithObjects:@"rb", @"ruby", nil];
		
		self.initScriptType = @"Ruby";
		self.initTaskRunnerClassName = @"MGSRubyScriptRunner";
		self.initTaskProcessName = @"KosmicTaskRubyRunner";
		self.initCanIgnoreBuildWarnings = YES;

	}
	
	return self;
}

@end
