//
//  MGSPythonLanguage.m
//  KosmicTask
//
//  Created by Jonathan on 11/11/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSPythonLanguage.h"


@implementation MGSPythonLanguage

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
		self.initExternalExecutorPath = MGS_PYTHON_LANG_PATH;
		self.initLanguageShipsWithOS = YES;
		self.initCanBuild = YES;
		
		// interface
		self.initSupportsDirectParameters = YES;
		
		// Cocoa
		self.initIsCocoaBridge = NO;
		
		// Result representation
		self.initNativeObjectsAsResults = NO;
		self.initNativeObjectsAsYamlSupport = YES;
		
		self.initSourceFileExtensions = [NSArray arrayWithObjects: @"py", nil];	
		self.initScriptType = @"Python";
		self.initTaskRunnerClassName =  @"MGSPythonScriptRunner";
		self.initTaskProcessName = @"KosmicTaskPythonRunner";
		self.initCanIgnoreBuildWarnings = YES;
	}
	
	return self;
}
@end
