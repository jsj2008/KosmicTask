//
//  MGSTaskSpecifier.m
//  Mother
//
//  Created by Jonathan on 18/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSMother.h"
#import "MGSTaskSpecifier.h"
#import "MGSScript.h"
#import "MGSNetClient.h"
#import "MGSImageManager.h"
#import "MGSClientScriptManager.h"
#import "MGSResult.h"
#import "MGSClientRequestManager.h"
#import "MGSClientTaskController.h"
#import "MGSNetRequest.h"
#import "MGSNetClientProxy.h"
#import "MGSNotifications.h"
#import "MGSAPLicenceCode.h"
#import "MGSAppController.h"
#import "MGSTrialRestrictions.h"

NSString *MGSPlistKeyScript = @"script";
NSString *MGSPlistKeyIdentifier = @"identifier";
NSString *MGSPlistKeyServicename = @"servicename";
NSString *MGSPlistKeyServiceShortName = @"shortname";

NSString *MGSKeyPathNetClientHostStatus = @"representedNetClient.hostStatus";

const char MGSContextNetClientHostStatus;
const char MGSContextNetClientServiceShortName;
const char MGSContextNetClientServiceName;
const char MGSContextNetClientHostIcon;

@interface MGSTaskSpecifier(Private)
- (void)timerExpired:(NSTimer*)theTimer;
- (BOOL)canSetRunStatus:(MGSTaskRunStatus )status;
- (void)setLocalRunStatus:(MGSTaskRunStatus )status;
- (void)registerForNotifications;
- (void)observeNetClient:(NSKeyValueObservingOptions)options;
@end


@implementation MGSTaskSpecifier

@synthesize netClient = _netClient;
@synthesize scriptIndex = _scriptIndex;
@synthesize script = _script;
@synthesize displayType = _displayType;
@synthesize identifier = _identifier;
@synthesize representedNetClient = _representedNetClient;
@synthesize elapsedTime = _elapsedTime;
@synthesize remainingTime = _remainingTime;
@synthesize netRequest = _netRequest;
@synthesize requestProgress = _requestProgress;
@synthesize taskStatus = _taskStatus;
@synthesize result = _result;
@synthesize runStatus = _runStatus;
@synthesize isProcessing = _isProcessing;
@synthesize activity = _activity;

static NSUInteger remoteTaskExecuteCount = 0;
static NSUInteger localTaskExecuteCount = 0;
static BOOL permitExecution = YES;

#pragma mark -
#pragma mark Instance control
/*
 
 init
 
 */
- (id)init
{
    if((self = [super init])){
		_displayType = MGSTaskDisplayInSelectedTab;
		_scriptIndex = -1;
 		_identifier = 1;
		_elapsedTime = 0;
		_remainingTime = 0;
		_allowedTime = 0;
		_requestProgress = [[MGSRequestProgress alloc] init]; 
		_requestProgress.value = MGSRequestProgressReady;
		_netRequest = nil;
		_taskStatus = MGSTaskStatusInit;
		_result = nil;
		_runStatus = MGSTaskRunStatusReady;
		_isProcessing = NO;
		_activity = MGSReadyTaskActivity;
		
		// this proxy net client instance will hold the host data until if and when
		// a valid netservice instance becomes available
		_netClientLoader = [[MGSNetClient alloc] initWithNetService:nil];
		//self.representedNetClient = _netClientLoader;	// always bind to this
		self.representedNetClient = [[MGSNetClientProxy alloc] init];	// always bind to this
		self.netClient = _netClientLoader;
		
		[self registerForNotifications];
	}
	
    return self;
}


/*
 
 init with minimal plist representation
 
 */
- (id)initWithMinimalPlistRepresentation:(NSDictionary *)plist
{
	if ((self = [self init])) {
	
		NSMutableDictionary *scriptDict = [plist objectForKey:MGSPlistKeyScript];
		self.script = [MGSScript dictWithDict:scriptDict];
		self.identifier = [[plist objectForKey:MGSPlistKeyIdentifier] intValue];
		
		NSAssert(_netClientLoader, @"net client loader is nil");
		
		self.netClient.serviceName = [plist objectForKey:MGSPlistKeyServicename];
		self.netClient.serviceShortName = [plist objectForKey:MGSPlistKeyServiceShortName];
	}
	
	return self;
}

