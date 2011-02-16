//
//  MGSPerlScriptRunner.m
//  KosmicTask
//
//  Created by Jonathan on 30/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSPerlScriptRunner.h"
#import "MGSPerlLanguage.h"

@implementation MGSPerlScriptRunner

#pragma mark -
#pragma mark Operations

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSPerlLanguage class];
}

/*
 
 - parseCompileResult:
 
 
 
 returns on stderr:
 
 filename.pl Syntax OK 
 
 or
 
 error description filename.pl
 
 

 */
- (BOOL) processCompileResult:(NSString *)resultString
{
#pragma unused(resultString)
	
	// syntax check information written to stderr
	NSString *stdErrString = [[NSString alloc] initWithData:self.stderrData encoding:NSUTF8StringEncoding];
	
	if (stdErrString && [stdErrString length] > 0) {
		
		// successful compile generates result
		NSRange range = [stdErrString rangeOfString:@"syntax ok" options:NSCaseInsensitiveSearch];
		if (range.location == NSNotFound) {
			self.error = stdErrString;
		}
	}
	
	return (!self.error ? YES : NO);
	
}

/*
 
 - launchEnvironment
 
 */
- (NSMutableDictionary *)launchEnvironment
{
	/*
	 
	 Module locations
	 http://www.wellho.net/mouth/588_Changing-INC-where-Perl-loads-its-modules.html
	 
	 
	 Module mechanics
	 http://world.std.com/~swmcd/steven/perl/module_mechanics.html#TOC24.5
	 
	 */
	
	NSString *yamlModulePath = [self pathToResource:@"Perl/perl5"];
	NSString *perlPath = [self pathToResource:@"Perl"];
	
	NSMutableDictionary *env = [super launchEnvironment];
	NSArray *paths = [NSArray arrayWithObjects: yamlModulePath, perlPath, 
					  nil];
	
	[self updateEnvironment:env pathkey:@"PERL5LIB" paths:paths];
	
	return env;
}
@end
