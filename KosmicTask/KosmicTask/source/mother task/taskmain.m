/*
 *  taskmain.m
 *  KosmicTask
 *
 *  Created by Jonathan Mitchell on 09/12/2007.
 *  Copyright 2007 Mugginsoft. All rights reserved.
 *
 */

#import "TaskRunner.h"
#import <unistd.h>
#import <pthread.h>
#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>

void* WatchForParentTermination (void* arg);

#define MGS_TERMINATE_WITH_PARENT

int main (int argc, const char * argv[])
{
	// watch for parent termination
#ifdef MGS_TERMINATE_WITH_PARENT
		
	// http://old.nabble.com/Ensure-NSTask-terminates-when-parent-application-does-td22510014.html
	
	pthread_t thread; 
	int threadError = pthread_create(&thread, 0, WatchForParentTermination, 0); 
	if (threadError != 0) {
		NSLog(@"Parent process watcher thread could not be started.\n");
	} else {
		// NSLog(@"This process will terminate if its parent exits unexpectedly.\n");
	}
#else
	// NSLog(@"This process will outlive its parent if the parent exits unexpectedly.\n");
#endif

	return MGSTaskRunnerMain(argc, argv);			
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
	NSLog(@"Task Terminating--Parent Process Terminated\n"); 
	exit (0);	
	return 0; 
} 


			
			
			
			



