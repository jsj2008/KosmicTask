//
//  MGSLuaScriptRunner.m
//  KosmicTask
//
//  Created by Jonathan on 07/03/2011.
//  Copyright 2011 mugginsoft.com. All rights reserved.
//

#import "MGSLuaScriptRunner.h"
#import "MGSLuaLanguage.h"


@implementation MGSLuaScriptRunner

/*
 
 - initWithDictionary
 
 designated initialiser
 
 */
- (id)initWithDictionary:(NSDictionary *)dictionary
{
	if ((self = [super initWithDictionary:dictionary])) {
		self.scriptExecutableExtension = @"lua";
		self.scriptSourceExtension = @"lua";
		
	}
	return self;
}

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSLuaLanguage class];
}


#pragma mark -
#pragma mark Operations

/*
 
 - launchPath
 
 */
- (NSString *)launchPath
{
	return [self pathToExecutable:@"lua"];
}

/*
 
 - buildPath
 
 */
- (NSString *)buildPath
{
	return [self pathToExecutable:@"luac"];
}

/*
 
 - launchEnvironment
 
 */
- (NSMutableDictionary *)launchEnvironment
{
	/*
	 
	 yaml.so is in the frameworks folder
	 
	 Lua yaml was obtained from http://yaml.luaforge.net/
	 
	 Note that the makefile is poor and won't correctly build the yaml.so.
	 I have patched it up.
	 
	 Note that the notes at the above url on how to use the package are quite wrong. The shared object must be loaded as follows. No Path searching takes place.
	 
	 path = "/full/path/to/yaml.so"
	 f = assert(package.loadlib(path, "luaopen_yaml"))
	 f()
	 
	 The above can be placed in a file called yaml.lua and that can be
	 loaded using require("yaml"). This can be place on LUA_PATH.
	 
	 see package.loadfile info here
	 http://www.lua.org/manual/5.1/manual.html
	 
	 */
	// define path to lua modules
	NSString *path = [self executablePath];	// path to executable
	path = [path stringByDeletingLastPathComponent];	// MAC OS
	NSString *luaPath = [path stringByAppendingPathComponent:@"../Resources/Lua/?.lua"];
	NSArray *paths = [NSArray arrayWithObjects:
					  luaPath,
					  @";",
					  nil];
	NSMutableDictionary *env = [super launchEnvironment];
	[self updateEnvironment:env pathkey:@"LUA_PATH" paths:paths separator:@";"];
	
	// define path to yaml shared library
	path = [self executablePath];	// path to executable
	path = [path stringByDeletingLastPathComponent];	// MAC OS
	NSString *yamlPath = [path stringByAppendingPathComponent:@"../Frameworks/yaml.so"];
	paths = [NSArray arrayWithObjects:
					  yamlPath,
					  nil];
	[self updateEnvironment:env pathkey:@"LUA_YAML_LIB_PATH" paths:paths separator:@""];
	
	
	return env;
}

/*
 
 - processBuildResult:
 
 */
- (BOOL)processBuildResult:(NSString *)resultString
{
#pragma unused(resultString)
	
	// syntax check information written to stderr
	NSString *stdErrString = [[NSString alloc] initWithData:self.stderrData encoding:NSUTF8StringEncoding];
	if (stdErrString && [stdErrString length] > 0) {
		[self addError:stdErrString];
	}
	
	// check result for error too
	if (resultString && [resultString length] > 0) {
		[self addError:resultString];
	}
	
	return (!self.error ? YES : NO);
	
}


@end
