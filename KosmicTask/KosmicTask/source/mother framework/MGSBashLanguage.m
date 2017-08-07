//
//  MGSBashLanguage.m
//  KosmicTask
//
//  Created by Jonathan on 11/11/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//
#import "MGSBashLanguage.h"

@implementation MGSBashLanguage

/*
 
 - init
 
 */
- (id)init
{
	self = [super init];
	if (self) {
		self.initSeparateSyntaxChecker = NO;
		self.initExecutorAcceptsOptions = YES;
		self.initBuildAcceptsOptions = NO;
		self.defExternalExecutorPath = MGS_BASH_LANG_PATH;
		self.defExternalBuildPath = MGS_BASH_LANG_PATH;
		self.initLanguageShipsWithOS = YES;
		self.defBuildOptions = @"-n";
		// interface
		self.initSupportsDirectParameters = YES;
		
		self.defSourceFileExtensions = [NSArray arrayWithObjects:@"bash", @"sh", nil];
		
		self.defScriptType = @"Bash shell";
		self.defTaskRunnerClassName = @"MGSBashScriptRunner";
		self.defTaskProcessName = @"KosmicTaskBashRunner";
		self.initCanIgnoreBuildWarnings = YES;
	}
	
	return self;
}

@end
