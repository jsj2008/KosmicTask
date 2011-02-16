//
//  MGSJavaRunner.m
//  KosmicTask
//
//  Created by Jonathan on 01/08/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

/*
 
 java into http://www.cs.swarthmore.edu/~newhall/unixhelp/debuggingtips_Java.html
 
 note that we can execute our class files either using /usr/bin/java
 or the JNI
 
 http://developer.apple.com/mac/library/technotes/tn2005/tn2147.html
 
 */

#import "MGSJavaRunner.h"
#import "TaskRunner.h"
#import "MGSJavaLanguage.h"

@implementation MGSJavaRunner


/*
 
 - initWithDictionary
 
 designated initialiser
 
 */
- (id)initWithDictionary:(NSDictionary *)dictionary
{
	if ((self = [super initWithDictionary:dictionary])) {
		self.scriptExecutableExtension = @"cpgz";
		self.scriptSourceExtension = @"java";
		
	}
	return self;
}

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSJavaLanguage class];
}

/*
 
 - validate
 
 */
- (BOOL)validate
{
	BOOL success = YES;
	
	if (!self.runClassName) {
		[self addError:NSLocalizedString(@"Run Class is not defined", @"Script task process error")];
		success = NO;
	}
		
	return success;
}

#pragma mark -
#pragma mark Operations

/*
 
 - launchEnvironment
 
 */
- (NSMutableDictionary *)launchEnvironment
{
	/*
	 
	 add java resources to classpath
	 
	 for native packages we give the path to the folder containing the package root.
	 for jar packages we give the path to the jar itself
	 
	 */
	NSString *yamlJarPath = [self pathToResource:@"Java/snakeyaml-1.7.jar"];
	NSString *packagePath = [self pathToResource:@"Java"];
	
	NSMutableDictionary *env = [super launchEnvironment];
	NSArray *paths = [NSArray arrayWithObjects: @".", yamlJarPath, packagePath, nil];
	
	[self updateEnvironment:env pathkey:@"CLASSPATH" paths:paths];
		
	return env;
}

/*
 
 - build
 
 */

- (BOOL)build
{
	// if the main class def is as follows
	// public class kosmicTask {
	// then a warning occurs if filename does not match class name	
	
	self.scriptFileNameTemplate = self.runClassName;
	
	return [super build];
}

/*
 
 - parseCompileResult:
 
 */
- (BOOL)processBuildResult:(NSString *)resultString
{
#pragma unused(resultString)
	
	// compiler error and warning information written to stderr.
	// warnings may be generated if we use -verbose.
	// if stdErr is non nil but the class file exists then we have warnings.
	// if stdErr is non nil and the class file does not exist exist then we have errors.
	NSString *stdErrString = [[NSString alloc] initWithData:self.stderrData encoding:NSUTF8StringEncoding];
	if (stdErrString && [stdErrString length] > 0) {		
		[self addError:stdErrString];
	}

	// get array of class files
	NSMutableArray *classFiles = [self filesAtPath:self.workingDirectory withExtension:@"class"];
	if (!classFiles || [classFiles count] == 0) {
		if (!self.error) {
			self.error = @"Class file not found.";
		}
		goto exitHandler;
	}
	
	// compressed archive setup
	NSString *archiveFileName = self.runClassName;
	NSString *archivePath = [self.workingDirectory stringByAppendingPathComponent:archiveFileName];
	/* get the compiled class files as a compressed archive.
	 
	 note that the generated files will be named after the Java class, not the .java source file.
	 if a single source file contains multiple class definitions then multiple class
	 file will be generated.
	 in order to maintain task script integrity we have to archive all the class files
	 
	 a jar is no good as it cannot reference class external to the jar without adding
	 a classpath reference to the required file to the jar.
	 
	 */
	NSDictionary *archiveOptions = [NSDictionary dictionaryWithObjectsAndKeys:@"class", @"FileExtension", nil];
	if (![self createArchive:archivePath options:archiveOptions]) {
		goto exitHandler;
	}
	 
	
exitHandler:	
	return [super processBuildResult:@""];
}

/*
 
 - execute
 
 */

- (BOOL)execute
{
	// it is not essential that our file be specifically named
	// but it will at least be consistent
	NSString *className = self.runClassName;
	self.scriptFileNameTemplate = className;
			
	return [super execute];
}


/*
 
 - executeOptions
 
 */
- (NSMutableArray *)executeOptions
{
	NSMutableArray *options = [super executeOptions];
	NSString *className = self.runClassName;
	
	// dont pass empty string arguments to java as it may raise an exception	
	// options:
	// className - name of the class containing the main() entry point.
	// the file containing the class must be named className.class
	[options addObject:className];
	
	return options;
}

@end
