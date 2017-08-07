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
		self.defExternalExecutorPath = MGS_TCLSH_LANG_EXECUTE_PATH;
		self.initLanguageShipsWithOS = YES;
		self.defCanBuild = NO;
		
		// interface
		self.initSupportsDirectParameters = YES;
		
		// Cocoa
		self.initIsCocoaBridge = NO;
		
		// Result representation
		self.initNativeObjectsAsResults = NO;
		self.initNativeObjectsAsYamlSupport = YES;
		
		self.defSourceFileExtensions = [NSArray arrayWithObjects:@"tclsh", nil];
		self.defScriptType = @"Tcl";
		self.defScriptTypeFamily = @"Tcl";
		self.defSyntaxDefinition = @"Tcl/Tk";
		self.defTaskRunnerClassName = @"MGSTclshScriptRunner";
		self.defTaskProcessName = @"KosmicTaskTclshRunner";
		self.initCanIgnoreBuildWarnings = YES;
	}
	
	return self;
}

@end
