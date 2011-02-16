//
//  MGSJavam
//  KosmicTask
//
//  Created by Jonathan on 10/11/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSJavaLanguage.h"


@implementation MGSJavaLanguage

/*
 
 - init
 
 */
- (id)init
{
	self = [super init];
	if (self) {
		
		self.initScriptType = @"Java";
		self.initCanIgnoreBuildWarnings = YES;
		self.initTaskProcessName = @"KosmicTaskJavaRunner";
		
		self.initTaskRunnerClassName= @"MGSJavaRunner";
		self.initBuildResultFlags = kMGSCompiledScript;
		
		self.initBuildProcessType = kMGSOutOfProcess;
		self.initExecutorProcessType = kMGSOutOfProcess;
		self.initSeparateSyntaxChecker = NO;
		self.initExecutorAcceptsOptions = YES;
		self.initBuildAcceptsOptions = YES;
		self.initLanguageType = kMGSCompiledLanguage;
		self.initExecutableFormat = kMGSCompiled;
		self.initExternalExecutorPath =  @"/usr/bin/java";
		self.initExecutorOptions = @"";
		self.initExternalBuildPath = @"/usr/bin/javac";
		self.initBuildOptions = @"-Xlint";
		self.initLanguageShipsWithOS = YES;
		
		// interface
		self.initSupportsClasses = YES;
		self.initSupportsClassFunctions = YES;
		self.initRequiredClassFunctionIsStatic = YES;
		self.initRequiredClassFunction = @"main";
		
		// Cocoa
		self.initIsCocoaBridge = NO;
		
		// Result representation
		self.initNativeObjectsAsResults = NO;
		self.initNativeObjectsAsYamlSupport = YES;
		
		self.initSourceFileExtensions = [NSArray arrayWithObjects: @"java", nil];
	}
	
	return self;
}
@end
