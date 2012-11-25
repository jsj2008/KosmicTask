//
//  MGSScriptRunner.m
//  Mother
//
//  Created by Jonathan on 01/09/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import "MGSScriptRunner.h"
#import "TaskRunner.h"
#import <Carbon/Carbon.h>
#import "MGSTempStorage.h"
#import "MGSScriptRunnerApplication.h"


#define OSStatusLog(status) NSLog(@"OSStatus error: %lx - reason: %s", (long)status, GetMacOSStatusErrorString(status))

static BOOL isForegroundApplication = NO;

// class extension
@interface MGSScriptRunner()
@property (copy) NSString *scriptFilePath;
@property (copy) NSString *scriptAction;
@property BOOL isExecuting;
@property BOOL isCompiling;
@property (copy) NSString *onRun;
@property (copy) NSString *runFunctionName;
@property (copy) NSString *runClassName;

- (BOOL)preflight;

@end


@implementation NSMutableData (MGSScriptRunner)

/* 
 
 - mgs_fileHandleDataAvailable
 
 Extend the NSMutableData class to add a method called by NSFileHandleDataAvailableNotification 
 to automatically append the new data 
 
 */
- (void) mgs_fileHandleDataAvailable:(NSNotification*)notification
{
    NSFileHandle *fileHandle = [notification object];
    NSData *data = [fileHandle availableData];
	
	// an empty data block is returned on EOF
	if ([data length] > 0) {
		[self appendData:data];    
		[fileHandle waitForDataInBackgroundAndNotify];
	}
}

@end

@implementation MGSScriptRunner

@synthesize taskDict, error, errorCode, errorInfo, replyDict, argc, argv, resultObject, 
			scriptExecutableExtension, scriptSourceExtension, scriptFilePath, scriptObject, workingDirectory, 
			scriptFileNameTemplate, scriptAction, isExecuting, isCompiling, useExecutableData,
			onRun, runFunctionName, runClassName, language;


#pragma mark -
#pragma mark Class methods

/*
 
 transform to foreground application
 */
+ (BOOL)transformToForegroundApplication
{
	//
	// check if already transformed
	//
	if ([self isForegroundApplication]) {
		return YES;
	}
	
	OSStatus osStatus;
	ProcessSerialNumber ourPSN;
	
	
	// get our current process
	if ((osStatus = GetCurrentProcess(&ourPSN)) != noErr) {
		OSStatusLog(osStatus);
		return NO;
	}
	
	// transform it into a foreground app
	if ((osStatus = TransformProcessType(&ourPSN, kProcessTransformToForegroundApplication)) != noErr) {
		OSStatusLog(osStatus);
		return NO;
	}
	
	// bring it to the front
	if ((osStatus = SetFrontProcess(&ourPSN)) != noErr) {
		OSStatusLog(osStatus);
		return NO;
	}
	
	// set system UI mode to limit interaction for this process
	SetSystemUIMode(kUIModeNormal, 0);

	// sharedApplication will make a connection to the window server
	[MGSScriptRunnerApplication sharedApplication];	

	// use kosmictask icon
	[[MGSScriptRunnerApplication sharedApplication] setApplicationIconImage:[[NSWorkspace sharedWorkspace] 
																iconForFileType:@"KosmicTask"]];
	
	isForegroundApplication = YES;
	
	return YES;
	
}

/*
 
 isForegroundApplication
 
 */
+ (BOOL)isForegroundApplication
{
	return isForegroundApplication;
}
#pragma mark -
#pragma mark Instance control
/*
 
 init with dictionary
 
 designated initialiser
 
 */
- (id)initWithDictionary:(NSDictionary *)dictionary
{
	if (!dictionary) {
		return (self = nil);		
	}
	
	if ((self = [super init])) {
		taskDict = dictionary;
		errorCode = MGSErrorCodeScriptRunner;
		replyDict = [NSMutableDictionary dictionaryWithCapacity:2];
		stdoutSaved = -1;
		scriptExecutableExtension = @"";
		scriptSourceExtension = @"";
		scriptFilePath = @"";
		scriptFileNameTemplate = @"KosmicTask";
		useExecutableData = YES;
		
		scriptAction = [taskDict objectForKey:MGSScriptAction];
		onRun = [taskDict objectForKey:MGSScriptOnRun];
		runFunctionName = [taskDict objectForKey:MGSScriptSubroutine];
		runClassName = [taskDict objectForKey:MGSScriptRunClass];
		resultObject = @"missing result";
		
		language = [[[self languageClass] alloc] init];
	}
	return self;
}

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	NSAssert(NO, @"subclass must override");
	
	return [MGSLanguage class];
}

