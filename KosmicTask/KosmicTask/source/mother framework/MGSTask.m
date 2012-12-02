//
//  MGSTask.m
//  Mother
//
//  Created by Jonathan Mitchell on 09/12/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import "MGSTask.h"
#import "MGSMother.h"
#import "NSBundle_Mugginsoft.h"
#import "MGSTempStorage.h"
#import "JAProcessInfo.h"
#import "MGSPath.h"

@interface MGSErrorMutableData
@end

@interface NSMutableData (MGSTask)
- (void) mgsTask_fileHandleDataAvailable:(NSNotification*)notification;
@end

@implementation NSMutableData (MGSTask)

/* 
 
 - mgs_fileHandleDataAvailable
 
 Extend the NSMutableData class to add a method called by NSFileHandleDataAvailableNotification 
 to automatically append the new data 
 
 */
- (void) mgsTask_fileHandleDataAvailable:(NSNotification*)notification
{
    NSFileHandle *fileHandle = [notification object];
    
	// an empty data block is returned on EOF
	NSData *data = [fileHandle availableData];
	if ([data length] > 0) {
		[self appendData:data];
		[fileHandle waitForDataInBackgroundAndNotify];
	}
}

@end

// class extension
@interface MGSTask()
- (void)signalDescendents:(int)signal;
- (void)closePipes;
@end

@interface MGSTask(Private)
- (void)cleanup;
@end

@implementation MGSTask

@synthesize taskOutputData = _taskOutputData;
@synthesize taskErrorData = _taskErrorData;
@synthesize taskComplete = _taskComplete;
@synthesize workingDirectoryPath = _currentDirectoryPath;

/*
 
 init
 
 */
- (id)init
{
	if ([super init]) {
		_tempFilePaths = nil;
		_readTaskDataIncrementally = NO;
		_taskComplete = NO;
	}
	
	return self;
}

/*
 
 start the task
 
 */
