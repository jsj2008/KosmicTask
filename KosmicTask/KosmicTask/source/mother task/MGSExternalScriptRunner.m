//
//  MGSShellScriptRunner.m
//  KosmicTask
//
//  Created by Jonathan on 29/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSExternalScriptRunner.h"
#import "TaskRunner.h"
#import "NSString+SymlinksAndAliases.h"
#import <unistd.h>

static NSString * const MGSExternalScriptRunnerException = @"MGSExternalScriptRunnerException";

// class extension
@interface MGSExternalScriptRunner()
- (NSString *)externalTask:(NSString *)taskPath env:(NSDictionary *)env data:(NSData *)taskData parameters:(NSArray *)parameters options:(NSArray *)options;
@end


@implementation MGSExternalScriptRunner

@synthesize stderrData;

/*
 
 init with dictionary
 

 */
- (id)initWithDictionary:(NSDictionary *)dictionary
{
	if ((self = [super initWithDictionary:dictionary])) {
	}
	return self;
}

#pragma mark -
#pragma mark Operations


/*
  
 - execute 
 
 */
- (BOOL) execute
{
	if (![self prepareExecutable]) {
		return NO;
	}
	
	NSArray *options = [self executeOptions];
	
	// get script parameter array
	NSArray *paramArray = [self ScriptParametersWithError:YES];
	if (!paramArray) return NO;
	
	// get executable script data
	NSData *executableData = nil;
	
	// if executable data was in an archive then we may not need 
	// to execute the data
	if (self.useExecutableData) {
		executableData = [self scriptExecutableDataWithError:YES];
		if (!executableData) return NO;
	}
	
	// shell the task
	NSString *resultString = [self externalTask:[self launchPath] env:[self launchEnvironment] data:executableData parameters:paramArray options:options];
	
	return [self processExecuteResult:resultString];
}

/*
 
 - parseExecuteResult:
 
 */

- (BOOL) processExecuteResult:(NSString *)resultString
{
	
	BOOL success = [super processExecuteResult:resultString];
	
	// pass stderr data back to caller
	[(NSFileHandle *)[NSFileHandle fileHandleWithStandardError] writeData:self.stderrData];
	
	return success;
}

/*
 
 - build
 
 */
- (BOOL) build
{
	// options
	NSArray *options = [self buildOptions];
	
	// may be nil
	NSArray *paramArray = [self.taskDict objectForKey:MGSScriptParameters];
	
	// get source script data
	NSData *sourceData = [self.taskDict objectForKey:MGSScriptSource];
	if (!sourceData) {
		self.error = NSLocalizedString(@"script source data missing", @"Script task process error");
		return NO;
	}
	
	// shell the task
	NSString *resultString = [self externalTask:[self buildPath] env:[self buildEnvironment] data:sourceData parameters:paramArray options:options];
	
	// parse the result
	return [self processBuildResult:resultString];
}

/*
 
 - parseCompileResult:
 
 */
- (BOOL) processBuildResult:(NSString *)resultString
{
	// non zero compile result is an error
	if ([resultString length] > 0) {
		self.error = resultString;
	}
	
	// pass stderr data back to caller
	[(NSFileHandle *)[NSFileHandle fileHandleWithStandardError] writeData:self.stderrData];

	return [super processBuildResult:resultString];
}

/*
 
 - staticAnalyserPath
 
 */
- (NSString *)staticAnalyserPath
{
	return nil;
}
/*
 
 - externalTask:data:parameters:options:
 
 see quartz composer CommandLineTool sample code
 http://developer.apple.com/library/mac/#samplecode/CommandLineTool/Listings/CommandLineToolPlugIn_m.html%23//apple_ref/doc/uid/DTS40009314-CommandLineToolPlugIn_m-DontLinkElementID_4
 
 */
