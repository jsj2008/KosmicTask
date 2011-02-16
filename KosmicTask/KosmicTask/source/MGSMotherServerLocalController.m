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

NSString *MGSMotherServerDaemonName = @"KosmicTaskServer";
NSString *MGSMotherServerScriptTaskName = @"KosmicTaskASRunner";

@interface MGSMotherServerLocalController()
- (void)startTimerExpired:(NSTimer *)theTimer;
- (void)taskTimerExpired:(NSTimer *)theTimer;
@end

@implementation MGSMotherServerLocalController

/*
 
 launch the local server if not running
 
 */
- (BOOL)launchIfNotRunning
{
	JAProcessInfo *processInfo = [[JAProcessInfo alloc] init];
	[processInfo obtainFreshProcessList];
	if (![processInfo findProcessWithName: MGSMotherServerDaemonName]) {
		return [self launch];
	}
	
	return NO;
}
/*
 
 launch the local server
 
 */
- (BOOL) launch
{
	if (!_serverTask) {
		
		/* 
		 try and get SSL identity.
		 if not present in keychain then try and create it.
		 calling this here means that the identity should be prepared
		 in advance rather than trying to create it during socket connection.
		 we also want to do this before publishing our service.
		 */
		CFArrayRef certificatesArray = [MGSSecurity sslCertificatesArray];
		if (!certificatesArray){
			MLog(RELEASELOG, @"could not retrieve SSL identity");
			NSRunAlertPanel(NSLocalizedString(@"SSL identity not found.", @"SSL identity not found alert title text"),
							NSLocalizedString(@"Secure communications will not be available.", @"SSL identity alert title text"),
							NSLocalizedString(@"OK", @"SSL identity alert button text"),nil,nil); 
		}
		
		// get server path from bundle
		NSBundle *mainBundle = [NSBundle mainBundle];
		
		// path to agent/daemon executable
		// NOTE:
		// Placing motherd in pathForAuxiliaryExecutable (which is just in /contents/MACOS) causes a curious problem.
		// When an AppleScript is run the componentInstance contacts the windowServer and if it is being run from
		// the bundle's /contents/MACOS it shows a dock icon for it!
		// Moving the executable to the resource folder solves the problem.
		// However code siging doesn't like executables in the resources folder.
		// Creating a further an Auxiliary sub folder in /Contents/MacOs seems to work.
		NSString *serverExecPath = [mainBundle pathForCustomAuxiliaryExecutable:MGSMotherServerDaemonName];		
		//NSString *serverExecPath = [mainBundle pathForAuxiliaryExecutable:MGSMotherServerDaemonName];
		//NSString *serverExecPath = [mainBundle pathForResource:MGSMotherServerDaemonName ofType:nil];

		_serverTask = [[NSTask alloc] init];
		[_serverTask setLaunchPath:serverExecPath];
		//[serverTask setArguments:serverArguments];
		
		// launch it
		// note that if the server is already running no exception
		// occurs. in this case [_serverTask isRunning] returns true but the server
		// instance will terminate itself as it will not be able to bind to the required socket port
		@try{
			[_serverTask launch];
		} 
		@catch (NSException *exception) {
			MLog(DEBUGLOG, @"Exception launching server.");
			[_serverTask release];
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
		MLog(DEBUGLOG, @"relaunching motherd");
		[self launch];
	}
}

/*
 
 kill the local server
 
 */
- (void) kill
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
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (![_serverTask isRunning]) {
		_serverTask = nil;
		[self launch];
	}
}
 */
@end




