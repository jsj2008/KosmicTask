//
//  main.m
//  mother
//
//  Created by Jonathan Mitchell on 27/09/2007.
//  Copyright www.mugginsoft.com 2007. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSMother.h"
#include <sys/ptrace.h>

int main(int argc, char *argv[])
{

// http://www.seoxys.com/3-easy-tips-to-prevent-a-binary-crack/	
// perhaps more hassle than it is worth if the app crashes and we can't debug it!
#ifdef DENY_GDB_ATTACH
    //ptrace(PT_DENY_ATTACH, 0, 0, 0);
#endif
	
	// setup logging
	[MLog initialize];
	[[MLog sharedController] setRecycle:YES];
	[[MLog sharedController] doRecycle];
	
	MLog(DEBUGLOG, @" ");
	MLog(DEBUGLOG, @"CLIENT STARTED: Calling NSApplicationMain()...");
	MLog(DEBUGLOG, @" ");
	
    return NSApplicationMain(argc,  (const char **) argv);
}