/*
 
 - preflight
 
 */
- (BOOL)preflight
{
	BOOL success = YES;
	
	if (!self.scriptAction) {
		[self addError:NSLocalizedString(@"no action key in task dictionary", @"Script task process error")];
		success = NO;
	}
	
	if (!self.onRun) {
		[self addError:NSLocalizedString(@"no onRun key in task dictionary", @"Script task process error")];
		success = NO;
	}
	
	success = [self validate];
	
	return success;
}

/*
 
 - validate
 
 */
- (BOOL)validate
{
	// subclasses should override to perform their own validation
	return YES;
}

#pragma mark -
#pragma mark Operations
/*
 
 run the script
 
 */
- (BOOL)runScript
{
	self.error = nil;
	BOOL success = NO;
	
	// preflight
	if (![self preflight]) {
		goto errorHandler;
	}
	
	// execute
	if ([self.scriptAction isEqual:MGSScriptActionExecute]) {
		self.isExecuting = YES;
		self.errorCode = MGSErrorCodeScriptExecute;
		success =  [self execute];		

	// build
	} else if ([self.scriptAction isEqual:MGSScriptActionBuild]) {
		self.isCompiling = YES;
		self.errorCode = MGSErrorCodeScriptBuild;
		success = [self build];		
	
	// unknown action requested
	} else {
		self.error = [NSString stringWithFormat: NSLocalizedString(@"unknown script action requested : %@", @"Script task process error"), self.scriptAction];
	}
			
	errorHandler:;
	
	// return error if defined
	if (self.error) {
		
		NSMutableDictionary *errorDict = [NSMutableDictionary dictionaryWithCapacity:3];
		[errorDict setObject:error forKey:MGSScriptError];
		[errorDict setObject:[NSNumber numberWithInteger:errorCode] forKey:MGSScriptErrorCode];
		if (errorInfo) {
			[errorDict setObject:errorInfo forKey:MGSScriptErrorInfo];
		}
		
		[self.replyDict setObject:errorDict forKey:MGSScriptError];
	}
	
	// include scratch paths that we want the caller to delete
	NSArray *scratchPaths = [[KosmicTaskController sharedController] scratchPaths];
	if (scratchPaths && [scratchPaths count] > 0) {
		[self.replyDict setObject:scratchPaths forKey:MGSScriptScratchPaths];
	}
	
	return success;
}

/*
 
 execute the script
 
 */
- (BOOL) execute
{
	return NO;
}

/*
 
 build the script
 
 */
- (BOOL) build
{
	return NO;
}

/*
 
 - executeWithManager:
 
 */
- (BOOL)executeWithManager:(MGSScriptExecutorManager *)manager
{
	/*
	 
	 setup the environment
	 
	 */
	scriptExecutorManager = [manager retain];
	if (![scriptExecutorManager setupEnvironment:self]) {
		self.error = @"script execution environment could not be set up.";
		return NO;
	}
	return [self executeApp];
}
/*
 
 - executeApp
 
 */
- (BOOL) executeApp
{
	BOOL success = YES;
	
	/*
	 note that because we are running in process here anything output to stdout
	 will be sent back to the calling process unless we do something about it.
	 
	 probably best to redirect stdout to stderr for duration of script
	 execution
	 
	 if script prints then it will be returned to the calling process in the stderr stream
	 
	 */
	[self redirectStdOutToStdErr];
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// create a shared application object
	[MGSScriptRunnerApplication sharedApplication];
	
	// set our delegate
	[NSApp setDelegate:self];
	
	// run until NSApp - stop: or terminate: sent.
	// only NSApp - stop: will cause run loop to return here.
	// But, only checks for stop request after an actual event has been
	// processed - timers do not count in this regard.
	//
	// If an exception occurs in -run it should be raised.
	// see // see https://github.com/omnigroup/OmniGroup/blob/master/Frameworks/OmniAppKit/OAApplication.m
	//
	// also see http://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/Exceptions/Tasks/ControllingAppResponse.html
	// for details on NSExceptionHandler
	@try {
		
		/*
		 
		 could we just not run the run loop ?
		 this would be a possibility but there would be no connection to the window server.
		 
		 Using an NSApplication instance ensures that Cocoa tasks are running in as near a standard application 
		 environment as possible.
		 
		 */
		[NSApp run];
	} @catch (NSException *e) {
		[NSApp reportException:e];
		[self addError:[e reason]];
	}
	[pool drain];
	
	// restore stdout
	[self restoreStdOut];
	
	return success;
	
}

