//
//  MGSPhpLanguage.m
//  KosmicTask
//
//  Created by Jonathan on 11/11/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSPhpLanguage.h"

@implementation MGSPhpLanguage

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
		self.initExternalExecutorPath = MGS_PHP_LANG_PATH;
		self.initExternalBuildPath = MGS_PHP_LANG_PATH;
		self.initLanguageShipsWithOS = YES;
		self.initBuildOptions = @"--syntax-check";
		
		// interface
		self.initSupportsDirectParameters = YES;
		
		// Cocoa
		self.initIsCocoaBridge = NO;
		
		// Result representation
		self.initNativeObjectsAsResults = NO;
		self.initNativeObjectsAsYamlSupport = YES;
		
		self.initSourceFileExtensions = [NSArray arrayWithObjects:@"php", nil];
		self.initScriptType = @"PHP";
		self.initTaskRunnerClassName =  @"MGSPhpScriptRunner";
		self.initTaskProcessName = @"KosmicTaskPhpRunner";
		self.initCanIgnoreBuildWarnings = YES;
	}
	
	return self;
}

@end
