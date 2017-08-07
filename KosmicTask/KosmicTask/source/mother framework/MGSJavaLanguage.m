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
		
		self.defScriptType = @"Java";
		self.initCanIgnoreBuildWarnings = YES;
		self.defTaskProcessName = @"KosmicTaskJavaRunner";
		
		self.defTaskRunnerClassName= @"MGSJavaRunner";
		self.initBuildResultFlags = kMGSCompiledScript;
		
		self.initBuildProcessType = kMGSOutOfProcess;
		self.initExecutorProcessType = kMGSOutOfProcess;
		self.initSeparateSyntaxChecker = NO;
		self.initExecutorAcceptsOptions = YES;
		self.initBuildAcceptsOptions = YES;
		self.initLanguageType = kMGSCompiledLanguage;
		self.initExecutableFormat = kMGSCompiled;
		self.defExternalExecutorPath =  @"/usr/bin/java";
		self.defExecutorOptions = @"";
		self.defExternalBuildPath = @"/usr/bin/javac";
		self.defBuildOptions = @"-Xlint";
		self.initLanguageShipsWithOS = YES;
		
		// interface
		self.initSupportsClasses = YES;
		self.initSupportsClassFunctions = YES;
		self.defRequiredClassFunctionIsStatic = YES;
		self.defRequiredClassFunction = @"main";
		
		// Cocoa
		self.initIsCocoaBridge = NO;
		
		// Result representation
		self.initNativeObjectsAsResults = NO;
		self.initNativeObjectsAsYamlSupport = YES;
		
		self.defSourceFileExtensions = [NSArray arrayWithObjects: @"java", nil];
	}
	
	return self;
}
@end