- (BOOL)start:(NSString *)execPath data:(NSData *)dataForStdIn withError:(NSError **)error
{
	NSString *MGSTaskStartException = @"MGSTaskStartException";
	NSString *errMsg = nil;
	NSFileHandle * fileHandle = nil;

	@try {
        *error = nil;
		
		NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
		
		MLog(DEBUGLOG, @"server bundle path is %@", [MGSPath bundlePath]);
		MLog(DEBUGLOG, @"task runner path is %@", execPath);
		if (!execPath || ![[NSFileManager defaultManager] fileExistsAtPath:execPath]) {
			errMsg = NSLocalizedString(@"Cannot find script task executable.", @"Return by server when find script task executable");
			[NSException raise:MGSTaskStartException format:errMsg, nil];
		}
		
		_taskOutputData = [[NSMutableData alloc] init];
		_currentDirectoryPath = [[MGSTempStorage sharedController] storageDirectoryWithOptions:nil];

        // determine the launch path for 32/64 bit build
#if __LP64__
        
        // the most suitable binary will be run
        NSString *launchPath = execPath;
        NSArray *launchArguments = [[NSArray alloc] initWithObjects:nil];
#else
        // request that we run 32 bit
        NSString *launchPath = @"/usr/bin/arch";
        NSArray *launchArguments = [[NSArray alloc] initWithObjects:@"-i386", execPath, nil];
        
#endif

#if MGS_USE_SANDBOX
        
        NSDictionary* environ = [[NSProcessInfo processInfo] environment];
        BOOL inSandbox = (nil != [environ objectForKey:@"APP_SANDBOX_CONTAINER_ID"]);
 

        // sandboxed app
        if (inSandbox) {
            
            // trying t launch a user script from a helper seems to be not permitted.
            // need to call this from main app thread in order to work.
            // so run server as thread rather than process.
            NSURL *userScriptsFolderURL = [[NSFileManager defaultManager]
                                       URLForDirectory:NSApplicationScriptsDirectory
                                       inDomain:NSUserDomainMask
                                       appropriateForURL:nil
                                       create:NO
                                       error:error];
            
            if (!userScriptsFolderURL || *error) {
                MLogInfo(@"Error: %@", *error);
                
                errMsg = NSLocalizedString(@"Cannot access user scripts directory: ", @"Return by server when cannot access user scripts folder in sandboxed app.");
                [NSException raise:MGSTaskStartException format:@"%@ %@", errMsg, *error];
            }
    
            

            MLogInfo(@"NSApplicationScriptsDirectory = %@", userScriptsFolderURL);

            // script path
            // the script text must include the shell path on the first line otherwise we crash
            //  #! /bin/bash
            NSString *taskRunnerExec = @"KosmicTaskLauncher.sh";

            // form task launcher path.
            // a script launched from NSApplicationScriptsDirectory escapes the sandbox.
            // note that the user will have to be prompted to move the launcher into place
            NSURL *taskRunnerURL = [NSURL fileURLWithPathComponents: @[[userScriptsFolderURL path], taskRunnerExec]];

            MLogInfo(@"taskRunnerURL = %@", taskRunnerURL);

            // initialise the task
            _unixTask = [[NSUserUnixTask alloc] initWithURL:taskRunnerURL error:error];
            if (!_unixTask || *error) {
                errMsg = NSLocalizedString(@"Cannot create unix task launcher: ", @"Return by server when cannot access application scripts task launcher in sandboxed app.");
                [NSException raise:MGSTaskStartException format:@"%@ %@", errMsg, *error];
                
            }
            
            void (^completionHandler)(NSError *err);
            
            completionHandler = ^(NSError *err) {
                if (err) {
                    NSLog(@"KosmicTaskLauncher failed: %@", err);
                } else {
                    NSLog(@"KosmicTaskLauncher okay");
                }
            };

            NSArray *taskArguments = @[@"hello", @"task"];
            
            // execute the task.
            [_unixTask executeWithArguments:taskArguments completionHandler:completionHandler];
            
        }
    
#endif
        if (YES) {
        
            // configure the task
            _task = [[NSTask alloc] init];
            [_task setLaunchPath:launchPath];
            [_task setArguments:launchArguments];
            [_task setCurrentDirectoryPath:_currentDirectoryPath];

            // task terminate notification
            [defaultCenter addObserver:self 
                              selector:@selector(taskDidTerminate:) 
                                  name:NSTaskDidTerminateNotification object:_task];
            
            
            // setup pipes for std in, out and err
            _inputPipe = [NSPipe pipe];
            if (!_inputPipe) {
                [NSException raise:MGSTaskStartException format:@"Cannot allocate input pipe"];
            }
            [_task setStandardInput:_inputPipe];

            _outputPipe = [NSPipe pipe];
            if (!_outputPipe) {
                [NSException raise:MGSTaskStartException format:@"Cannot allocate output pipe"];
            }
            [_task setStandardOutput:_outputPipe];

            _errorPipe = [NSPipe pipe];
            if (!_errorPipe) {
                [NSException raise:MGSTaskStartException format:@"Cannot allocate error pipe"];
            }
            [_task setStandardError:_errorPipe];
            
                    
            // launch task and read in background
            @try{
                [_task launch];
            } @catch (NSException *exception) {
                
                errMsg = NSLocalizedString(@"Cannot launch task. %@ : %@", @"Return by server when script task cannot be launched");
                
                // re raise
                [NSException raise:MGSTaskStartException format:errMsg, [exception name], [exception reason]];
            }
		}
        
		// read task output async
		if ((fileHandle = [_outputPipe fileHandleForReading])) {
			_taskOutputData = [NSMutableData data];
			[[NSNotificationCenter defaultCenter] addObserver:_taskOutputData 
													 selector:@selector(mgsTask_fileHandleDataAvailable:) 
														 name:NSFileHandleDataAvailableNotification object:fileHandle];
			[fileHandle waitForDataInBackgroundAndNotify];
			
		}
		
		// read task stdErr async
		if ((fileHandle = [_errorPipe fileHandleForReading])) {
			_taskErrorData = [NSMutableData data];
			[[NSNotificationCenter defaultCenter] addObserver:self 
													 selector:@selector(fileHandleErrorDataAvailable:) 
														 name:NSFileHandleDataAvailableNotification object:fileHandle];
			[fileHandle waitForDataInBackgroundAndNotify];			
		}
	
		// write data to std in
		if (dataForStdIn) {
			fileHandle = [_inputPipe fileHandleForWriting];
			[fileHandle writeData:dataForStdIn];
			[fileHandle closeFile];
		}

		
	}
	@catch (NSException *e) {
		
		errMsg = [NSString stringWithFormat:NSLocalizedString(@"Task Exception: %@ : %@.", @"Return by server when unknown script task error occurs"),
				  [e name], [e reason]];
		NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
							  errMsg, NSLocalizedDescriptionKey, nil];
		// return error
		*error = [NSError errorWithDomain: MGSErrorDomainMotherServer
									 code: MGSErrorCodeTaskLaunchException
								 userInfo: info];
		
		_outputPipe = nil;
		_inputPipe = nil;
		_errorPipe = nil;
		_taskOutputData = nil;
		_taskErrorData = nil;
		
		return NO;	
	}
	
	return YES;

}
										
