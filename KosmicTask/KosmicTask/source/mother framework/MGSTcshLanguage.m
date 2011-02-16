//
//  MGSTcshLanguage.m
//  KosmicTask
//
//  Created by Jonathan on 11/11/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSTcshLanguage.h"

@implementation MGSTcshLanguage

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
		self.initExternalExecutorPath = MGS_TCSH_LANG_PATH;
		self.initLanguageShipsWithOS = YES;
		self.initCanBuild = NO;
		
		// interface
		self.initSupportsDirectParameters = YES;
		
		self.initSourceFileExtensions = [NSArray arrayWithObjects:@"tcsh", nil];
		self.initScriptType = @"Tenex C shell";
		self.initTaskRunnerClassName = @"MGSTcshScriptRunner";
		self.initTaskProcessName = @"KosmicTaskTcshRunner";
		self.initCanIgnoreBuildWarnings = YES;
	}
	
	return self;
}

@end