/*
 
 dispose
 
 */
- (void)dispose
{
	
}


/*
 
 finalize
 
 */
- (void)finalize
{	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	MLog(MEMORYLOG, @"%@ finalized", [[self class] description]);
	[super finalize];
}

/*
 
 - setNetRequest
 
 */
- (void)setNetRequest:(MGSNetRequest *)aRequest
{
	_netRequest = aRequest;
}

#pragma mark -
#pragma mark Instance methods
/*
 
 increment identifier
 
 */
- (void)incrementIdentifier
{
	_identifier++;
}

#pragma mark -
#pragma mark Equality

/*
 
 - isEqualUUID:
 
 */
- (BOOL)isEqualUUID:(id)object
{
	// must be same class
	if (![object isKindOfClass:[self class]]) {
		return NO;
	}
	
	// must have same UUID
	if ([[self UUID] isEqualToString:[(MGSTaskSpecifier *)object UUID]]) {
		return YES;
	}
		 
	return NO;
}

/*
 
 override hash if override isEqual
 
 */
- (NSUInteger)hash
{
	return [[self UUID] hash];
}

#pragma mark -
#pragma mark Net client

/*
 
 a net client has become available
 
 */
- (void)netClientAvailable:(NSNotification *)notification
{
	MGSNetClient *aNetClient = [notification object];
	NSAssert([aNetClient isKindOfClass:[MGSNetClient class]], @"net client is not notification object");
	
	// if no net client defined then see if the new client is an active
	// copy of the loader
	// Note: _netClient may be nil for actions loaded from archive
	if (!_netClient) {
		if ([[aNetClient serviceName] isEqualToString:[_netClientLoader serviceName]]) {
			[self setNetClient:aNetClient];
		}
		return;
	}
	
	MGSHostStatus hostStatus = [_netClient hostStatus];
	
	// if _netClient defined but has no service currently available then
	// see if new client is an active copy of the current clients old host
	if (hostStatus == MGSHostStatusNotYetAvailable || hostStatus == MGSHostStatusDisconnected) {
		if ([[aNetClient serviceName] isEqualToString:[_netClient serviceName]]) {
			[self setNetClient:aNetClient];
		}
		return;
	}
	
}

//=======================================================
//
// determine if action is available on the client
//
//
//=======================================================
- (MGSTaskAvailability)isAvailable
{
	MGSNetClient *netClient = [self netClient];
	NSAssert(netClient, @"net client is nil");	// represented client should always be valid
	
	// is the net client service available?
	// this may occur for a history action whose client has not yet become
	// available or has become unavailable
	if (netClient.hostStatus != MGSHostStatusAvailable) {
		return MGSTaskClientNotAvailable;
	}
	
	// script may no longer exist on the client
	MGSClientScriptManager *scriptController = [netClient.taskController scriptManager];
	if (-1 == [scriptController scriptIndexForUUID:[self UUID]]) {
		return MGSTaskNotAvailable;
	}
		 
	return MGSTaskAvailable;
}

/*
 
 set net client
 
 */
- (void)setNetClient:(MGSNetClient *)netClient
{
	// remove observers
	if (_netClient && _netClient == _netClientObserved) {
		@try{
			[_netClient removeObserver:self forKeyPath:@"hostStatus"];
			[_netClient removeObserver:self forKeyPath:@"serviceName"];
			[_netClient removeObserver:self forKeyPath:@"serviceShortName"];
			[_netClient removeObserver:self forKeyPath:@"hostIcon"];
		} @catch(NSException *e) {
			MLog(RELEASELOG, @"%@", [e reason]);
		}
		_netClientObserved = nil;
	}
	_netClient = netClient;
	
	[self observeNetClient:NSKeyValueObservingOptionInitial];
}


#pragma mark -
#pragma mark History
/*
 
 history copy
 
 */
- (id)historyCopy
{
	return [self mutableDeepCopyAsNewInstance];
}

#pragma mark -
#pragma mark Result
/*
 
 set result
 
 */
- (void)setResult:(MGSResult *)result
{
	// if clearing an existing result then
	// reset the action run status
	if (_result && !result) {
		[self setLocalRunStatus:MGSTaskRunStatusReady];
	}
	
	_result = result;
}

