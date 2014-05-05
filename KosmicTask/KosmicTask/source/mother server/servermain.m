//
//  main.m
//  mother
//
//  Created by Jonathan Mitchell on 31/10/2007.
//  Copyright Mugginsoft 2007. All rights reserved.
//
#import "MGSMother.h"
#import "MGSMotherServer.h"
#import "MGSConnectionMonitor.h"
#import "MGSSystem.h"
#import "MySignalHandler.h"
#import "MGSCodeSigning.h"
#import "MGSTempStorage.h"
#import "MGSPath.h"
#import <unistd.h>
#import <pthread.h>
#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>

void* WatchForParentTermination (void* arg) ;

int main (int argc, const char * argv[])
{
	//
	// debugging the server
	//
	// 1. enable the wait code below.
	// 2. Run GUI as a separate exec, ie not in the Xcode environment
	// 3. attach to the task by ID.
	// 4. set breakpoints.
	// 5. set wait to 0 in debugger (right click on variable name in listview. selecte edit value. change and continue)
	//
	
//#define MGS_DEBUG_WAIT
	
#ifdef MGS_DEBUG_WAIT
	int waitx = 1; while (waitx);	// spin here to allow debugger attachment
#endif
	
	MLog(DEBUGLOG, @" ");
	MLog(DEBUGLOG, @"SERVER STARTED");
	MLog(DEBUGLOG, @" ");
	MLog(DEBUGLOG, @"KosmicTaskServer path: %@\n", [MGSPath executablePath]);
	
	// print banner
	printf ("KosmicTaskServer by Mugginsoft.");
	printf ("\nSYNTAX: %s port (if port omitted defaults to %i)", argv[0], MOTHER_IANA_REGISTERED_PORT);
	printf ("\nAccepts multiple connections from KosmicTask clients.\n");
	
	// scan cl arguments
	NSString *portString;
	if (argc == 1) {
		portString = [NSString stringWithFormat:@"%i", MOTHER_IANA_REGISTERED_PORT];
	} else if (argc == 2) {
		portString = [NSString stringWithCString:argv[1]];
	} else {
		printf ("\nInvalid  number of arguments.\n");
		exit(1);
	}
	 
	//printf ("Press Ctrl-C to exit.\n");
	fflush (stdout);
	
	// validate that min os is present
	if (![[MGSSystem sharedInstance] OSVersionIsSupported]) {
		MLogInfo(@"KosmicTaskServer requires at least OS X %@.\n", [[MGSSystem sharedInstance] minOSVersionSupported]);
		MLogInfo(@"KosmicTaskServer exiting.\n");
		
		exit(1);
	} 
	
	// check code signing
	MGSCodeSigning *codeSign = [MGSCodeSigning new];
	NSString *path = [MGSPath executablePath];
	if ([codeSign validatePath:path] != CodesignOkay) {
		MLogInfo(@"KosmicTaskServer code signing failure: %@\n", codeSign.resultString);
	} else {
		MLog(DEBUGLOG, @"KosmicTaskServer code signing: %@\n", codeSign.resultString);
	}
	
	// install the signal handler
	[MySignalHandler installSignalHandler];

	// watch for parent termination
#ifdef MGS_TERMINATE_WITH_PARENT
    
    // http://old.nabble.com/Ensure-NSTask-terminates-when-parent-application-does-td22510014.html
    
    pthread_t thread;
    int threadError = pthread_create(&thread, 0, WatchForParentTermination, 0);
    if (threadError != 0) {
        MLogInfo(@"Parent process watcher thread could not be started.\n");
    } else {
        MLogInfo(@"This process will terminate if its parent exits unexpectedly.\n");
    }
}
#else
MLogInfo(@"This process will outlive its parent if the parent exits unexpectedly.\n");
#endif

    // start the server
    [MGSMotherServer startOnPort:portString];

	// will never hit this
	return 0;
}

/*
 
 WatchForParentTermination()
 
 */
void* WatchForParentTermination (void* arg) {	
	
#pragma unused(arg)
	
	pid_t ppid = getppid ();	// get parent pid 
	
	int kq = kqueue (); 
	if (kq != -1) { 
		struct kevent procEvent;	// wait for parent to exit 
		EV_SET (&procEvent,	 // kevent 
				ppid,	 // ident 
				EVFILT_PROC,	// filter 
				EV_ADD,	 // flags 
				NOTE_EXIT,	 // fflags 
				0,	 // data 
				0);	 // udata 
		
		kevent (kq, &procEvent, 1, &procEvent, 1, 0); 
	} 
	NSLog(@"KosmicTaskServer Terminating--Parent Process Terminated\n"); 
	exit (0);	
	return 0; 
} 

