//
//  MGSRubyCocoaLanguage.m
//  KosmicTask
//
//  Created by Jonathan on 10/11/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSRubyCocoaLanguage.h"


@implementation MGSRubyCocoaLanguage

/*
 
 - init
 
 */
- (id)init
{
	self = [super init];
	if (self) {
		self.initBuildProcessType = kMGSOutOfProcess;
		self.initExecutorProcessType = kMGSInProcess;
		self.initSeparateSyntaxChecker = NO;
		self.initExecutorAcceptsOptions = NO;
		self.initBuildAcceptsOptions = YES;
		self.initExecutableFormat = kMGSSource;
		self.initLanguageShipsWithOS = YES;
		self.initExternalBuildPath = @"/usr/bin/ruby";
		
		// interface
		self.initSupportsScriptFunctions = YES;
		self.initSupportsClasses = YES;
		self.initSupportsClassFunctions = YES;
		self.initDefaultScriptFunction = @"kosmictask";
		self.initDefaultClass = @"KosmicTask";
		self.initDefaultClassFunction = @"kosmictask";
		
		// Cocoa
		self.initIsCocoaBridge = YES;
		
		// Result representation
		self.initNativeObjectsAsResults = YES;
		self.initNativeObjectsAsYamlSupport = NO;
		
		// extension should default to ruby plugin
		self.initSourceFileExtensions = [NSArray arrayWithObjects: nil];
		
		self.initScriptType = @"Ruby Cocoa";
		self.initScriptTypeFamily = @"Ruby";
		self.initSyntaxDefinition = @"Ruby";
		self.initTaskRunnerClassName = @"MGSRubyCocoaScriptRunner";
		self.initTaskProcessName = @"KosmicTaskRubyCocoaRunner";
		self.initCanIgnoreBuildWarnings = YES;
		
	}
		
	return self;
}
@end
