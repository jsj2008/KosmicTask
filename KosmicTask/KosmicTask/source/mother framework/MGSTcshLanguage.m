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
		self.defExternalExecutorPath = MGS_TCSH_LANG_PATH;
		self.initLanguageShipsWithOS = YES;
		self.defCanBuild = NO;
		
		// interface
		self.initSupportsDirectParameters = YES;
		
		self.defSourceFileExtensions = [NSArray arrayWithObjects:@"tcsh", nil];
		self.defScriptType = @"Tenex C shell";
		self.defTaskRunnerClassName = @"MGSTcshScriptRunner";
		self.defTaskProcessName = @"KosmicTaskTcshRunner";
		self.initCanIgnoreBuildWarnings = YES;
	}
	
	return self;
}

@end
