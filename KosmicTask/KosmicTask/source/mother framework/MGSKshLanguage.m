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
		self.defExternalExecutorPath = MGS_KSH_LANG_PATH;
		self.defExternalBuildPath = MGS_KSH_LANG_PATH;
		self.initLanguageShipsWithOS = YES;
		self.defBuildOptions = @"-n";
		
		// interface
		self.initSupportsDirectParameters = YES;
		
		self.defSourceFileExtensions = [NSArray arrayWithObjects:@"ksh", nil];	
		self.defScriptType = @"Korn shell";
		self.defTaskRunnerClassName = @"MGSKshScriptRunner";
		self.defTaskProcessName = @"KosmicTaskKshRunner";
		self.initCanIgnoreBuildWarnings = YES;
	}
	
	return self;
}

@end
