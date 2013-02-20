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
		self.initExternalExecutorPath = MGS_BASH_LANG_PATH;
		self.initExternalBuildPath = MGS_BASH_LANG_PATH;
		self.initLanguageShipsWithOS = YES;
		self.initBuildOptions = @"-n";
		// interface
		self.initSupportsDirectParameters = YES;
		
		self.initSourceFileExtensions = [NSArray arrayWithObjects:@"bash", @"sh", nil];
		
		self.initScriptType = @"Bash shell";
		self.initTaskRunnerClassName = @"MGSBashScriptRunner";
		self.initTaskProcessName = @"KosmicTaskBashRunner";
		self.initCanIgnoreBuildWarnings = YES;
        
        // code template processing
        self.initInputArgumentName = kMGSFunctionArgumentName;
        self.initInputArgumentCase = kMGSFunctionArgumentUpperCase;
        self.initInputArgumentStyle = kMGSFunctionArgumentWhitespaceRemoved;
	}
	
	return self;
}

@end
