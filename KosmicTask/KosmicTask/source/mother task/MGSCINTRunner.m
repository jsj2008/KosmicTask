//
//  MGSCINTRunner.m
//  KosmicTask
//
//  Created by Jonathan on 07/08/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSCINTRunner.h"
#import "TaskRunner.h"
#import <dlfcn.h>
#import "MGSCINTLanguage.h"

@implementation MGSCINTRunner

/*
 
 - initWithDictionary
 
 designated initialiser
 
 */
- (id)initWithDictionary:(NSDictionary *)dictionary
{
	if ((self = [super initWithDictionary:dictionary])) {
		self.scriptExecutableExtension = @"c";
		self.scriptSourceExtension = @"c";
		
	}
	return self;
}

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSCINTLanguage class];
}

#pragma mark -
#pragma mark Operations

/*
 
 - launchPath
 
 */
- (NSString *)launchPath
{
	//
	// launch path is in the bundle
	//
	NSString *path = [self executablePath]; // MacOS
	path = [path stringByDeletingLastPathComponent];
	path = [path stringByAppendingPathComponent:@"../Frameworks/cint.framework/bin/cint"];
	
	return path;
}

/*
 
 - executeOptions
 
 */
- (NSMutableArray *)executeOptions
{
	NSMutableArray *options = [super executeOptions];
	
	// add option to quit interpreter if main missing or error
	[options addObject:@"-o1"];
	
	return options;
}

/*
 
 - launchEnvironment
 
 using CINT executable interpreter has isses becauses it enters interactive mode
 if there is no main() or an error in main().
 
 */
- (NSMutableDictionary *)launchEnvironment
{
	NSString *path = [self executablePath]; // MacOS
	path = [path stringByDeletingLastPathComponent];
	path = [path stringByAppendingPathComponent:@"../Frameworks/cint.framework"];
		
	NSMutableDictionary *env = [super launchEnvironment];
	[self updateEnvironment:env pathkey:@"PATH" paths:[NSArray arrayWithObjects:[path stringByAppendingPathComponent:@"bin"], nil]];
	[self updateEnvironment:env pathkey:@"DYLD_LIBRARY_PATH" paths:[NSArray arrayWithObjects:[path stringByAppendingPathComponent:@"lib"], nil]];
	[self updateEnvironment:env pathkey:@"CINTSYSDIR" paths:[NSArray arrayWithObjects:path, nil]];
	
	return env;
}

/*
 
 - execute
 
 The dynamic loader searches for libraries in the directories specified by a set of 
 environment variables and the process’s current working directory. These variables, 
 when defined, must contain a colon-separated list of pathnames (absolute or relative) 
 in which the dynamic loader searches for libraries. Table 1 lists the variables.
 
 Note that simply placing the library relative to the calling executable is not enough.
 
 The working directory for the task is NOT the executable folder.
 
 see http://developer.apple.com/mac/library/documentation/DeveloperTools/Conceptual/DynamicLibraries/100-Articles/DynamicLibraryUsageGuidelines.html
 
 for this to work the DYLD_LIBRARY_PATH may need to be established before
 this task is started - though perhps not as the code uses dlopen() rather than compile time linking.
 */
/*
- (BOOL) execute
{
	NSString *path = [self executablePath]; // MacOS
	path = [path stringByDeletingLastPathComponent];
	path = [path stringByAppendingPathComponent:@"../Frameworks/cint"];

	//setenv("PATH", [[path stringByAppendingPathComponent:@"bin"] UTF8String], 1);
	//setenv("DYLD_LIBRARY_PATH", [[path stringByAppendingPathComponent:@"lib"] UTF8String], 1);
	//setenv("CINTSYSDIR", [path UTF8String], 1);
	
	NSLog(@"env DYLD_LIBRARY_PATH = %s", getenv("DYLD_LIBRARY_PATH"));
	
	// get script parameter array
	NSArray *paramArray = [self ScriptParametersWithError:YES];
	if (!paramArray) return NO;
	
	// get executable script data
	NSData *executableData = [self scriptExecutableDataWithError:YES];
	if (!executableData) return NO;
	
	// write task data to file
	NSString *scriptPath = [self writeScriptDataToWorkingFile:executableData withExtension:self.scriptExecutableExtension];
	if (!scriptPath) return NO;
	
	NSString *command = [NSString stringWithFormat:@"cint -E -E %@", scriptPath];
	G__init_cint((char *)[command UTF8String]);
	G__scratch_all();
	
	NSLog(@"BOO");
	return YES;

}
*/

/*
 
 - build
 
 */
- (BOOL) build
{
	return YES;
}

@end
