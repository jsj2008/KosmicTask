//
//  MGSRubyScriptRunner.m
//  KosmicTask
//
//  Created by Jonathan on 30/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//
#import "MGSRubyScriptRunner.h"
#import "MGSRubyLanguage.h"

#define APPSCRIPT_PATH_10_6 @"Ruby/rb-appscript/lib-osx10.6"
#define APPSCRIPT_PATH_10_7 @"Ruby/rb-appscript/lib-osx10.7"
#define APPSCRIPT_PATH APPSCRIPT_PATH_10_7

@implementation MGSRubyScriptRunner

/*
 
 - initWithDictionary
 
 designated initialiser
 
 */
- (id)initWithDictionary:(NSDictionary *)dictionary
{
	if ((self = [super initWithDictionary:dictionary])) {
		self.scriptExecutableExtension = @"rb";
		self.scriptSourceExtension = @"rb";

	}
	return self;
}

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSRubyLanguage class];
}

#pragma mark -
#pragma mark Operations

/*
 
 - parseCompileResult:
 
 */
- (BOOL) processBuildResult:(NSString *)resultString
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
 
 - appscriptPath
 
 */
- (NSString *)appscriptPath
{
	// set default appscript root path
	NSString *path = [self pathToResource:APPSCRIPT_PATH];
	
    // check for other system versions
    if ([GTMSystemVersion isSnowLeopard]) {
        path = [self pathToResource:APPSCRIPT_PATH_10_6];
    }
    
	return path;
}

/*
 
 - launchEnvironment
 
 */
- (NSMutableDictionary *)launchEnvironment
{
	/*
	 http://www.rubyinside.com/how-to-create-a-ruby-extension-in-c-in-under-5-minutes-100.html
	 
	 add rb-appscript bundle path to environment
	 
	 note that we also require ae.bundle
	 
	 this is a ruby extension module that gets loaded into the ruby runtime
	 environment and provides the rb-AE bridge
	 
	 this has to be built for the target OS version.
	 	 
	 two ways to install - download and build or using gems
	 
	 DOWNLOAD and BUILD
	 
	 get source from (need the zip not the gem)
	 http://rubyforge.org/projects/rb-appscript/
	 
	 rb lib installs into
	  /Library/Ruby/Site/1.8
	 on 10.6 ae.bundle is installed into /library/ruby/site/1.8/universal-darwin10.0
     on 10.6 ae.bundle is installed into /library/ruby/site/1.8/universal-darwin11.0
     
	 installing ae.bundle into the APPSCRIPT_PATH_10_6 path along with the other
	 components seems to work: ie lib-osx10.6
	 _aem
	 _appscript
	 ae.bundle
	 aem.rb
	 appscript.rp
	 kae.rb
	 osax.rb
	 
	 GEMS
	 
	 also using the gem installation (as opposed to a download, build, install)
	 in /library/ruby/site/1.8/gems/rb-appscript-0.5.3
	 seems to work as ae.bundle is installed there.
	 the only caveat is that scripts must begin with:
	 require 'rubygems'
	 
	 when installing the gem it still has to compile ae.bundle
	 
	 */
	NSMutableDictionary *env = [super launchEnvironment];
	NSArray *paths = [NSArray arrayWithObjects:
					  [self appscriptPath],
					  [self pathToResource:@"Ruby"],
					  nil];
	[self updateEnvironment:env pathkey:ENV_RUBY_LIB paths:paths];
	
	return env;
}


@end
