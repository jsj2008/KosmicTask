//
//  MGSKshLanguage.m
//  KosmicTask
//
//  Created by Jonathan on 11/11/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSKshLanguage.h"

@implementation MGSKshLanguage

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
		self.initExternalExecutorPath = MGS_KSH_LANG_PATH;
		self.initExternalBuildPath = MGS_KSH_LANG_PATH;
		self.initLanguageShipsWithOS = YES;
		self.initBuildOptions = @"-n";
		
		// interface
		self.initSupportsDirectParameters = YES;
		
		self.initSourceFileExtensions = [NSArray arrayWithObjects:@"ksh", nil];	
		self.initScriptType = @"Korn shell";
		self.initTaskRunnerClassName = @"MGSKshScriptRunner";
		self.initTaskProcessName = @"KosmicTaskKshRunner";
		self.initCanIgnoreBuildWarnings = YES;
	}
	
	return self;
}

@end
