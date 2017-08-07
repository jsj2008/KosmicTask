//
//  MGSPythonObjCLanguage.m
//  KosmicTask
//
//  Created by Jonathan on 11/11/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSPythonObjCLanguage.h"


@implementation MGSPythonObjCLanguage

/*
 
 - init
 
 */
- (id)init
{
	self = [super init];
	if (self) {
		self.initBuildProcessType = kMGSOutOfProcess;
		self.initExecutorProcessType = kMGSInProcess;
		self.initSeparateSyntaxChecker = YES;
		self.initExecutorAcceptsOptions = NO;
		self.initBuildAcceptsOptions = NO;
		self.initExecutableFormat = kMGSSource;
		self.initLanguageShipsWithOS = YES;
		self.defCanBuild = YES;
		
		// interface
		self.initSupportsScriptFunctions = YES;
		self.initSupportsClasses = YES;
		self.initSupportsClassFunctions = YES;
		self.defDefaultScriptFunction = @"kosmictask";
		self.defDefaultClass = @"KosmicTask";
		self.defDefaultClassFunction = @"kosmictask";
		
		// Cocoa
		self.initIsCocoaBridge = YES;
		
		// Result representation
		self.initNativeObjectsAsResults = YES;
		self.initNativeObjectsAsYamlSupport = NO;
		
		// extension should default to python plugin
		self.defSourceFileExtensions = [NSArray arrayWithObjects: nil];
		
		self.defScriptType = @"Python Cocoa";
		self.defScriptTypeFamily = @"Python";
		self.defTaskRunnerClassName = @"MGSPythonObjCScriptRunner";
		self.defTaskProcessName = @"KosmicTaskPythonObjCRunner";
		self.initCanIgnoreBuildWarnings = YES;
	}
	
	return self;	
}
@end