/*
 
 task terminated
 
 Note that a major problem was occurring.
 In some occasions a single buffer of data was missing :
 
 2008-08-08 17:53:24.379 mothert[8678:10b] taskmain.m:257 Task data ready to be written. Size: 2780
 2008-08-08 17:53:24.384 motherd[8636:10b] MGSTask.m:150 New task data available: 510 bytes
 2008-08-08 17:53:24.387 motherd[8636:10b] MGSTask.m:152 Total task data is now: 510 bytes
 2008-08-08 17:53:24.394 motherd[8636:10b] MGSTask.m:125 Remaining task data available: 1760 bytes
 2008-08-08 17:53:24.395 motherd[8636:10b] MGSTask.m:130 Final task data is: 2270 bytes
 
 the fact that the task has ended should not prevent data from being read from the pipe.
 error was caused by fact that the task terminate notification was coming through before the
 final read notification.
 
 task termination is not now used to trigger reading final data from the buffer
 
 */
- (void)taskDidTerminate:(NSNotification *)note
{
	int exitCode = [[note object] terminationStatus];
	if (exitCode != 0) {
		MLogInfo(@"Task terminated with exit code 0");
#pragma mark warning what happens here? Anything?
	}
	
	self.taskComplete = YES;
}

/*
 
 set task complete
 
 */
- (void)setTaskComplete:(BOOL)value
{
	_taskComplete = value;
	
	if (!_taskComplete) {
		return;
	}
	
	// complete error data read
    [self readErrorPipeToEndOfFile];
    
	// complete output data read
    [self readOutputPipeToEndOfFile];
    
	// remove observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
		
	MLog(DEBUGLOG, @"Final task data is: %u bytes", [_taskOutputData length]);
	
	[self cleanup];
	
	// tell delegate that task has terminated
	if (_delegate && [_delegate respondsToSelector:@selector(taskDidTerminate:)]) {
		[_delegate taskDidTerminate:self];
	}
	
	// make sure the task is terminated
	[_task terminate];
}
										
/*
 
 set delegate
 
 */
- (void)setDelegate:(id <MGSTaskDelegate>)aDelegate
{
	_delegate = aDelegate;
}

/*
 
 terminate the task
 
 */
- (void)terminate
{
    if (_task.isRunning) {
        
        // close pipes
        [self closePipes];
        
        // kill children
        [self signalDescendents:SIGKILL];
        
        // should the task termination observer be removed here ?
        [_task terminate];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
            
        [self cleanup];
    }
}