- (NSString *)externalTask:(NSString *)inTaskPath env:(NSDictionary *)env data:(NSData *)taskData parameters:(NSArray *)parameters options:(NSArray *)options
{
	// DEBUG only
	// int spin = 1; while (spin) {;}	// spin here to allow debugger attachment
	// DEBUG only
	NSString *resultString = nil;
	NSFileHandle* fileHandle = nil;
	NSMutableData *outData = nil, *errData = nil;
	NSTask *task = nil;

	@try {
		// make sure the runloop is active
		[NSRunLoop currentRunLoop];

		// resolve path
		NSString *taskPath = [inTaskPath stringByResolvingSymlinksAndAliases];
		
		// validate task path
		if (![[NSFileManager defaultManager] isExecutableFileAtPath:taskPath]) {
			[self addError:[NSString stringWithFormat:NSLocalizedString(@"cannot execute file at path %@", @"Script task process error"), inTaskPath]];
			return nil;
		}
		
		NSString *scriptFileName = nil;

		// if no task data then we assume that the task
		// has been pre prepared in the working directory and 
		// that the options will call it as required
		if (taskData) {
			// write task data to file
			NSString *scriptPath = [self writeScriptDataToWorkingFile:taskData withExtension:[self scriptFileExtension]];
			if (!scriptPath) {
				return nil;
			}

			// get script path components
			scriptFileName = [scriptPath lastPathComponent];
			scriptFileName = [self scriptFileNameForShell:scriptFileName];
		}
		
		// configure task.
		// note that this child task will inherit stderr and out from parent process.
		// the caller will read stderr and hence access all error stream data
		// from this task and its child unless we reassign stderr.
		//
		// this is generally the best approach but in some cases, say Perl, syntax checking
		// messages are sent to stderr in which case we will need to intercept them before
		// they are returned to the client.
		//
		task = [[NSTask alloc] init];
		[task setCurrentDirectoryPath:self.workingDirectory];
		[task setLaunchPath:taskPath];
		
		// configure environment
		if (env) {
			[task setEnvironment:env];
		}
		
		// configure task arguments
		NSMutableArray *arguments = [NSMutableArray arrayWithArray:options];	// options
		if (scriptFileName) {
			[arguments addObject:scriptFileName];	// script file path
		}
		if (parameters) {
			/*
			 
			 coerce all parameters to strings
			 
			 */
			for (id parameter in parameters) {
				NSString *stringRep = nil;
				if ([parameter isKindOfClass:[NSString class]]) {
					stringRep = parameter;
				} else if ([parameter respondsToSelector:@selector(stringValue)]) {
					stringRep = [parameter stringValue];
				} else {
					stringRep = [parameter description];
				}
				[arguments addObject:stringRep];
			}
		}
		/*
		 see the docs for setArguments:
		 
		 must be an array of strings. fileSystemRepresentation is used to generate the arguments
		 passed to argv[].
		 
		 */
		[task setArguments: arguments];
		
		/*
		 
		 The max size of the command line that can be passed to the task is ARG_MAX
		 Richards page 233 : says ARG_MAX is total size of argument list and environment list
		 */
		NSInteger commandLineSize = 0;
		for (NSString *key in [env allKeys]) {
			commandLineSize += [key length] + [[env objectForKey:key] length] + 2; // add two for : and =
		}
		for (id argument in arguments) {
			commandLineSize += [argument length];
		}
		NSInteger maxCommandLineSize = ARG_MAX - (1 * 1024);	// dont try for exactness
		if (commandLineSize > maxCommandLineSize) {
			[self addError:[NSString stringWithFormat:
							NSLocalizedString(@"Maximum task argument size exceeded. The combined maximum size of task environment variables and arguments is %i KB. The requested size was %i KB.", 
											   @"Script task process error"), 
							maxCommandLineSize/1024, commandLineSize/1024]];
			
			return nil;
		}
		
		//NSLog(@"LaunchPath = %@ args %@", taskPath, arguments);
		
		// configure input
		NSPipe *inputPipe = [NSPipe pipe];
		if (!inputPipe) {
			[NSException raise:MGSExternalScriptRunnerException format:@"Cannot allocate input pipe"];
		}
		[task setStandardInput:inputPipe];	// http://www.cocoadev.com/index.pl?NSTask
				
		// configure task output
		NSPipe *outputPipe = [NSPipe pipe];
		if (!outputPipe) {
			[NSException raise:MGSExternalScriptRunnerException format:@"Cannot allocate output pipe"];
		}
		[task setStandardOutput: outputPipe];
		
		// configure stderr
		NSPipe *errorPipe = [NSPipe pipe];
		if (!errorPipe) {
			[NSException raise:MGSExternalScriptRunnerException format:@"Cannot allocate error pipe"];
		}
		[task setStandardError: errorPipe];
		
		// set the session ID for the group.
		// the child task will inherit it!
		// this will create a session group.
		// when this task is killed the child tasks will die too.
		
		// perhaps the server task is part of the process group. check for -1 return above?
		pid_t group = setsid(); 
		(void)group;
		
		
		// launch the task.
		/*
		 
		 http://www.in-ulm.de/~mascheck/various/argmax/
		 
		 The max length of the total command line (which includes our task arguments) is syslimits.h/ARG_MAX
		 which on SL is  (256 * 1024) = 262144. In effect this is the max length of the argument that can be based to exec()
		 , which, of course, occurs when we launch our task and fork() the current process.
		 
		 Shells can get around this using of xargs(1) - see Richards - Advanced programming in Unix Env - p234
		 
		 */
		/*
		 
		 The docs for NSTask -launch state:
		 
		 Raises an NSInvalidArgumentException if the launch path has not been set or is invalid or if it fails to create a process.
		 
		 What it doesn't address is what happens if the process command line formed from the NSTask properties exceeds ARG_MAX.
		 The path is valid, the process is created but the process subsequently becomes invalid.
		 
		 In this case the exec() that follows the fork() fails as ARG_MAX is the limit for exec() arguments.
		 The child process now has no raison d'etre and expires declaring:
		 
		 *** NSTask: Task create for path '/some/crumbs' failed: 22, "Invalid argument".  Terminating temporary process.
		 
		 The parent process receives the above on the child's stdErr.
		 No exception is raised in the parent.
		 NSTask -terminationStatus returns 5.
		 
		 What is the best way to detect this failure so that an intelligible error can be reported to the user who instigated the task (eg "the task you submitted was really just too big")?
		 I can grep the stdErr report, but it's hardly a robust approach, or is the terminationStatus wholly distinctive or documented?
		 
		 Or I could estimate how close the process command line resulting from the NSTask is to ARG_MAX (256 * 1024) and take avoiding action.
		 
		 */
		[task launch];
		
		// we don't need to write to stdIn as the Task will read the argument list
		
	#ifdef MGS_USE_PROCESS_GROUPING

		// we want the child process to end when we end
		// http://old.nabble.com/Ensure-NSTask-terminates-when-parent-application-does-td22510014.html
		// http://en.wikipedia.org/wiki/Process_group
		//
		// all process in group should die when the process leader dies.
		// http://stackoverflow.com/questions/994033/mac-os-x-quickest-way-to-kill-quit-an-entire-process-tree-from-within-a-cocoa-ap.
		//
		// 
		pid_t group = setsid(); 
		if (group == -1) { 
			NSLog(@"setsid() == -1"); 
			group = getpgrp(); 
		} 
		if (setpgid([task processIdentifier], group) == -1) { 
			// setpgid always seems to fail
			NSLog(@"unable to put task into same group as self: errno = %i", errno); 
		} 
		//NSLog(@"new task process id = %i", [task processIdentifier]);
		//NSLog(@"pgid = %i", group);
	#endif

		// read task output async
		if ((fileHandle = [outputPipe fileHandleForReading])) {
			outData = [NSMutableData data];
			[[NSNotificationCenter defaultCenter] addObserver:outData 
													 selector:@selector(mgs_fileHandleDataAvailable:) 
														 name:NSFileHandleDataAvailableNotification object:fileHandle];
			[fileHandle waitForDataInBackgroundAndNotify];
		}

		// read stdErr async
		if ((fileHandle = [errorPipe fileHandleForReading])) {
			errData = [NSMutableData data];
			[[NSNotificationCenter defaultCenter] addObserver:errData 
													 selector:@selector(mgs_fileHandleDataAvailable:) 
														 name:NSFileHandleDataAvailableNotification object:fileHandle];
			[fileHandle waitForDataInBackgroundAndNotify];
		}
				
		// wait for task
		[task waitUntilExit];
		
		// complete error data read
		if ((fileHandle = [errorPipe fileHandleForReading])) {
			[[NSNotificationCenter defaultCenter] removeObserver:errData name:NSFileHandleDataAvailableNotification object:fileHandle];
			[errData appendData:[fileHandle readDataToEndOfFile]];
		}
		
		// complete output data read
		if ((fileHandle = [outputPipe fileHandleForReading])) {
			[[NSNotificationCenter defaultCenter] removeObserver:outData name:NSFileHandleDataAvailableNotification object:fileHandle];
			[outData appendData:[fileHandle readDataToEndOfFile]];
		}
			
		// assign error data.
		self.stderrData = errData;
		
		// check exit code
		int exitCode = [task terminationStatus];
		if (exitCode != 0) {
			// is this desirable ?
			if (NO) {
				[self addError:[NSString stringWithFormat:NSLocalizedString(@"Script exit code: %i", @"Task exit code"), exitCode, nil]];
			}
		}
			
		// get string
		resultString = [[NSString alloc] initWithData:outData encoding: NSUTF8StringEncoding];
	} 
	@catch (NSException *e) {
		self.error = [NSString stringWithFormat:@"A task runner exception has occurred %@ : %@ ", [e name], [e description]];
		resultString = nil;
		
		if ([task isRunning]) {
			[task terminate];
		}
	}
	@finally {
		;
	}
	return resultString;
}

/*
 
 - scriptFileNameForShell
 
 */
- (NSString *)scriptFileNameForShell:(NSString *)scriptFileName
{
	return scriptFileName;
}
@end
