//
//  MGSTclshLanguage.m
//  KosmicTask
//
//  Created by Jonathan on 11/11/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSTclshLanguage.h"

@implementation MGSTclshLanguage

/*
 
 - init
 
 */
- (id)init
{
	self = [super init];
	if (self) {
		self.initExecutorProcessType = kMGSOutOfProcess;
		self.initExecutorAcceptsOptions = YES;
		self.initExecutableFormat = kMGSSource;
		self.initExternalExecutorPath = MGS_TCLSH_LANG_EXECUTE_PATH;
		self.initLanguageShipsWithOS = YES;
		self.initCanBuild = NO;
		
		// interface
		self.initSupportsDirectParameters = YES;
		
		// Cocoa
		self.initIsCocoaBridge = NO;
		
		// Result representation
		self.initNativeObjectsAsResults = NO;
		self.initNativeObjectsAsYamlSupport = YES;
		
		self.initSourceFileExtensions = [NSArray arrayWithObjects:@"tclsh", nil];
		self.initScriptType = @"Tcl";
		self.initScriptTypeFamily = @"Tcl";
		self.initSyntaxDefinition = @"Tcl/Tk";
		self.initTaskRunnerClassName = @"MGSTclshScriptRunner";
		self.initTaskProcessName = @"KosmicTaskTclshRunner";
		self.initCanIgnoreBuildWarnings = YES;
	}
	
	return self;
}

@end