/*
 
 - stop task:
 
 */
- (void)stopTask:(id)result
{
	self.resultObject = result;
	[self stopApp:self];
}

/*
 
 - stopApp:
 
 */
- (void)stopApp:(id)sender
{
#pragma unused(sender)
	
	// will stop run loop after next actual event object dispatched.
	// a timer doesn't count here
	[NSApp stop:self];
	
	// send a dummy event to trigger stopping
	NSEvent *event = [NSEvent otherEventWithType:NSApplicationDefined 
										location:NSMakePoint(0,0)
								   modifierFlags:0
									   timestamp:0 
									windowNumber:0 
										 context:nil
										 subtype:1 
										   data1:1 
										   data2:1];
	[NSApp postEvent:event atStart:YES];
}


#pragma mark -
#pragma mark Result processing

/*
 
 - setResultObject:
 
 */
- (void)setResultObject:(id)result
{
	if (!result) {
		result = @"empty result";
	}
	resultObject = result;
	
	//
	// resultObject MUST be serializable.
	// if it isn't then coerce it into a plist
	//
	if (![NSPropertyListSerialization propertyList:resultObject isValidForFormat:NSPropertyListXMLFormat_v1_0]) {
		resultObject = [NSPropertyListSerialization coercePropertyList:resultObject];
	}
	
	// form result dict
	NSMutableDictionary *resultDict = [NSMutableDictionary dictionaryWithCapacity:2];
	
	[resultDict setObject:resultObject forKey:MGSScriptKeyResultObject];
	
	// add result dict to reply
	[self.replyDict setObject:resultDict forKey:MGSScriptKeyResult];
}

/*
 
 - processExecuteResult:
 
 */

- (BOOL) processExecuteResult:(id)executeResult
{
	self.resultObject = executeResult;
	
	return (self.error ? NO : YES);
}

/*
 
 - processBuildResult:
 
 */
- (BOOL) processBuildResult:(NSString *)resultString
{
	#pragma unused(resultString)
	
	return (self.error ? NO : YES);
}

#pragma mark -
#pragma mark NSApplicationDelegate messages
/*
 
 application did finish launching
 
 */
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
#pragma unused(aNotification)
	
	// get script parameter array
	NSArray *paramArray = [self ScriptParametersWithError:YES];
	if (!paramArray) goto errorExit;
	
	// get executable script data
	NSData *executableData = [self scriptExecutableDataWithError:YES];
	if (!executableData) goto errorExit;
	
	// write task data to file
	NSString *scriptPath = [self writeScriptDataToWorkingFile:executableData withExtension:self.scriptExecutableExtension];
	if (!scriptPath) goto errorExit;
	
	// load  script and execute
	id object = nil;
	@try {

		/*
		 if exceptions not caught we could override NApplication's -run
		 
		 - (void)run
		 {
			 @try{
				 do
				 {
					 // run the run loop
					 CFRunLoopRunInMode(kCFRunLoopDefaultMode, 10, NO);
				 }
				 while (YES);
			} @ catch(NSException *e) {
				 // weep and expire
			}
		 }
		 
		 */
		// exceptions can be raised here that will not be trapped elsewhere
		object = [scriptExecutorManager loadScriptAtPath:scriptPath
											   runClass:self.runClassName
												 runFunction:self.runFunctionName
											   withArguments:paramArray];	
	} @catch (NSException *e) {
		scriptExecutorManager.error = [e reason];
	}
	
	// check if error occurred in script executor
	if (scriptExecutorManager.error) {
		[self addError:scriptExecutorManager.error];
	}
	
	// if keepTaskAlive we let the app run
	if ([[KosmicTaskController sharedController] keepTaskAlive]) {	
		
		// object is the created script object
		self.scriptObject = object;
	} else {
		
		// object is the result
		self.resultObject = object;
		
		// if no result object
		if (!self.resultObject) {
			[self addError:@"could not launch script."];
		} 
		
		// stop the run loop
		[self stopApp:self];
	}
	
	return;
	
errorExit:
	
	// stop the run loop
	[self stopApp:self];
	
	return;
}

#pragma mark -
#pragma mark Error handling

/*
 
 - setError:
 
 */
-(void)setError:(NSString *)anError
{
	// append all errors
	if (self.error) {
		[self addError:anError];
		return;
	}
	
	if (anError && ![anError isKindOfClass:[NSString class]]) {
		error = NSLocalizedString(@"invalid error object type", @"Script task process error");
		return;
	}
	
	error = anError;
	
	if (error && self.scriptFilePath) {
		error = [error stringByReplacingOccurrencesOfString:self.scriptFilePath 
					withString:@"KosmicTask" 
					options:NSCaseInsensitiveSearch
					range:NSMakeRange(0, [error length])];
	}
}