#pragma mark -
#pragma mark Copying

/*
 
 copy with zone
 
 */
-(id) copyWithZone:(NSZone*)zone 
{
	#pragma unused(zone)
	
	// create
	id copy = NSCopyObject(self, 0, NULL);
	
	// register for notifications as original
	[copy registerForNotifications];
	
	// add observers as original
	[copy observeNetClient:0];
	
	return copy;
}

/*
 
 mutable deep copy as new instance
 
 creates a copy of the action that is suitable for use
 as a new action instance.
 
 the copy will know nothing of its execution history.
 
 */
- (id)mutableDeepCopyAsNewInstance
{
	// note that this is NOT a true copy but a new instance
	// initialised with the same client and script.
	MGSTaskSpecifier *copy = [[[self class] alloc] init];
	
	// copy those instance vars that will be required to make
	// the action a usable new instance copy
	copy.netClient = _netClient;
	copy.scriptIndex = _scriptIndex;
	
	// we need a deep copy here as we may change the 
	// script parameters etc
	copy.script = [_script mutableDeepCopy];
	
	return copy;
}

/*
 
 mutable deep copy as existing instance
 
 creates a copy of the action that is suitable for use
 as an existing action instance.
 
 the copy will know its execution history
 
 */
- (id)mutableDeepCopyAsExistingInstance
{
	// actual object copy
	// all instance vars are copied.
	MGSTaskSpecifier *copy = [self copy];

	// we need a deep copy here as we may change the 
	// script parameters etc 
	copy.script = [_script mutableDeepCopy];
	
	// need a copy here as we may modify the progress
	copy.requestProgress = [_requestProgress copy];
	
	return copy;
}

#pragma mark -
#pragma mark Representation
/*
 
 minimal plist representation
 
 this representation is minimal and is intended for archiving.
 
 */
- (id)minimalPlistRepresentation
{
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:2];
	
	// exception will occur if nil inserted into dict
	@try {	
		// need the script and parameters
		MGSScript *script = [self script];
		NSAssert(script, @"script is nil");
		[dictionary setObject:[script dict]	forKey:MGSPlistKeyScript];
		
		// need the service machine name
		[dictionary setObject:[self.netClient serviceName] forKey:MGSPlistKeyServicename];
		[dictionary setObject:[self.netClient serviceShortName] forKey:MGSPlistKeyServiceShortName];
		
		// need the action identifier
		[dictionary setObject:[NSNumber numberWithInt:[self identifier]] forKey: MGSPlistKeyIdentifier];
	}
	@catch (NSException *e) {
		MLog(DEBUGLOG, @"exception name: %@ description: %@", [e name], [e reason]);
		return nil;
	}
	
	return dictionary;
}

#pragma mark -
#pragma mark Identification
/*
 
 display name
 
 */
- (NSString *)displayName
{
	NSString *displayName = nil;
	
	// if no script defined then action is a placeholder for those situations where no valid tasks exist
	if (_script) {
		displayName = [NSString stringWithFormat:@"%@: %@", [_netClient serviceShortName], [_script name]];
	} else {
		displayName = [NSString stringWithFormat:@"%@: %@", [_netClient serviceShortName], NSLocalizedString(@"No tasks available", @"Toolbar LCD display - no tasks available")];
	}
	
	return displayName;
}



/*
 
 UUID
 
 */
- (NSString *)UUID 
{
	return [_script UUID];
}

/* 
 
 script name
 
 */
- (NSString *)name 
{
	return [_script name];
}

/*
 
 name with host prefix
 
 */
- (NSString *)nameWithHostPrefix 
{
	NSString *hostName = [_netClient serviceShortName];
	if (!hostName) hostName = @"host";
	
	return [NSString stringWithFormat:@"%@-%@", hostName, [self name]];
}


/* 
 
 action name with parameter values
 
 */
- (NSString *)nameWithParameterValues 
{
	return [_script nameWithParameterValues];
}


#pragma mark -
#pragma mark Operation

/*
 
 execute
 
 */
