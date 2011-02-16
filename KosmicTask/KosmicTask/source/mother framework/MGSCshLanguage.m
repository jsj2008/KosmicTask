//
//  MGSCshLanguage.m
//  KosmicTask
//
//  Created by Jonathan on 11/11/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#include "MGSCshLanguage.h"

@implementation MGSCshLanguage

/*
 
 - init
 
 */
- (id)init
{
	self = [super init];
	if (self) {
		self.initExecutorProcessType = kMGSOutOfProcess;
		self.initExecutorAcceptsOptions = YES;
		self.initExecutableFormat = kMGSSource;
		self.initExternalExecutorPath = MGS_CSH_LANG_PATH;
		self.initLanguageShipsWithOS = YES;
		self.initCanBuild = NO;
		
		// interface
		self.initSupportsDirectParameters = YES;
		
		self.initSourceFileExtensions = [NSArray arrayWithObjects:@"csh", nil];
		
		self.initScriptType = @"C shell";
		self.initTaskRunnerClassName =  @"MGSCshScriptRunner";
		self.initTaskProcessName = @"KosmicTaskCshRunner";
		self.initCanIgnoreBuildWarnings = YES;
	}
	
	return self;
}

@end

