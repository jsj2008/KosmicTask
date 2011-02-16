//
//  TaskRunner.m
//  KosmicTask
//
//  Created by Jonathan on 29/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "TaskRunner.h"
#import "MGSTempStorage.h"

static NSString *MGSTaskRunnerMainException = @"MGSTaskRunnerMainException";
/*
 
 MGSTaskRunnerMain
 
 */
int MGSTaskRunnerMain (int argc, const char * argv[])
{
#pragma unused(argc)
#pragma unused(argv)
	
	//
	// debugging the process
	//
	// 1. enable the wait code below.
	// 2. Run GUI as a separate exec, ie not in the Xcode environment
	// 3. attach to the task by ID.
	// 4. set breakpoints.
	// 5. set wait to 0 in debugger (right click on variable name in listview. selecte edit value. change and continue)
	//
	// DEBUG only
	// int spin = 1; while (spin) {;}	// spin here to allow debugger attachment
	// DEBUG only
	
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	//
	// the caller will listen to stderr for this process.
	// note that NSLog writes to stderr so anything logged
	// here will end up before the user
	//
	
	NSFileHandle *outputHandle = [NSFileHandle fileHandleWithStandardOutput];
	NSFileHandle *inputHandle = nil;
	NSString *error = nil;
	MGSScriptRunner *scriptRunner = nil;
	NSDictionary *taskDict = nil;

	// catch all exceptions here
	@try {
		NSData *inputData = nil;
		
		// read data from stdin
		inputHandle = [NSFileHandle fileHandleWithStandardInput];
		inputData = [inputHandle readDataToEndOfFile];
		
		// input from stdin is required
		if (!inputData) {			
			[NSException raise:MGSTaskRunnerMainException 
						format:@"no task input supplied"];
		}
		
		// get task dict
		taskDict = [NSKeyedUnarchiver unarchiveObjectWithData:inputData];
		if(!taskDict)
		{
			[NSException raise:MGSTaskRunnerMainException 
						format:@"error unarchiving task dictionary"];
		}

		// configure temp storage
		NSString *storageURL = [taskDict objectForKey:MGSScriptTempStorageReverseURL];
		if (!storageURL) {
			[NSException raise:MGSTaskRunnerMainException 
						format:@"storage URL not found"];
		}		
		MGSTempStorage *storage = [MGSTempStorage sharedController];
		storage.reverseURL = storageURL;
		
		// get script runner class name
		NSString *runnerClassName = [taskDict objectForKey:MGSScriptRunnerClassName];
		
		// get class
		Class klass = NSClassFromString(runnerClassName);
		if (!klass) {
			[NSException raise:MGSTaskRunnerMainException 
						format:@"script runner class not found"];
		}
		
		// validate the class
		if (![klass isSubclassOfClass:[MGSScriptRunner class]]) {
			[NSException raise:MGSTaskRunnerMainException 
						format:@"invalid script runner class"];
		}
		
		// allocate instance
		scriptRunner = [[klass alloc] initWithDictionary:taskDict];
		
		// validate the runner
		if (!scriptRunner) {
			[NSException raise:MGSTaskRunnerMainException 
						format:@"cannot create script runner"];
		}
		
		scriptRunner.argc = argc;
		scriptRunner.argv = argv;
		
		// run the script.
		// returns YES if runs without errors.
		// A return value of NO indicates that errors or warnings occurred.
		[scriptRunner runScript];
			
	} @catch (NSException *e) {
		
		if (scriptRunner) {
			[scriptRunner restoreStdOut];	
		}
		
		// exception handling
		NSLog(@"Script task exception: %@", e);
		NSString *format = NSLocalizedString(@"An exception occurred: %@", @"Script task process error");
		error = [NSString stringWithFormat:format, e];
	}

	
	@try {
		NSDictionary *errorInfo = nil;
		NSInteger errorCode = MGSErrorCodeScriptRunner;

		// get reply dict
		NSMutableDictionary *replyDict = scriptRunner.replyDict;
		if (!replyDict) {
			replyDict = [NSMutableDictionary dictionaryWithCapacity:2];
		}
		
		// if no error defined query the scriptRunner
		if (!error) {
			
			// get runner errors
			if (scriptRunner && scriptRunner.error) {
				errorCode = scriptRunner.errorCode;
				error = scriptRunner.error;
				errorInfo = scriptRunner.errorInfo;
			}
		}
				
		// add error to reply dict
		if (error) {
			NSMutableDictionary *errorDict = [NSMutableDictionary dictionaryWithCapacity:3];
			[errorDict setObject:error forKey:MGSScriptError];
			[errorDict setObject:[NSNumber numberWithInteger:errorCode] forKey:MGSScriptErrorCode];
			if (errorInfo) {
				[errorDict setObject:errorInfo forKey:MGSScriptErrorInfo];
			}
			[replyDict setObject:errorDict forKey:MGSScriptError];
		}
		
		// serialize the reply dict
		NSString *plistError = nil;
		NSData *data = [NSPropertyListSerialization dataFromPropertyList:replyDict format:NSPropertyListXMLFormat_v1_0 errorDescription:&plistError];

		// validate the plist
		if (!data || plistError) {
			
			replyDict = [NSMutableDictionary dictionaryWithCapacity:2];
			NSMutableDictionary *errorDict = [NSMutableDictionary dictionaryWithCapacity:3];
			[errorDict setObject:plistError forKey:MGSScriptError];
			[errorDict setObject:[NSNumber numberWithInteger:errorCode] forKey:MGSScriptErrorCode];
			[replyDict setObject:errorDict forKey:MGSScriptError];
			
			plistError = nil;
			data = [NSPropertyListSerialization dataFromPropertyList:replyDict format:NSPropertyListXMLFormat_v1_0 errorDescription:&plistError];
			if (!data) {
				[NSException raise:MGSTaskRunnerMainException 
							format:@"Cannot report plist error"];
			}
		}

		// write to output handle
		[outputHandle writeData:data];

	} @catch (NSException *e) {
		
		NSLog(@"Script task final exception: %@", e);
		return -1;
		
	} @finally {
		
		[outputHandle closeFile];
		[pool drain];
	}

	return 0;
}