- (void)execute:(id <MGSNetRequestOwner>)owner
{
	// cannot execute if connection not validated
	if (!self.netClient.validatedConnection) {
		
		[[NSNotificationCenter defaultCenter] 
			postNotificationName:MGSNoteConnectionLimitExceeded 
			object:self.netClient 
			userInfo:nil];
		
		return;
	}
	
	if ([self canExecute]) {
		
		if ([self.netClient isLocalHost]) {
			localTaskExecuteCount++;
		} else {
			remoteTaskExecuteCount++;
		}
			
		[self setLocalRunStatus:MGSTaskRunStatusExecuting];
		[[MGSClientRequestManager sharedController] requestExecuteTask:self withOwner:owner];
	}
}

/*
 
 terminate the action
 
 */
- (void)terminate:(id <MGSNetRequestOwner>)owner
{
	if (![self canTerminate]) {
		return;
	}
	
	switch (self.requestProgress.value) {
			
			// sending data
			// we want to terminate sending of the data
		case MGSRequestProgressSending:
		case MGSRequestProgressSuspendedSending:
			[self setLocalRunStatus:MGSTaskRunStatusTerminatedByUser];
			[[self netRequest] disconnect];
			break;
			
			// waiting for reply
			// we want to terminate execution of the remote task
		case MGSRequestProgressWaitingForReply:
		case MGSRequestProgressSuspended:
			[self setLocalRunStatus:MGSTaskRunStatusTerminatedByUser];
			[[MGSClientRequestManager sharedController] requestTerminateTask:self withOwner:owner];
			break;
			
			// receiving reply
			// we want to terminate receiving of the remote data
		case MGSRequestProgressReceivingReply:
		case MGSRequestProgressSuspendedReceiving:	
			[self setLocalRunStatus:MGSTaskRunStatusTerminatedByUser];
			[[self netRequest] disconnect];
			break;

			// ignore terminate requests at these times
		case MGSRequestProgressReplyReceived:	
			break;
			
			// shouldn't be here
		default:;
			NSString *text = [NSString stringWithFormat:@"trying to terminate invalid progress state: %ld", self.requestProgress.value];
			MLogInfo(@"%@", text);
			[self setLocalRunStatus:MGSTaskRunStatusTerminatedByUser];
			break;
	}
	

}

/*
 
 suspend  
 
 */
- (void)suspend:(id <MGSNetRequestOwner>)owner
{
	if (![self canSuspend]) {
		return;
	}
	
	_suspendedProgress = self.requestProgress.value;
	
	switch (self.requestProgress.value) {

		// sending data
		// we want to suspend the sending of the data
		case MGSRequestProgressSending:
			[self setLocalRunStatus:MGSTaskRunStatusSuspendedSending];
			[[self netRequest] setWriteSuspended:YES];
			break;
		
		// waiting for reply
		// we want to suspend the execution of the remote task
		case MGSRequestProgressWaitingForReply:
			[self setLocalRunStatus:MGSTaskRunStatusSuspended];
			[[MGSClientRequestManager sharedController] requestSuspendTask:self withOwner:owner];
			break;

		// receiving reply
		// we want to suspend the receiving of the remote data
		case MGSRequestProgressReceivingReply:
			[self setLocalRunStatus:MGSTaskRunStatusSuspendedReceiving];
			[[self netRequest] setReadSuspended:YES];
			break;

		default:;
			NSString *text = [NSString stringWithFormat:@"trying to suspend invalid progress state: %ld", self.requestProgress.value];
			MLogInfo(@"%@", text);
			break;
	}
	
}

/*
 
 resume  
 
 */
- (void)resume:(id <MGSNetRequestOwner>)owner
{
	if (![self canResume]) {
		return;
	}
	
	switch (self.runStatus) {

		// sending data suspended
		// we want to resume the sending of the data
		case MGSTaskRunStatusSuspendedSending:
			[self setLocalRunStatus: MGSTaskRunStatusExecuting];			
			[[self netRequest] setWriteSuspended:NO];
			break;
			
		// waiting for reply suspended
		// we want to resume the execution of the remote task
		case MGSTaskRunStatusSuspended:
			[self setLocalRunStatus: MGSTaskRunStatusExecuting];
			[[MGSClientRequestManager sharedController] requestResumeTask:self withOwner:owner];
			break;
			
		// receiving reply suspended
		// we want to resume the receiving of the remote data
		case MGSTaskRunStatusSuspendedReceiving:
			[self setLocalRunStatus: MGSTaskRunStatusExecuting];
			[[self netRequest] setReadSuspended:NO];
			break;
		
			// this may occur if rapidly click the play button and build up a queue of events.
		default:;
			NSString *text = [NSString stringWithFormat:@"trying to resume invalid run status: %ld", self.runStatus];
			MLogInfo(@"%@", text);
			break;
	}
}

