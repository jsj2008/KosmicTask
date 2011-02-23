//
//  MGSPythonScriptRunner.m
//  KosmicTask
//
//  Created by Jonathan on 29/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSPythonScriptRunner.h"
#import "MGSPythonLanguage.h"

#define APPSCRIPT_EGG_10_6 @"Python/appscript-1.0.0-py2.6-macosx-10.6-universal.egg"

@implementation MGSPythonScriptRunner

/*
 
 - initWithDictionary
 
 designated initialiser
 
 */
- (id)initWithDictionary:(NSDictionary *)dictionary
{
	if ((self = [super initWithDictionary:dictionary])) {
		self.scriptExecutableExtension = @"py";
		self.scriptSourceExtension = @"py";
		
	}
	return self;
}

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSPythonLanguage class];
}


#pragma mark -
#pragma mark Operations

/*
 
 - staticAnalyserPath
 
 */
- (NSString *)staticAnalyserPath
{
	// pyflakes static analyser root path
	NSString *path = [self pathToResource:@"Python/Pyflakes"];
		
	return path;
}

/*
 
 - appscriptPath
 
 */
- (NSString *)appscriptPath
{
	// appscript root path
	NSString *path = [self pathToResource:APPSCRIPT_EGG_10_6];
	
	return path;
}

/*
 
 - buildPath
 
  python has no syntax check option so we use pyflakes.
  other python static analysers are availble by pyflakes is the simplest.
 
 */
- (NSString *)buildPath
{
	// path to pyflakes binary
	NSString *saPath = [[self staticAnalyserPath] stringByAppendingPathComponent:@"/bin/pyflakes"];
	
	return saPath;
}

/*
 
 - launchEnvironment
 
 */
- (NSMutableDictionary *)launchEnvironment
{
	/*
	 
	 to avoid installing pyflakes we set the PYTHONPATH env variable
	 to include our static analyser path
	 
	 we also need to include support for py-appscript
	 
	 this can be installed as an egg package using
	 sudo easy_install appscript
	 
	 this will download the sources and build the egg into
	 /Library/Python/2.6/site-packages/appscript-x.xx.x-py2.6-macosx-10.6-universal.egg
	 
	 we can extract it from there and include in our project.
	 note that the installation builds the C based AE bridge that is loaded into the
	 python runtime. this approach is very similar to using ruby gems
	 
	 alternatively we can download the source from http://pypi.python.org/pypi/appscript/
	 this builds the ae bridge module and installs it into the Python path
	 
	 we use the egg here but in ruby we do not use the gem
	 
	 */
	NSString *yamlPath = [self pathToResource:@"Python/yaml"];
	NSString *pythonPath = [self pathToResource:@"Python"];
	NSMutableDictionary *env = [super launchEnvironment];
	NSArray *paths = [NSArray arrayWithObjects:[self staticAnalyserPath],
												[self appscriptPath],
												yamlPath,
												pythonPath,
												nil];
	[self updateEnvironment:env pathkey:ENV_PYTHON_PATH paths:paths];

	return env;
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
