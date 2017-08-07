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
		self.defExternalExecutorPath = MGS_PERL_LANG_PATH;
		self.defExternalBuildPath = MGS_PERL_LANG_PATH;
		self.initLanguageShipsWithOS = YES;
		self.defBuildOptions = @"-wc";
		
		// interface
		self.initSupportsDirectParameters = YES;
		
		// Cocoa
		self.initIsCocoaBridge = NO;
		
		// Result representation
		self.initNativeObjectsAsResults = NO;
		self.initNativeObjectsAsYamlSupport = YES;
		
		self.defSourceFileExtensions = [NSArray arrayWithObjects: @"pl", nil];
		
		self.defScriptType = @"Perl";
		self.defTaskRunnerClassName = @"MGSPerlScriptRunner";
		self.defTaskProcessName = @"KosmicTaskPerlRunner";
		self.initCanIgnoreBuildWarnings = YES;
	}
	
	return self;
}

@end