/*
 
 disconnect the action
 
 */
- (void)disconnect
{
	[self setLocalRunStatus:MGSTaskRunStatusTerminatedByUser];
	[[self netRequest] disconnect];
}

#pragma mark -
#pragma mark Can do operation
/*
 
 can execute
 
 */
- (BOOL)canExecute
{	
	// in trial mode can only execute a fixed number of tasks before
	// having to restart
	if (MGSAPLicenceIsRestrictiveTrial() && TRIAL_RESTRICTS_FUNCTIONALITY) {
		
		// limit task executions
		if ([self.netClient isLocalHost]) {			
			if (MGS_TRIAL_MAX_LOCAL_TASK_EXECUTIONS >= 25) {
				permitExecution = NO;
			}
		} else {
			if (remoteTaskExecuteCount >= MGS_TRIAL_MAX_REMOTE_TASK_EXECUTIONS) {
				permitExecution = NO;
			}
		}
		
		// disallow execution
		if (!permitExecution) {
			
			// send restrictionApplied: up the responder chain.
			// renamed to something less obvious.
			[NSApp sendAction:@selector(appRequest) to:nil from:self];
			return NO;
		}
	}

	// can only execute if host available.
	if (self.representedNetClient.hostStatus != MGSHostStatusAvailable) {
		return NO;
	}
		
	// if cannot terminate then can execute
	if (![self canTerminate]) {
		return YES;
	}
	
	return NO;
}

 /*
 
 can suspend
 
 */
 - (BOOL)canSuspend
 {
	 // can suspend if executing
	 if (_runStatus == MGSTaskRunStatusExecuting) {
		 return YES;
	 }
	 
	 return NO;
 }
 
 /*
 
 can resume
 
 */
 - (BOOL)canResume
{
	 
	 // can resume if suspended
	 if (_runStatus == MGSTaskRunStatusSuspended || 
		 _runStatus == MGSTaskRunStatusSuspendedSending ||
		 _runStatus == MGSTaskRunStatusSuspendedReceiving
		 ) {
		 return YES;
	 }
	 
	 return NO;
}
/*
 
 can terminate
 
 */
- (BOOL)canTerminate
{
	
	// validate run status
	switch (_runStatus) {
		case MGSTaskRunStatusHostUnavailable:		// host unavailable
		case MGSTaskRunStatusReady:				// ready to execute
		case MGSTaskRunStatusComplete:			// complete with no error
		case MGSTaskRunStatusCompleteWithError:	// complete with error
		case MGSTaskRunStatusTerminatedByUser:	// terminated by user
			return NO;
			break;
			
		default:
			break;
	}

	// validate progress
	switch (self.requestProgress.value) {
			
			// cannot terminate at these times
		case MGSRequestProgressNull:
		case MGSRequestProgressReady:
		case MGSRequestProgressReplyReceived:
		case MGSRequestProgressCompleteWithNoErrors:
		case MGSRequestProgressCompleteWithErrors:
		case MGSRequestProgressCannotConnect:
			return NO;
			
		default:;
			break;
	}
	
	// can terminate if can suspend or resume
	if ([self canSuspend] || [self canResume]) {
		return YES;
	}
	
	return NO;
}

/*
 
 - canBuild
 
 */
- (BOOL)canBuild
{
	return _netClient.isConnected;
}

/*
 
 can Save
 
 */
- (BOOL)canSave
{
	return _netClient.isConnected;
}

/*
 
 can edit
 
 */
- (BOOL)canEdit
{
	// can edit if not running
	return ![self canTerminate];
}

#pragma mark -
#pragma mark Completion

/*
 
 action did complete
 
 */
- (void)taskDidComplete
{
	[self setLocalRunStatus: MGSTaskRunStatusComplete];
}


/*
 
 action did complete with error
 
 */
