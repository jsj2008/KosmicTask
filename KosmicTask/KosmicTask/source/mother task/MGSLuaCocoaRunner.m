//
//  MGSLuaCocoaRunner.m
//  KosmicTask
//
//  Created by Jonathan on 08/12/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSLuaCocoaRunner.h"
#import "MGSLuaScriptManager.h"
#import "MGSLuaCocoaLanguage.h"

@implementation MGSLuaCocoaRunner


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
	return [MGSLuaCocoaLanguage class];
}

/*
 
 - execute
 
 */
- (BOOL) execute
{
	
	// execute
	return [self executeWithManager:[MGSLuaScriptManager sharedManager]];
}

/*
 
 - buildPath
 
 */
- (NSString *)buildPath
{
	NSString *path = [self executablePath];	// path to executable
	path = [path stringByDeletingLastPathComponent]; 
	//path = [path stringByAppendingPathComponent:@"luac"];
	path = [path stringByAppendingPathComponent:@"../Frameworks/LuaCocoa.framework/Versions/Current/Tools/luac"];
	
	return path;
}

/*
 
 - processBuildResult:
 
 */
- (BOOL) processBuildResult:(NSString *)resultString
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