/*
 
 - addError:
 
 */
- (void)addError:(NSString *)anError
{
	if (!anError) return;
	
	if (self.error) {
		NSString *prevError = error;
		error = nil;	// clear the existing error
		self.error = [NSString stringWithFormat:@"%@\n%@", prevError, anError];
	} else {
		self.error = anError;
	}
	
}

/*
 
 setErrorInfo:
 
 */
- (void)setErrorInfo:(NSMutableDictionary *)theErrorInfo
{
	NSAssert([theErrorInfo isKindOfClass:[NSDictionary class]], @"bad errorInfo class");
	
	errorInfo = theErrorInfo;
	/*
	 
	 the existence of an error depends on the error method returning a non nil value.
	 if there is no error string but errorInfo is defined then we define an error.
	 
	 */
	
	if (!error) {
		error = @"Additional error information is available";
	}
}

#pragma mark -
#pragma mark Resource handling
/*
 
 - executablePath
 
 */
- (NSString *)executablePath
{
	NSString *path = [[NSBundle mainBundle] executablePath];	// path to executable
	
	return path;
}

/*
 
 - resourcesPath
 
 */
- (NSString *)resourcesPath
{
	NSString *path = [self executablePath];	// path to executable
	path = [path stringByDeletingLastPathComponent];	// MAC OS
	path = [path stringByAppendingPathComponent:@"../Resources"];
	
	return path;
}

/*
 
 - pathToResource:
 
 */
- (NSString *)pathToResource:(NSString *)resourceName
{
	return [[self resourcesPath] stringByAppendingPathComponent:resourceName];
}

/*
 
 - pathToExecutable:
 
 */
- (NSString *)pathToExecutable:(NSString *)name
{	
	NSString *path = [self executablePath];	// path to executable
	path = [path stringByDeletingLastPathComponent];	// MAC OS

	return [path stringByAppendingPathComponent:name];
}

#pragma mark -
#pragma mark Task environment
/*
 
 - updateEnvironment:pathkey:paths
 
 */
- (void)updateEnvironment:(NSMutableDictionary *)env pathkey:(NSString *)key paths:(NSArray *)paths
{
	[self updateEnvironment:env pathkey:key paths:paths separator:@":"];
	
}
/*
 
 - updateEnvironment:pathkey:paths
 
 */
- (void)updateEnvironment:(NSMutableDictionary *)env pathkey:(NSString *)key paths:(NSArray *)paths separator:(NSString *)separator
{
	
	NSString *envPath = [env objectForKey:key];
	for (NSString *path in paths) {
		if (!envPath) {
			envPath = path;
		} else {
			envPath = [NSString stringWithFormat:@"%@%@%@", path, separator, envPath];
		}
	}
	
	[env setObject:envPath forKey:key];
	
}
/*
 
 - launchEnvironment
 
 */
- (NSMutableDictionary *)launchEnvironment
{
	NSMutableDictionary *env = [NSMutableDictionary dictionaryWithDictionary:[self environment]];
	
	return env;
}
/*
 
 - buildEnvironment
 
 */
- (NSMutableDictionary *)buildEnvironment
{
	return [self launchEnvironment];
}

/*
 
 - environment
 
 */
- (NSDictionary *)environment
{
	// there were problems with cint finding include files.
	// not allowing to append to existing env vars did help.
	return [[NSProcessInfo processInfo] environment];
}

#pragma mark -
#pragma mark Task paths
/*
 
 - launchPath
 
 */
- (NSString *)launchPath
{
	NSString *path = [self.taskDict objectForKey:MGSScriptExecutorPath];
	if (!path) {
		path = [self defaultLaunchPath];
	}
	
	return path;
}

/*
 
 - buildPath
 
 */
- (NSString *)buildPath
{
	NSString *path = [self.taskDict objectForKey:MGSScriptBuildPath];
	if (!path) {
		path = [self defaultBuildPath];
	}
	
	return path;
}

/*
 
 - executeOptions
 
 */
- (NSMutableArray *)executeOptions
{
	NSString *optionString = [self.taskDict objectForKey:MGSScriptExecutorOptions];
	if (!optionString) {
		optionString = self.language.initExecutorOptions;
	} 
		
	NSMutableArray *options = [MGSLanguage tokeniseString:optionString];
	if (!options) {
		options = [NSMutableArray new];
	}
	return options;
}

