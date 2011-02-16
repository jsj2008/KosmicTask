//
//  MGSZshLanguage.m
//  KosmicTask
//
//  Created by Jonathan on 11/11/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#include "MGSZshLanguage.h"

@implementation MGSZshLanguage

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
		self.initExternalExecutorPath = MGS_ZSH_LANG_PATH;
		self.initLanguageShipsWithOS = YES;
		self.initCanBuild = NO;
		
		// interface
		self.initSupportsDirectParameters = YES;
		
		self.initSourceFileExtensions = [NSArray arrayWithObjects:@"zsh", nil];
		self.initScriptType = @"Z shell";
		self.initTaskRunnerClassName = @"MGSZshScriptRunner";
		self.initTaskProcessName	 = @"KosmicTaskZshRunner";
		self.initCanIgnoreBuildWarnings = YES;
	}
	
	return self;
}

@end
