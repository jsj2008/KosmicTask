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
		self.defExternalExecutorPath = MGS_ZSH_LANG_PATH;
		self.initLanguageShipsWithOS = YES;
		self.defCanBuild = NO;
		
		// interface
		self.initSupportsDirectParameters = YES;
		
		self.defSourceFileExtensions = [NSArray arrayWithObjects:@"zsh", nil];
		self.defScriptType = @"Z shell";
		self.defTaskRunnerClassName = @"MGSZshScriptRunner";
		self.defTaskProcessName	 = @"KosmicTaskZshRunner";
		self.initCanIgnoreBuildWarnings = YES;
	}
	
	return self;
}

@end
