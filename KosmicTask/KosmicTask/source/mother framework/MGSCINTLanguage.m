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
		
		self.defScriptType = @"CINT C and C++";
		self.defSyntaxDefinition =  @"C++";
		self.initExecutorProcessType = kMGSOutOfProcess;
		self.initExecutorAcceptsOptions = YES;
		self.initExecutableFormat = kMGSSource;
		self.initLanguageShipsWithOS = NO;
		self.defCanBuild = NO;
		self.defExecutorOptions = @"-E -E";
		// interface
		self.initSupportsScriptFunctions = YES;
		self.defRequiredScriptFunction = @"main";
		
		self.defSourceFileExtensions = [NSArray arrayWithObjects: @"c", @"cpp", @"cxx", @"c++", @"cint", nil];
		
		self.defTaskRunnerClassName = @"MGSCINTRunner";
		self.defTaskProcessName = @"KosmicTaskCINTRunner";
		self.initCanIgnoreBuildWarnings = YES;
	}
	
	return self;
}

@end
