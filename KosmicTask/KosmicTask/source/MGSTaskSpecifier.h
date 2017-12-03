//
//  MGSTaskSpecifier.h
//  Mother
//
//  Created by Jonathan on 18/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSRequestProgress.h"

@class MGSNetClient;
@class MGSScript;
@class MGSClientNetRequest;
@class MGSRequestProgress;
@class MGSResult;
@class MGSError;
@class MGSNetClientProxy;

@protocol MGSNetRequestOwner;

extern NSString *MGSKeyPathNetClientHostStatus;
extern NSString *MGSTaskExecuteKeyTag;

enum _MGSTaskRunStatus {
	MGSTaskRunStatusHostUnavailable,		// host unavailable
	MGSTaskRunStatusLoading,				// loading representation
	MGSTaskRunStatusReady,				// ready to execute
	MGSTaskRunStatusExecuting,			// executing
	MGSTaskRunStatusSuspended,			// suspended
	MGSTaskRunStatusComplete,				// complete with no error
	MGSTaskRunStatusCompleteWithError,	// complete with error
	MGSTaskRunStatusTerminatedByUser,		// terminated by user
	MGSTaskRunStatusSuspendedSending,
	MGSTaskRunStatusSuspendedReceiving,
	
};
typedef NSInteger MGSTaskRunStatus;

enum _MGSTaskAvailability {
	MGSTaskNotAvailable = -1,
	MGSTaskClientNotAvailable = 0,	
	MGSTaskAvailable = 1,		// newly created task
};
typedef NSInteger MGSTaskAvailability;

enum _MGSTaskStatus {
	MGSTaskStatusInit = 0,
	MGSTaskStatusNew = 1,		// newly created task
};
typedef NSInteger MGSTaskStatus;

enum _MGSTaskDisplayType {
	MGSTaskDisplayInSelectedTab = 0, 
	MGSTaskDisplayInNewTab,
	MGSTaskDisplayInNewWindow,
};
typedef NSInteger MGSTaskDisplayType;

enum _MGSTaskActivity {
	MGSUnavailableTaskActivity = 0,		// unavailable
	MGSLoadingTaskActivity,				// loading
	MGSReadyTaskActivity,				// ready to execute
	MGSPausedTaskActivity,			// is paused	
	MGSProcessingTaskActivity,		// is processing
	MGSTerminatedTaskActivity,		// terminated 
};
typedef NSInteger MGSTaskActivity;

@interface MGSTaskSpecifier : NSObject <NSCopying> {
	MGSNetClient * _netClient;			// net client to initiate task on
	MGSNetClient *_netClientLoader;		// net client used to hold host data for tasks loaded from archive
	MGSNetClient *_netClientObserved;
	
	/* when a client disconnects and reconnects when a task is visible the netClient
	   instance here will change. in order not to have to update all our bindings we bind to
	 a proxy netClient */
	MGSNetClientProxy * _representedNetClient; // proxy client used for binding
	
	int _scriptIndex;	// index of the task script within the net client script handler
	MGSScript * _script;	// a deep copy of the task script indicated by _scriptIndex
	MGSTaskDisplayType _displayType;	// display in selected or new tab
	NSInteger _identifier;	// numeric identifier
	
	MGSClientNetRequest * _netRequest;				// currently active request for this task
	MGSRequestProgress *_requestProgress;	// request progress
	NSDate *_startTime;
	NSTimeInterval _allowedTime;
	NSTimeInterval _elapsedTime;
	NSTimeInterval _remainingTime;
	NSTimer *_processingTimer;
	MGSTaskStatus _taskStatus;
	MGSResult * _result;
	MGSTaskRunStatus _runStatus;
	MGSTaskActivity _activity;
	BOOL _isProcessing;
	eMGSRequestProgress _suspendedProgress;
}

@property (nonatomic) MGSNetClient *netClient;
@property int scriptIndex;
@property (nonatomic) MGSScript *script;
@property MGSTaskDisplayType displayType;
@property NSInteger identifier;
@property MGSNetClientProxy *representedNetClient;
@property NSTimeInterval elapsedTime;
@property NSTimeInterval remainingTime;
@property (nonatomic) MGSClientNetRequest *netRequest;
@property MGSRequestProgress *requestProgress;
@property MGSTaskStatus taskStatus;
@property (nonatomic) MGSResult *result;
@property (readonly) MGSTaskRunStatus runStatus;
@property (readonly) MGSTaskActivity activity;
@property (readonly) BOOL isProcessing;

// creation/destruction
- (id)init;
- (id)initWithMinimalPlistRepresentation:(NSDictionary *)plist;
- (void)disconnect;

- (BOOL)isEqualUUID:(id)object;

// operation
- (void)execute:(id <MGSNetRequestOwner>)owner options:(NSDictionary *)options;
- (void)execute:(id <MGSNetRequestOwner>)owner;
- (void)suspend:(id <MGSNetRequestOwner>)owner;
- (void)resume:(id <MGSNetRequestOwner>)owner;
- (void)terminate:(id <MGSNetRequestOwner>)owner;

// can perform operation
- (BOOL)canExecute;
- (BOOL)canSuspend;
- (BOOL)canTerminate;
- (BOOL)canResume;
- (BOOL)canBuild;
- (BOOL)canSave;
- (BOOL)canEdit;

- (void)taskDidComplete;
- (void)taskDidCompleteWithError:(MGSError *)error;
- (void)incrementIdentifier;

- (id) historyCopy;
- (id)mutableDeepCopyAsNewInstance;
- (id)mutableDeepCopyAsExistingInstance;
- (id)minimalPlistRepresentation;
- (void)netClientAvailable:(NSNotification *)notification;
- (MGSTaskAvailability)isAvailable;
- (NSString *)nameWithParameterValues;
- (NSString *)displayName;

// accessors
- (NSString *)UUID;
- (NSString *)name;
- (NSString *)nameWithHostPrefix;

@end
