//
//  MGSRubyCocoaScriptRunner.m
//  KosmicTask
//
//  Created by Jonathan on 29/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSRubyCocoaScriptRunner.h"
#import "MGSRubyScriptManager.h"
#import "MGSRubyCocoaLanguage.h"

/*
  
 note that RubyCocoa does not support GC hence this app
 must not use RC 
 
 */
@implementation MGSRubyCocoaScriptRunner

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSRubyCocoaLanguage class];
}

#pragma mark -
#pragma mark Operations

/*
 
 - execute
 
 */
- (BOOL) execute
{
	
	// setup the process environment
	NSString *resourcePath = [self resourcesPath];
	NSArray *pathArray = [NSArray arrayWithObjects: resourcePath, [self appscriptPath], nil];
	setenv([ENV_RUBY_LIB UTF8String], [[pathArray componentsJoinedByString:@":"] UTF8String], 1);
	
	
	// execute
	return [self executeWithManager:[MGSRubyScriptManager sharedManager]];

}

@end
