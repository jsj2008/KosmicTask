//
//  MGSRubyScriptManager.m
//  KosmicTask
//
//  Created by Jonathan on 14/05/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSRubyScriptManager.h"
#import "MGSScriptRunner.h"


#import <RubyCocoa/RBRuntime.h>

@interface MGSRubyScriptExecutor : NSObject < MGSScriptExecutor> {
}
@end


@implementation MGSRubyScriptManager

/*
 
 - setupEnvironment
 
 http://sourceforge.jp/projects/rubycocoa/lists/archive/devel/2007-February/000768.html
 
 http://rubycocoa.svn.sourceforge.net/viewvc/rubycocoa/trunk/src/sample/VPRubyPluginEnabler/
 
 */
- (BOOL) setupEnvironment:(MGSScriptRunner *)scriptRunner
{	
	// get path to our ruby entrypoint
	NSString *scriptPath = [[scriptRunner resourcesPath] stringByAppendingPathComponent:@"MGSRubyScriptExecutor.rb"];
	
	int success = RBApplicationInit ([scriptPath UTF8String], scriptRunner.argc, scriptRunner.argv, nil);
	
	if (success != 0) {
		return NO;
	}
	return YES;
}

/*
 
 - executorClassName
 
 */
- (NSString *)executorClassName
{
	return @"MGSRubyScriptExecutor";
}

@end
