//
//  MGSTask.h
//  Mother
//
//  Created by Jonathan Mitchell on 09/12/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MGSTask;


// formal delegate protocol
@protocol MGSTaskDelegate

@optional
- (void) taskDidTerminate:(id)task;

@required

@end

@interface MGSTask : NSObject {
	NSTask *_task;
	NSPipe *_inputPipe;
	NSPipe *_outputPipe;
	NSPipe *_errorPipe;
	id _delegate;
	NSMutableData * _taskOutputData;
	NSMutableData * _taskErrorData;
	NSMutableArray *_tempFilePaths;
	BOOL _readTaskDataIncrementally;
	BOOL _taskComplete;
	NSString *_currentDirectoryPath;
}

- (BOOL)start:(NSString *)processName data:(NSData *)dataForStdIn withError:(NSError **)error;
- (void)setDelegate:(id <MGSTaskDelegate>)aDelegate;
- (void)terminate;
- (void)suspend;
- (void)resume;
- (void)addTempFilePath:(NSString *)tempPath;
- (NSArray *)processDescendents;
- (void)fileHandleErrorDataAvailable:(NSNotification*)notification;
- (void)readErrorPipeToEndOfFile;
- (void)readOutputPipeToEndOfFile;

@property (readonly) NSMutableData *taskOutputData;
@property (readonly) NSMutableData *taskErrorData;
@property BOOL taskComplete;
@property (readonly) NSString *workingDirectoryPath;

@end