/*
 
 - buildOptions
 
 */
- (NSMutableArray *)buildOptions
{
	NSString *optionString = [self.taskDict objectForKey:MGSScriptBuildOptions];
	if (!optionString) {
		optionString = self.language.initBuildOptions;
	}  
	
	NSMutableArray *options = [MGSLanguage tokeniseString:optionString];
	if (!options) {
		options = [NSMutableArray new];
	}
	
	return options;
}
/*
 
 - launchPath
 
 */
- (NSString *)defaultLaunchPath
{
	return self.language.initExternalExecutorPath;
}	


/*
 
 - defaultBuildPath
 
 */
- (NSString *)defaultBuildPath
{
	NSString *buildPath = self.language.initExternalBuildPath;
	if (!buildPath) {
		buildPath = [self defaultLaunchPath];
	}
	
	return buildPath;
}

#pragma mark -
#pragma mark Script components

/*
 
 - scriptSourceWithError:
 
 */
- (NSString *)scriptSourceWithError:(BOOL)genError
{
	// get the source
	NSString *source = [self.taskDict objectForKey:MGSScriptSource];
	if (source == nil || [source length] == 0) {
		if (genError) {
			self.error = NSLocalizedString(@"no source in task dictionary", @"Script task process error");
		}
		return nil;
	}
	
	return source;
}

/*
 
 - ScriptParametersWithError:
 
 */
- (NSArray *)ScriptParametersWithError:(BOOL)genError
{
	// get script parameter array
	NSArray *paramArray = [self.taskDict objectForKey:MGSScriptParameters];
	if (!paramArray && genError) {
		self.error = NSLocalizedString(@"no parameters in task dictionary", @"Script task process error");
	}
	
	return paramArray;
}	

/*
 
 - scriptExecutableDataWithError:
 
 */

- (NSData *)scriptExecutableDataWithError:(BOOL)genError
{
	
	// get executable script data
	NSData *executableData = [self.taskDict objectForKey:MGSScriptExecutable];
	if (!executableData && genError) {
		self.error = NSLocalizedString(@"script executable data missing", @"Script task process error");
	}
	
	return executableData;
}

/*
 
 - scriptExecutableFormat
 
 */
- (NSString *)scriptExecutableFormat
{
	
	// get executable script format
	return [self.taskDict objectForKey:MGSScriptExecutableFormat];

}

/*
 
 - executableIsArchive
 
 */
- (BOOL)executableIsArchive
{
	NSString *executableFormat = [self scriptExecutableFormat];
	
	NSArray *archiveFormats = [NSArray arrayWithObjects:MGSScriptDataFormatTarBzip2, nil];
	if ([archiveFormats containsObject:executableFormat]) {
		return YES;
	}
	
	return NO;
}
/*
 
 - scriptExecutableSourceWithError:
 
 */

- (NSString *)scriptExecutableSourceWithError:(BOOL)genError
{
	
	// get executable script data
	NSData *executableData = [self.taskDict objectForKey:MGSScriptExecutable];
	if (!executableData) {
		if (genError) {
			self.error = NSLocalizedString(@"script executable data missing", @"Script task process error");
		}
		return nil;
	}
	
	// get source
	NSString *executableSource = [[NSString alloc] initWithData:executableData encoding:NSUTF8StringEncoding];
	if (!executableSource) {
		if (genError) {
			self.error = NSLocalizedString(@"script executable source missing", @"Script task process error");
		}
		return nil;
	}
	
	return executableSource;
}

/*
 
 - beginScriptExecutableSource
 
 */
- (NSString *)beginScriptExecutableSource
{
	return nil;
}

#pragma mark -
#pragma mark Archiving
/*
 
 - createArchive:options:
 
 TODO: use libarchive
 
 http://code.google.com/p/libarchive/
 
 see the ArchiveWrapper class
 
 */
