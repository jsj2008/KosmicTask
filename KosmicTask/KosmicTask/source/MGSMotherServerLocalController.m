//
//  MGSMotherServerLocalController.m
//  Mother
//
//  Created by Jonathan on 11/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSMotherServerLocalController.h"
#import "NSBundle_Mugginsoft.h"
#import "MGSSecurity.h"
#import "JAProcessInfo.h"
#import "MGSPath.h"
#import "MGSMotherServer.h"

NSString *MGSKosmicTaskAgentName = @"KosmicTaskServer";

@interface MGSMotherServerLocalController()
- (void)startTimerExpired:(NSTimer *)theTimer;
- (void)taskTimerExpired:(NSTimer *)theTimer;
- (BOOL)threadLaunch;
- (BOOL)processLaunch;
- (BOOL)processLaunchIfNotRunning;
- (BOOL)threadLaunchIfNotRunning;
- (void)processKill;
- (void)threadKill;
@end

@implementation MGSMotherServerLocalController

@synthesize runAsProcess = _runAsProcess;

/*
 
 - init
 
 */
- (id)init
{
    self = [super init];
    if (self) {
        
        // default to run as process?
        _runAsProcess = YES;
    }
    
    return self;
}

/*
 
 - launchIfNotRunning
 
 */
- (BOOL)launchIfNotRunning
{
	if (self.runAsProcess) {
        return [self processLaunchIfNotRunning];
    }
    
    return [self threadLaunchIfNotRunning];
}
/*
 
 - processLaunchIfNotRunning
 
 */
- (BOOL)processLaunchIfNotRunning
{
	JAProcessInfo *processInfo = [[JAProcessInfo alloc] init];
	[processInfo obtainFreshProcessList];
	if (![processInfo findProcessWithName: MGSKosmicTaskAgentName]) {
		return [self launch];
	}
	
	return NO;
}
/*
 
 - threadLaunchIfNotRunning
 
 */
- (BOOL)threadLaunchIfNotRunning
{
	if (![_serverThread isExecuting]) {
        _serverThread = nil;
		return [self launch];
	}
	
	return NO;
}
/*
 
 launch the local server
 
 */
- (BOOL)launch
{
    if (self.runAsProcess) {
        return [self processLaunch];
    }
    
    return [self threadLaunch];
}

/*
 
 - processLaunch
 
 */
- (BOOL)processLaunch
{
    if (!_serverTask) {
        
		// path to agent executable
		NSString *agentPath = [MGSPath bundlePathForHelperExecutable:MGSKosmicTaskAgentName];
        
		/*
		 try and get SSL identity.
		 if not present in keychain then try and create it.
		 calling this here means that the identity should be prepared
		 in advance rather than trying to create it during socket connection.
		 we also want to do this before publishing our service.
		 */
        
        if (YES) {
            
            /*
             
             set the identity options.
             this includes:
             
             1. list of paths that are trusted to access the identity without triggering a user prompt.
             
             */
            NSArray *paths = [NSArray arrayWithObjects:agentPath, nil];
            [MGSSecurity setIdentityOptions:[NSDictionary dictionaryWithObjectsAndKeys:paths, @"trustedAppPaths", nil]];
            
            CFArrayRef certificatesArray = [MGSSecurity sslCertificatesArray];
            if (!certificatesArray){
                MLogInfo(@"could not retrieve SSL identity");
                NSRunAlertPanel(NSLocalizedString(@"SSL identity not found.", @"SSL identity not found alert title text"),
                                NSLocalizedString(@"Secure communications will not be available.", @"SSL identity alert title text"),
                                NSLocalizedString(@"OK", @"SSL identity alert button text"),nil,nil);
            }
		}
        
        // determine the launch path for 32/64 bit build
#if __LP64__
        
        // the most suitable binary will be run
        NSString *launchPath = agentPath;
        NSArray *serverArguments = [[NSArray alloc] initWithObjects:nil];
#else
        // request that we run 32 bit
        NSString *launchPath = @"/usr/bin/arch";
        NSArray *serverArguments = [[NSArray alloc] initWithObjects:@"-i386", agentPath, nil];
        
#endif
        
        // allocate NSTask
		_serverTask = [[NSTask alloc] init];
		[_serverTask setLaunchPath:launchPath];
		[_serverTask setArguments:serverArguments];
		
		// launch it
		// note that if the server is already running no exception
		// occurs. in this case [_serverTask isRunning] returns true but the server
		// instance will terminate itself as it will not be able to bind to the required socket port
		@try{
			[_serverTask launch];
		}
		@catch (NSException *exception) {
			MLog(DEBUGLOG, @"Exception launching server with agent path: %@\nLaunch path: %@\n Exception: %@", agentPath, launchPath, exception);
			_serverTask = nil;
			return NO;
		}
		
		if ([_serverTask isRunning]) {
			_timer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(startTimerExpired:) userInfo:nil repeats:NO];
            
		}
		
		// cannot seem to observe isRunning, hence timers
		//[_serverTask addObserver:self forKeyPath:@"isRunning" options:0 context:nil];
	}
	
	
	return YES;
}

/*
 
 - threadLaunch
 
 */
- (BOOL)threadLaunch
{
    if (_serverThread) {
        return NO;
    }
    
    // create thread
   _serverThread = [[NSThread alloc] initWithTarget:[MGSMotherServer class]
                                                 selector:@selector(startWithOptions:)
                                                   object:nil];
    
    if (!_serverThread) {
        return NO;
    }
    
    // start the thread
    [_serverThread start];
    
    return YES;
}

/*
 
 first timer expired after launch
 
 */
- (void)startTimerExpired:(NSTimer *)theTimer
{
	#pragma unused(theTimer)
	
	[_timer invalidate];
	_timer = nil;
	
	// if the task is running then try and keep it running.
	// it may not be running if it cannot establish a port etc due to another instance.
	// in this case it is pointless to keep trying to restart the task.
	//
	// of course there is always launchd to look forward too.
	//
	if ([_serverTask isRunning]) {
		_timer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(taskTimerExpired:) userInfo:nil repeats:YES];		
	}
}

/*
 
 task timer expired
 if task is not running then relaunch it
 
 */
- (void)taskTimerExpired:(NSTimer *)theTimer
{
	#pragma unused(theTimer)
	
	if (![_serverTask isRunning]) {
		_serverTask = nil;
		[_timer invalidate];
		_timer = nil;
		MLog(DEBUGLOG, @"relaunching server");
		[self launch];
	}
}

/*
 
 kill the local server
 
 */
- (void) kill
{
    if (self.runAsProcess) {
        return [self processKill];
    }
    
    return [self threadKill];
}

/*
 
 - processKill
 
 */
- (void)processKill
{
	if (!_serverTask) {
		return;
	}
	
	if ([_serverTask isRunning]) {
		[_serverTask terminate];
	}
	_serverTask = nil;
	
	return;    
}

/*
 
 - threadKill
 
 */
- (void)threadKill
{
    if (!_serverThread) {
		return;
	}
	
    // we really just want the thread to exit along with the application
	
	return;
}
@end




