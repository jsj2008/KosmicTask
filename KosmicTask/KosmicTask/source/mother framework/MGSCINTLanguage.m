//
//  MGSCINTLanguage.m
//  KosmicTask
//
//  Created by Jonathan on 10/11/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSCINTLanguage.h"


@implementation MGSCINTLanguage


/*
 
 - init
 
 */
- (id)init
{
	self = [super init];
	if (self) {
		
		self.initScriptType = @"CINT C and C++";
		self.initSyntaxDefinition =  @"C++";
		self.initExecutorProcessType = kMGSOutOfProcess;
		self.initExecutorAcceptsOptions = YES;
		self.initExecutableFormat = kMGSSource;
		self.initLanguageShipsWithOS = NO;
		self.initCanBuild = NO;
		self.initExecutorOptions = @"-E -E";
		// interface
		self.initSupportsScriptFunctions = YES;
		self.initRequiredScriptFunction = @"main";
		
		self.initSourceFileExtensions = [NSArray arrayWithObjects: @"c", @"cpp", @"cxx", @"c++", @"cint", nil];
		
		self.initTaskRunnerClassName = @"MGSCINTRunner";
		self.initTaskProcessName = @"KosmicTaskCINTRunner";
		self.initCanIgnoreBuildWarnings = YES;
	}
	
	return self;
}

@end