- (BOOL)createArchive:(NSString *)archivePath options:(NSDictionary *)options
{
	NSString *MGSTaskArchiveException = @"MGSTaskArchiveException";
	NSString *excErr = nil;
	NSTask *task = nil;
	NSMutableData *errorData = nil;
	NSFileHandle *fileHandle = nil;
	
	@try {
				
		archivePath = [archivePath stringByAppendingPathExtension:@"tar.gz"];
		
		[[NSFileManager defaultManager] removeItemAtPath:archivePath error:NULL];	// precaution
		
		NSString *fileExtension = [options objectForKey:@"FileExtension"];
		if (!fileExtension) {
			excErr = NSLocalizedString(@"No file extension specified.", @"Archive error");
			[NSException raise:MGSTaskArchiveException format:excErr, nil];
		}
		
		// prepare archive task
		// remember that this doesn't run in a shell
		// so that wildcard expansion will not work.
		task = [[NSTask alloc] init];
		[task setCurrentDirectoryPath:self.workingDirectory];
		[task setLaunchPath:@"/usr/bin/tar"];
		
		// configure task arguments
		// -c create an archive
		// -j compress with gzip
		// file list 
		// archive name
		//
		// for the file list *.class won't work here as we don't have a shell
		// unless our task is /bin/sh -c "/usr/bin/tar -cjf kosmicTask.tar.gz *.class "
		// but this has all the extra overhead of starting up a shell
		// http://www.macosxguru.net/article.php?story=20050827090703916
		// http://forums.macrumors.com/showthread.php?t=311645
		//
		// note that ditto only supports whole directories
		/*
		 The command:
		 pax -zf archive.cpgz
		 will list the files in the compressed CPIO archive archive.cpgz.
		 
		 note that compression can be done in process :
		 http://www.bzip.org/1.0.5/bzip2-manual-1.0.5.html
		 http://stackoverflow.com/questions/813223/how-to-compress-a-directory-with-libbz2-in-c
		 
		 see the ArchiveWrapper class
		 
		 http://bazaar.launchpad.net/%7Epelle-morth/modazipin/trunk/annotate/head%3A/ArchiveWrapper.m
		 
		 */
		NSMutableArray *arguments = [NSMutableArray arrayWithObjects:
									 @"--format",
									 @"cpio",	
									 @"-cjf",
									 archivePath,
									 nil];
		NSMutableArray *files = [self filesAtPath:self.workingDirectory withExtension:fileExtension];
		if (!files || [files count] == 0) {
			excErr = NSLocalizedString(@"No files found to archive.", @"Archive error");
			[NSException raise:MGSTaskArchiveException format:excErr, nil];
		}
		
		// add files as arguments
		[arguments addObjectsFromArray:files];
		
		// set task arguments
		[task setArguments: arguments];
		
		// configure input
		[task setStandardInput:[NSPipe pipe]];	// http://www.cocoadev.com/index.pl?NSTask
		
		// configure stderr
		NSPipe *errorPipe = [NSPipe pipe];
		if (!errorPipe) {
			[NSException raise:MGSTaskArchiveException format:@"Cannot allocate error pipe", nil];
		}
		[task setStandardError: errorPipe];
		
		// launch the task
		setsid(); // make part of process group
		[task launch];
		
		// read task stdErr async
		if ((fileHandle = [errorPipe fileHandleForReading])) {
			errorData = [NSMutableData data];
			[[NSNotificationCenter defaultCenter] addObserver:errorData 
													 selector:@selector(mgs_fileHandleDataAvailable:) 
														 name:NSFileHandleDataAvailableNotification object:fileHandle];
			[fileHandle waitForDataInBackgroundAndNotify];			
		}
		
		// wait for task to complete
		[task waitUntilExit];

		// complete error data read
		if ((fileHandle = [errorPipe fileHandleForReading])) {
			[[NSNotificationCenter defaultCenter] removeObserver:errorData name:NSFileHandleDataAvailableNotification object:fileHandle];
			[errorData appendData:[fileHandle readDataToEndOfFile]];
		}
		
		// report error
		if ([task terminationStatus] != 0) {
			self.error = NSLocalizedString(@"Task archive file error.", @"Archive error");
			
			NSString *stdError = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
			if (stdError) {
				[self addError:stdError];
			}
			
			excErr = NSLocalizedString(@"Archive error.", @"Archive error");
			[NSException raise:MGSTaskArchiveException format:excErr, nil];
		}

		
		// look for the archive file
		NSError *dataError = nil;
		NSData *archiveData = [NSData dataWithContentsOfFile:archivePath options:NSMappedRead error:&dataError];
		
		if (archiveData) {
			[self.replyDict setObject:archiveData forKey:MGSScriptKeyCompiledScript];
			[self.replyDict setObject:MGSScriptDataFormatTarBzip2 forKey:MGSScriptKeyCompiledScriptDataFormat];
		} else {
			excErr = NSLocalizedString(@"Task archive file not found.", @"Archive error");
			[NSException raise:MGSTaskArchiveException format:excErr, nil];
		}
	} @catch(NSException *e) {
		[self addError:[NSString stringWithFormat:@"Exception : %@ %@", [e name], [e reason]]];
		[self addError:[NSString stringWithFormat:@"NSTask = %@ %@", [task launchPath], [task arguments]]];
		return NO;
	}
	
	return YES;
}

