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
