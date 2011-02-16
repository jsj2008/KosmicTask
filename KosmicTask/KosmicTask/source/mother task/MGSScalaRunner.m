//
//  MGSScalaRunner.m
//  KosmicTask
//
//  Created by Jonathan on 07/08/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSScalaRunner.h"
#import "TaskRunner.h"

@implementation MGSScalaRunner

/*
 
 - initWithDictionary
 
 designated initialiser
 
 */
- (id)initWithDictionary:(NSDictionary *)dictionary
{
	if ((self = [super initWithDictionary:dictionary])) {
		self.scriptExecutableExtension = @"jar";
		self.scriptSourceExtension = @"scala";
		
	}
	return self;
}
#pragma mark -
#pragma mark Operations

/*
 
 - launchPath
 
 */
- (NSString *)launchPath
{
	// @"/usr/bin/java" is a symlink to the framework binary
	//
	// /System/Library/Frameworks/JavaVM.framework/Versions/Current/Commands/java
	//
	return @"/usr/bin/java";
}

/*
 
 - buildPath
 
 */
- (NSString *)buildPath
{
	// @"/usr/bin/javac" is a symlink to the framework binary
	//
	// /System/Library/Frameworks/JavaVM.framework/Versions/Current/Commands/javac
	//
	return @"/usr/bin/javac";
}

/*
 
 - build
 
 */

- (BOOL)build
{
	// if the main class def is as follows
	// public class kosmicTask {
	// then a warning occurs if filename does not match class name
	NSString *className = @"kosmicTask";
	self.scriptFileNameTemplate = className;
	
	return [super build];
}

/*
 
 - buildOptions
 
 */
- (NSArray *)buildOptions
{
	// dont pass empty string arguments to javac as it will raise an exception	
	NSArray *options = [NSArray arrayWithObjects:nil];
	
	return options;
}

/*
 
 - parseCompileResult:
 
 */
- (BOOL)processBuildResult:(NSString *)resultString
{
#pragma unused(resultString)
	
	// compiler error information written to stderr
	NSString *stdErrString = [[NSString alloc] initWithData:self.stderrData encoding:NSUTF8StringEncoding];
	if (stdErrString && [stdErrString length] > 0) {		
		self.error = stdErrString;
		goto exitHandler;
	}
	
	/* get the compiled class files as a jar.
	 note that the generated files will be named after the Java class, not the .java source file.
	 if a single source file contains multiple class definitions then multiple class
	 file will be generated.
	 in order to maintain task script integrity we have to archive all the class files
	 plus the manifest into a jar. the jar can be executed with java - jar myArchive.jar
	 
	 see http://projects.mugginsoft.net/view.php?id=796
	 
	 see http://download-llnw.oracle.com/javase/tutorial/deployment/jar/appman.html [^]
	 
	 1.compile with java
	 2.create Manifest.txt
	 Main-Class: kosmicTask\n
	 3. create jar with classes and manifest
	 jar -cfm kosmicTask.jar Manifest.txt *.class
	 4. execute
	 java -jar kosmicTask.jar
	 
	 */
	NSString *className = @"kosmicTask";
	
	// make the manifest
	NSError *fileError = nil;
	NSString *manifestFileName = @"manifest.txt";
	NSString *manifestPath = [self.workingDirectory stringByAppendingPathComponent:manifestFileName];
	NSString *manifest = [NSString stringWithFormat:@"Main-Class: %@\n", className];
	if (![manifest writeToFile:manifestPath atomically:YES encoding:NSUTF8StringEncoding error:&fileError]) {
		self.error = NSLocalizedString(@"Task manifest file could not be created.", @"Task manifest not created");
		goto exitHandler;
	}
	
	// jar setup
	// to view the jar contents
	// jar -tf kosmicTask.jar
	NSString *jarFileName = @"kosmicTask.jar";
	NSString *jarPath = [self.workingDirectory stringByAppendingPathComponent:jarFileName];
	[[NSFileManager defaultManager] removeItemAtPath:jarPath error:NULL];	// precaution
	
	
	// prepare jar task
	// remember that this doesn't run in a shell as such
	// so that wildcard expansion will not work.
	NSTask *task = [[NSTask alloc] init];
	[task setCurrentDirectoryPath:self.workingDirectory];
	[task setLaunchPath:@"/usr/bin/jar"];
	
	// configure task arguments
	// -c create a jar file
	// -f file name to create
	// -m manifest filename to be added
	// file list 
	//
	// for the file list *.class won't work here as we don't have a shell
	// unless our task is /bin/sh -c "/usr/bin/jar cfm kosmicTask.jar manifest.txt *.class"
	// but this has all the extra overhead of starting up a shell
	// http://www.macosxguru.net/article.php?story=20050827090703916
	// http://forums.macrumors.com/showthread.php?t=311645
	//
	NSMutableArray *arguments = [NSMutableArray arrayWithObjects:
								 @"cfm",
								 jarFileName,
								 manifestFileName,
								 nil];
	// append class files as arguments
	NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:self.workingDirectory];
	if (!dirEnum) {
		self.error = NSLocalizedString(@"Cannot enumerate working directory.", @"Cannot enumerate working directory");
		goto exitHandler;
	}
	NSString *dirFile = nil;
	while ((dirFile = [dirEnum nextObject])) {
		if([[dirFile pathExtension] isEqualToString:@"class"])
		{
			[arguments addObject:dirFile];
		}
	}
	
	[task setArguments: arguments];
	
	// configure input
	[task setStandardInput:[NSPipe pipe]];	// http://www.cocoadev.com/index.pl?NSTask
	
	// configure task output
	NSPipe *outputPipe = [NSPipe pipe];
	[task setStandardOutput: outputPipe];
	//NSFileHandle *fhOutput = [outputPipe fileHandleForReading];
	
	// configure stderr
	NSPipe *errorPipe = [NSPipe pipe];
	[task setStandardError: errorPipe];
	
	// launch the task
	[task launch];
	[task waitUntilExit];
	
	// look for the jar file
	NSError *dataError = nil;
	NSData *compiledData = [NSData dataWithContentsOfFile:jarPath options:NSMappedRead error:&dataError];
	
	if (compiledData) {
		[self.replyDict setObject:compiledData forKey:MGSScriptKeyCompiledScript];
	} else {
		self.error = NSLocalizedString(@"Task JAR file not found.", @"Task JAR file not found");
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
	// it is not essential that our jar be specifically named
	// but it will at least be consistent
	NSString *className = @"kosmicTask";
	self.scriptFileNameTemplate = className;
	
	return [super execute];
}


/*
 
 - executeOptions
 
 */
- (NSArray *)executeOptions
{
	// dont pass empty string arguments to javac as it will raise an exception	
	NSArray *options = [NSArray arrayWithObjects:@"-jar", nil];
	
	return options;
}
@end
