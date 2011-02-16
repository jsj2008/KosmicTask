//
//  MGSPerlLanguage.m
//  KosmicTask
//
//  Created by Jonathan on 11/11/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//


#import "MGSPerlLanguage.h"

@implementation MGSPerlLanguage

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
		self.initExternalExecutorPath = MGS_PERL_LANG_PATH;
		self.initExternalBuildPath = MGS_PERL_LANG_PATH;
		self.initLanguageShipsWithOS = YES;
		self.initBuildOptions = @"-wc";
		
		// interface
		self.initSupportsDirectParameters = YES;
		
		// Cocoa
		self.initIsCocoaBridge = NO;
		
		// Result representation
		self.initNativeObjectsAsResults = NO;
		self.initNativeObjectsAsYamlSupport = YES;
		
		self.initSourceFileExtensions = [NSArray arrayWithObjects: @"pl", nil];
		
		self.initScriptType = @"Perl";
		self.initTaskRunnerClassName = @"MGSPerlScriptRunner";
		self.initTaskProcessName = @"KosmicTaskPerlRunner";
		self.initCanIgnoreBuildWarnings = YES;
	}
	
	return self;
}

@end
