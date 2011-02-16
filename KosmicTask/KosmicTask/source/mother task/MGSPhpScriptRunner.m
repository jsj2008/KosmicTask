//
//  MGSPhpScriptRunner.m
//  KosmicTask
//
//  Created by Jonathan on 30/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSPhpScriptRunner.h"
#import "MGSPhpLanguage.h"

@implementation MGSPhpScriptRunner

#pragma mark -
#pragma mark Operations

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSPhpLanguage class];
}

/*
 
 - executeOptions
 
 */
- (NSMutableArray *)executeOptions
{
	NSMutableArray *options = [super executeOptions];

	// add option to execute appended file
	[options addObject: @"-f"];
	
	return options; 
	
}

/*
 
 - beginScriptExecutableSource
 
 */
- (NSString *)beginScriptExecutableSource
{
	/*
	 
	 path to the YAML kit - spyc/spyc.php
	 
	 http://code.google.com/p/spyc/
	 
	 
	 Using Spyc is trivial:
	 
	 <?php
	 require_once "spyc.php";
	 $Data = Spyc::YAMLLoad('spyc.yaml');
	 or (if you prefer functional syntax)
	 
	 <?php
	 require_once "spyc.php";
	 $Data = spyc_load_file('spyc.yaml');
	 
	 
	 $yaml = Spyc::YAMLDump($array);
	 
	 Warning: require_once(spyc.php): failed to open stream: 
	 No such file or directory in /Users/Jonathan/Library/Caches/com.mugginsoft.kosmictaskserver.files/MGSTempStorage.exEVnuV7Qy/KosmicTask on line 16
	 
	 Fatal error: require_once(): Failed opening required 'spyc.php' (include_path='.:/usr/lib/php') in 
	 /Users/Jonathan/Library/Caches/com.mugginsoft.kosmictaskserver.files/MGSTempStorage.exEVnuV7Qy/KosmicTask on line 16
	 
	 
	 */
	
	// we need to set the include path.
	// no ENV variable option.
	// And don't want to start fiddling with php.ini settings.
	NSString *phpPath = [self pathToResource:@"PHP"];
	NSString *source = [NSString stringWithFormat: @"<?php set_include_path(get_include_path() . PATH_SEPARATOR .'%@'); ?>", phpPath];
	return source;
}

/*
 
 - scriptExecutableDataWithError:
 
 */

- (NSData *)scriptExecutableDataWithError:(BOOL)genError
{
	NSString *source = [self scriptExecutableSourceWithError:genError];
	
	if (!source) {
		return [super scriptExecutableDataWithError:genError];
	}
	
	// prefix startup source
	NSString *startup = [self beginScriptExecutableSource];
	NSString *newSource = [NSString stringWithFormat:@"%@\n%@", startup, source];
	
	// return new source data
	return [newSource dataUsingEncoding:NSUTF8StringEncoding];
}

/*
 
 - parseCompileResult:
 
 */
- (BOOL) processBuildResult:(NSString *)resultString
{

	// successful compile generates result
	NSRange range = [resultString rangeOfString:@"no syntax errors detected" options:NSCaseInsensitiveSearch];
	if (range.location == NSNotFound) {
		self.error = resultString;
	}
	
	return [super processBuildResult:nil];
	
}

@end