- (void)taskDidCompleteWithError:(MGSError *)error
{
	#pragma unused(error)
	
	[self setLocalRunStatus: MGSTaskRunStatusCompleteWithError];
}

#pragma mark -
#pragma mark KVO

/*
 
 observe value for key path
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	#pragma unused(keyPath)
	#pragma unused(object)
	#pragma unused(change)
	
	// client host status changed
	if (context == &MGSContextNetClientHostStatus) {
		
		_representedNetClient.hostStatus = _netClient.hostStatus;
		
		switch(_netClient.hostStatus) {
				
			case MGSHostStatusNotYetAvailable:
				[self setLocalRunStatus:MGSTaskRunStatusHostUnavailable];
				break;
				
			case MGSHostStatusAvailable:
				[self setLocalRunStatus:MGSTaskRunStatusReady];
				break;
				
			case MGSHostStatusNotResponding:
				break;
				
			case MGSHostStatusDisconnected:
				// terminate if active
				[self terminate:nil];
				[self setLocalRunStatus:MGSTaskRunStatusHostUnavailable];
				break;
				
			default:
				NSAssert(NO, @"invalid host status");
				
		}
	} else if (context == &MGSContextNetClientServiceShortName) {
		
		_representedNetClient.serviceShortName = _netClient.serviceShortName;
		
	} else if (context == &MGSContextNetClientServiceName) {
		
		_representedNetClient.serviceName = _netClient.serviceName;
	
	} else if (context == &MGSContextNetClientHostIcon) {
		
		_representedNetClient.hostIcon = _netClient.hostIcon;
	}
}

@end


@implementation MGSTaskSpecifier(Private)

#pragma mark KVO
/*
 
 add net client observers
 
 */
- (void)observeNetClient:(NSKeyValueObservingOptions)options
{
	_netClientObserved = _netClient;
	
	// add observers
	[_netClient addObserver:self forKeyPath:@"hostStatus" options:options context:(void *)&MGSContextNetClientHostStatus];
	[_netClient addObserver:self forKeyPath:@"serviceName" options:options context:(void *)&MGSContextNetClientServiceName];
	[_netClient addObserver:self forKeyPath:@"serviceShortName" options:options context:(void *)&MGSContextNetClientServiceShortName];
	[_netClient addObserver:self forKeyPath:@"hostIcon" options:options context:(void *)&MGSContextNetClientHostIcon];
}

#pragma mark -
#pragma mark Notification handling
/*
 
 register for notifications
 
 */
- (void)registerForNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netClientAvailable:) name:MGSNoteClientAvailable object:nil];
}

#pragma mark -
#pragma mark Run status

/*
 
 can set run status
 
 */
-(BOOL)canSetRunStatus:(MGSTaskRunStatus)status
{
	BOOL clientConnected = _netClient.isConnected;
	
	switch (status) {
			
		case MGSTaskRunStatusHostUnavailable:
			return !clientConnected;
			break;
			
		case MGSTaskRunStatusReady:
		case MGSTaskRunStatusComplete:
		case MGSTaskRunStatusCompleteWithError:
		case MGSTaskRunStatusExecuting:
		case MGSTaskRunStatusSuspended:
		case MGSTaskRunStatusSuspendedSending:
		case MGSTaskRunStatusSuspendedReceiving:
		case MGSTaskRunStatusTerminatedByUser:
			return clientConnected;			
			break;
			
		default:
			NSAssert(NO, @"invalid run status");
			return NO;
			break;
	}

	return YES;
}

/*
 
 set local run state
 
 defined as a readonly property so need to update KVO manually.
 in order to keep this method manageable it only sets the runstate
 and the progress. after the state has been set the appropriate task
 action must be performed.
 
 */