/*
 
 - filesAtPath:withExtension:
 
 */
- (NSMutableArray *)filesAtPath:(NSString *)path withExtension:(NSString *)fileExtension
{
	NSMutableArray *files = [NSMutableArray arrayWithObjects: nil];
	
	// append files
	NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:path];
	if (!dirEnum) {
		self.error = NSLocalizedString(@"Cannot enumerate working directory.", @"Archive error");
		return nil;
	}
	NSString *dirFile = nil;
	while ((dirFile = [dirEnum nextObject])) {
		if([[dirFile pathExtension] isEqualToString:fileExtension])
		{
			[files addObject:dirFile];
		}
	}

	return files;
}
/*
 
 - extractArchive:options:
 
 TODO: use libarchive
 
 http://code.google.com/p/libarchive/
 
 */
- (BOOL)extractArchive:(NSString *)archivePath options:(NSDictionary *)options
{
#pragma unused(options)
	NSString *MGSTaskExtractArchiveException = @"MGSTaskExtractArchiveException";
	NSString *excErr = nil;
	NSTask *task = nil;
	NSMutableData *errorData = nil;
	NSFileHandle *fileHandle = nil;


	@try {
		// prepare archive task
		// remember that this doesn't run in a shell
		// so that wildcard expansion will not work.
		task = [[NSTask alloc] init];
		[task setCurrentDirectoryPath:self.workingDirectory];
		[task setLaunchPath:@"/usr/bin/tar"];
		
		// configure task arguments
		// -x extract an archive
		// -f archive name

		NSMutableArray *arguments = [NSMutableArray arrayWithObjects:
									 @"-xof",
									 archivePath,
									 nil];
			
		// set task arguments
		[task setArguments: arguments];
		
		// configure input
		[task setStandardInput:[NSPipe pipe]];	// http://www.cocoadev.com/index.pl?NSTask
		
		// configure stderr
		NSPipe *errorPipe = [NSPipe pipe];
		if (!errorPipe) {
			[NSException raise:MGSTaskExtractArchiveException format:@"Cannot allocate error pipe", nil];
		}
		[task setStandardError:errorPipe];
		
		// launch the task
		setsid(); // make part of process group
		[task launch];
		
		// read task stdErr async
		if ((fileHandle = [errorPipe fileHandleForReading])) {
			errorData = [NSMutableData data];
			[[NSNotificationCenter defaultCenter] addObserver:errorData 
													 selector:@selector(mgs_fileHandleDataAvailable:) 
														 name:NSFileHandleDataAvailableNotification object:fileHandle];
			[fileHandle waitForDataInBackgroundAndNotify];			
		}
		
		[task waitUntilExit];

		// complete error data read
		if ((fileHandle = [errorPipe fileHandleForReading])) {
			[[NSNotificationCenter defaultCenter] removeObserver:errorData name:NSFileHandleDataAvailableNotification object:fileHandle];
			[errorData appendData:[fileHandle readDataToEndOfFile]];
		}
		
		// return error
		if ([task terminationStatus] != 0) {
			NSString *stdError = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
			if (stdError) {
				[self addError:stdError];
			}
			
			excErr = NSLocalizedString(@"Extract archive error.", @"Extract archive error");
			[NSException raise:MGSTaskExtractArchiveException format:excErr, nil];
		}
	} @catch (NSException *e) {
		[self addError:[NSString stringWithFormat:@"Exception : %@ %@", [e name], [e reason]]];
		[self addError:[NSString stringWithFormat:@"NSTask = %@ %@", [task launchPath], [task arguments]]];
		
		return NO;
	}
	
	return YES;

}

/*
 
 - prepareExecutable
 
 */
- (BOOL)prepareExecutable
{
	if ([self executableIsArchive]) {
		
		// get executable script data
		NSData *executableData = [self scriptExecutableDataWithError:YES];
		if (!executableData) goto exitHandler;
		
		// write task data to file
		NSString *archivePath = [self writeScriptDataToWorkingFile:executableData withExtension:[self scriptFileExtension]];
		if (!archivePath) goto exitHandler;
		
		// extract class files from archive
		NSDictionary *archiveOptions = [NSDictionary dictionaryWithObjectsAndKeys: nil];
		if (![self extractArchive:archivePath options:archiveOptions]) {
			goto exitHandler;
		}
		
		// we don't want to pass executable data directly
		self.useExecutableData = NO;
	}

	return YES;
	
exitHandler:
	
	return NO;
}

