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
		self.defExternalExecutorPath = MGS_CSH_LANG_PATH;
		self.initLanguageShipsWithOS = YES;
		self.defCanBuild = NO;
		
		// interface
		self.initSupportsDirectParameters = YES;
		
		self.defSourceFileExtensions = [NSArray arrayWithObjects:@"csh", nil];
		
		self.defScriptType = @"C shell";
		self.defTaskRunnerClassName =  @"MGSCshScriptRunner";
		self.defTaskProcessName = @"KosmicTaskCshRunner";
		self.initCanIgnoreBuildWarnings = YES;
	}
	
	return self;
}

@end