- (void)setLocalRunStatus:(MGSTaskRunStatus)status
{
	// validate that run status can be set
	if (![self canSetRunStatus:status]) {
		return;
	}
	
	MGSTaskRunStatus prevRunStatus = _runStatus;
	
	// runStatus is read only so need to do manual KVO update
	[self willChangeValueForKey:@"runStatus"];
	_runStatus = status;
	
	// set action activity
	[self willChangeValueForKey:@"activity"];
	switch (_runStatus) {
			
		case MGSTaskRunStatusHostUnavailable:
			_activity = MGSUnavailableTaskActivity;
			break;
			
		case MGSTaskRunStatusReady:
		case MGSTaskRunStatusComplete:
		case MGSTaskRunStatusCompleteWithError:
			_activity = MGSReadyTaskActivity;
			break;
			
		case MGSTaskRunStatusExecuting:
			_activity = MGSProcessingTaskActivity;			
			break;
			
		case MGSTaskRunStatusSuspended:
		case MGSTaskRunStatusSuspendedSending:
		case MGSTaskRunStatusSuspendedReceiving:
			_activity = MGSPausedTaskActivity;
			break;
			
		case MGSTaskRunStatusTerminatedByUser:
			_activity = MGSTerminatedTaskActivity;			
			break;
		
		default:
			NSAssert(NO, @"invalid run status");
			break;
	}
	[self didChangeValueForKey:@"activity"];
	[self didChangeValueForKey:@"runStatus"];
	BOOL currentlyProcessing = NO; 
	
	
	// determine progress
	switch (_runStatus) {
			
		case MGSTaskRunStatusHostUnavailable:
			self.requestProgress.value = MGSRequestProgressCannotConnect;
			break;
			
		case MGSTaskRunStatusReady:
			self.elapsedTime = 0;
			self.remainingTime = 0;
			_allowedTime = 0;
			[self.requestProgress initialize];
			break;
			
		case MGSTaskRunStatusExecuting:
			
			switch (prevRunStatus) {
					
				// restore suspended progress
				case MGSTaskRunStatusSuspended:
				case MGSTaskRunStatusSuspendedSending:
				case MGSTaskRunStatusSuspendedReceiving:
					self.requestProgress.value = _suspendedProgress;
					break;
					
				default:
					break;
			}
			
			break;
			
		case MGSTaskRunStatusSuspended:
			self.requestProgress.value = MGSRequestProgressSuspended;
			break;

		case MGSTaskRunStatusSuspendedSending:
			self.requestProgress.value = MGSRequestProgressSuspendedSending;
			break;
		
		case MGSTaskRunStatusSuspendedReceiving:
			self.requestProgress.value = MGSRequestProgressSuspendedReceiving;
			break;
			
		case MGSTaskRunStatusComplete:
			break;
			
		case MGSTaskRunStatusCompleteWithError:
			break;
			
		case MGSTaskRunStatusTerminatedByUser:
			self.requestProgress.value = MGSRequestProgressTerminatedByUser;
			break;
			
		default:
			NSAssert(NO, @"invalid run status");
			break;
	}
	
	// determine isProcessing status
	switch (_runStatus) {

		case MGSTaskRunStatusExecuting:
		case MGSTaskRunStatusSuspended:
		case MGSTaskRunStatusSuspendedSending:
		case MGSTaskRunStatusSuspendedReceiving:
			currentlyProcessing = YES;
			break;
			
		default:
			currentlyProcessing = NO;
			break;
	}
	
	// isProcessing is read only so need to do manual KVO update
	if (currentlyProcessing != _isProcessing) {
		
		[self willChangeValueForKey:@"isProcessing"];
		_isProcessing = currentlyProcessing;
		[self didChangeValueForKey:@"isProcessing"];

		// update timer while processing
		if (_isProcessing) {
			_startTime = [NSDate date];
			self.elapsedTime = 0;
			_allowedTime = [_script timeout];	// will be 0 if no timeout defined
			self.remainingTime = _allowedTime;
			_processingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerExpired:) userInfo:nil repeats:YES];
		} else {
			[self timerExpired:_processingTimer]; // final update
			[_processingTimer invalidate];
			_processingTimer = nil;
		}
		
	}
	
	[self didChangeValueForKey:@"activity"];
	[self didChangeValueForKey:@"runStatus"];

}

#pragma mark -
#pragma mark Timers
/*
 
 timer expired
 
 */
- (void)timerExpired:(NSTimer*)theTimer
{
	#pragma unused(theTimer)
	
	self.elapsedTime = -[_startTime timeIntervalSinceNow];
	if (_allowedTime > 0) {
		NSTimeInterval remainingTime = _allowedTime - (int)_elapsedTime;
		self.remainingTime = remainingTime > 0 ? _allowedTime - (int)_elapsedTime : 0;
	}
}
@end