#pragma mark -
#pragma mark Script file handling

/*
 
 - scriptFileExtension
 
 */
- (NSString *)scriptFileExtension
{
	if ([self isCompiling]) {
		return self.scriptSourceExtension;
	} else if ([self isExecuting]) {
		return self.scriptExecutableExtension;
	}
	
	NSAssert(NO, @"invalid script file extension");
	
	return @"tmp";
}

#pragma mark -
#pragma mark Working storage handling


/*
 
 - tempDirectory
 
 */
- (NSString *)workingDirectory
{
	 // make a working directory to hold all work files in
	 if (!workingDirectory) {
		 workingDirectory = [[MGSTempStorage sharedController] storageDirectoryWithOptions:nil];
		 if (!workingDirectory) {
			 self.error = NSLocalizedString(@"cannot create working directory", @"Script task process error");
			 return nil;
		 }
		 
		 [self.replyDict setObject:workingDirectory forKey:MGSScriptWorkingDirectory];
	 }
	
	return workingDirectory;
}
/*
 
 - setScriptFilePath:
 
 */
- (void)setScriptFilePath:(NSString *)path
{
	scriptFilePath = path;
	NSAssert([path isKindOfClass:[NSString class]], @"invalid path class");
}
/*
 
 - writeScriptDataToWorkingFile:withExtension:
 
 */
- (NSString *)writeScriptDataToWorkingFile:(NSData *)data withExtension:(NSString *)ext
{

	self.scriptFilePath = @"";
	
	// validate the extension
	if (!ext) {
		ext = @"";
	} else if ([ext length] > 0) {
		NSRange range = [ext rangeOfString:@"." options:NSAnchoredSearch];
		if (range.location == NSNotFound) {
			ext = [@"." stringByAppendingString:ext];
		}
	}
	
	NSString *scriptPath = [self workingFilePathWithExtension:ext];
	if (![data writeToFile:scriptPath atomically:YES]) {
		self.error = NSLocalizedString(@"cannot save script to file", @"Script task process error");
		return nil;
	}
	
	self.scriptFilePath = scriptPath;
	
	return scriptPath;
}

/*
 
 - workingFilePathWithExtension:
 
 */
- (NSString *)workingFilePathWithExtension:(NSString *)ext
{
	NSMutableDictionary *options = [NSMutableDictionary dictionaryWithObjectsAndKeys:
							 self.workingDirectory, MGSTempFileTemporaryDirectory,
							 ext, MGSTempFileSuffix,
							 nil];
	
	// use template if defined
	if (self.scriptFileNameTemplate) {
		[options setObject:self.scriptFileNameTemplate forKey:MGSTempFileTemplate];
	}
	
	NSString *scriptPath = [[MGSTempStorage sharedController] storageFileWithOptions:options];
	
	// delete temp file if exists
	[[NSFileManager defaultManager] removeItemAtPath:scriptPath error:NULL];

	return scriptPath;
}


/*
 
 - redirectStdOutToStdErr
 
 */
- (void)redirectStdOutToStdErr
{
	// http://discussions.apple.com/thread.jspa?messageID=8914050
	// http://trac.handbrake.fr/browser/tags/0.9.4/macosx/HBOutputRedirect.m
	
	//int     (*oldWriteFunc)(void *, const char *, int);
	//stdout->_write = stderr->_write;
	//stdout->_write = &stdoutwrite;
	//int stderrSave = dup(STDOUT_FILENO);
	//dup2(STDOUT_FILENO, STDERR_FILENO);
	/*
	 
	 note that because we are running in process here anything output by python to stdout
	 will be sent back to the calling process unless we do something about it.
	 
	 probably best to redirect stdout to stderr for duration of script
	 execution
	 dup docs say:
	 
	 The new descriptor returned by the call is the lowest numbered descriptor currently not in use by the
     process.
	 
	 so if we close STDOUT_FILENO and duplicate STDERR_FILENO then FD 2 (STDOUT_FILENO) will
	 be a duplicate of STDERR_FILENO
	 
	 */
	// redirect stdout to std err
	fflush(stdout);
	stdoutSaved = dup(STDOUT_FILENO);
	close(STDOUT_FILENO);
	dup(STDERR_FILENO);
	
}
/*
 
 - restoreStdOut
 
 */
- (void)restoreStdOut
{
	if (stdoutSaved != -1) {
		fflush(stdout);
		close(STDOUT_FILENO);
		dup(stdoutSaved);
		stdoutSaved = -1;
	}
	
}
@end