/*
 
 - closePipes
 
 */
- (void)closePipes
{
    // docs sat we don't have to close pipes explicitly as
    // this will occur at dellocation.
    // In a GC enviornment though we may not want to wait
    // for -finalize to be called.
    [[_inputPipe fileHandleForReading] closeFile];
    [[_outputPipe fileHandleForReading] closeFile];
    [[_errorPipe fileHandleForReading] closeFile];
    _inputPipe = nil;
    _outputPipe = nil;
    _errorPipe = nil;
}
/*
 
 - processDescendents
 
 */
- (NSArray *)processDescendents
{
	JAProcessInfo *procInfo = [[JAProcessInfo alloc] init];
	NSArray *children = [procInfo descendentsOfPID:[_task processIdentifier]];
	
	return children;
}

/*
 
 - signalDescendents:
 
 */
- (void)signalDescendents:(int)sig
{
	NSArray *children = [self processDescendents];

	for (NSNumber *pid in children) {
		
		// send signal
		if (kill([pid intValue], sig) != 0) {
			MLogInfo(@"errno: %i sending signal: %i to child PID: %i", errno, sig, [pid intValue]);
		} else {
			MLog(DEBUGLOG, @"sent signal: %i to child PID: %i", sig, [pid intValue]);
		}
	}	
}

/*
 
 suspend the task
 
 */
- (void)suspend
{
	// stop children
	[self signalDescendents:SIGSTOP];

	[_task suspend];
}


/*
 
 resume the task
 
 */
- (void)resume
{
	[_task resume];
	
	// resume children
	[self signalDescendents:SIGCONT];

}

/*
 
 add temp file path to task
 
 */
- (void)addTempFilePath:(NSString *)tempPath
{
	if (!_tempFilePaths) {
		_tempFilePaths = [NSMutableArray arrayWithCapacity:1];
	}
	
	[_tempFilePaths addObject:tempPath];
}

/*
 
 - fileHandleErrorDataAvailable:
 
 */
- (void)fileHandleErrorDataAvailable:(NSNotification*)notification
{
    NSFileHandle *fileHandle = [notification object];
    
	// an empty data block is returned on EOF
	NSData *data = [fileHandle availableData];
	if ([data length] > 0) {
		[_taskErrorData appendData:data];
		[fileHandle waitForDataInBackgroundAndNotify];
	}
}

/*
 
 - readErrorPipeToEndOfFile
 
 */
- (void)readErrorPipeToEndOfFile
{
    NSFileHandle *fileHandle = nil;
    
	if ((fileHandle = [_errorPipe fileHandleForReading])) {
		[[NSNotificationCenter defaultCenter] removeObserver:_taskErrorData name:NSFileHandleDataAvailableNotification object:fileHandle];
		[_taskErrorData appendData:[fileHandle readDataToEndOfFile]];
	}

}

/*
 
 - readOutputPipeToEndOfFile
 
 */
- (void)readOutputPipeToEndOfFile
{
    NSFileHandle *fileHandle = nil;
   
    if ((fileHandle = [_outputPipe fileHandleForReading])) {
		[[NSNotificationCenter defaultCenter] removeObserver:_taskOutputData name:NSFileHandleDataAvailableNotification object:fileHandle];
		[_taskOutputData appendData:[fileHandle readDataToEndOfFile]];
	}
    
}
@end						
										
@implementation MGSTask(Private)

/*
 
 clean up
 
 */
- (void)cleanup
{

	@try 
	{

		// delete any temp files registered with the task
		if (_tempFilePaths) {
			for (NSString *path in _tempFilePaths) {
				if (![[NSFileManager defaultManager] removeItemAtPath:path error:NULL]) {
					NSLog(@"Could not remove temp file: %@", path);
				}
			}
		}
	}
	@catch(NSException *e) {
		NSLog(@"Exception: %@", e);
	}
}


@end

