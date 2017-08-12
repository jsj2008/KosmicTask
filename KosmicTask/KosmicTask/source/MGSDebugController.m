//
//  DebugController.m
//  mother
//
//  Created by Jonathan Mitchell on 06/10/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import "MGSDebugController.h"
#import <string.h>



@implementation MGSDebugController

/*
 
 init
 
 */
- (id)init
{
	self = [super initWithWindowNibName:@"DebugPanel"];
	return self;
}

/*
 
 window did load
 
 */
- (void)windowDidLoad
{
	// set the coredump process id outlet
	int  processId = [[NSProcessInfo processInfo] processIdentifier];
	NSString  *coreDump = [NSString stringWithFormat: @"%@%d", [coreDumpProcess stringValue], processId];
	[coreDumpProcess setStringValue:coreDump];
}

/* 
 
 this WILL crash the app.
 it should only be called to verify that core dumps are occurring
 and to test the crash reporting mechanism.
 
*/
- (IBAction)assertFail:(id)sender
{ 
	#pragma unused(sender)
	
	// trying to write to a literal string should generate an access error
	//char *s = "a";
	//s[0] = 0;

	// http://developer.apple.com/tools/xcode/symbolizingcrashdumps.html
#define CRASH_CODE 1
#if CRASH_CODE
	//abort();
	//(void)strlen((const char *)1); // doesn't seem to have effect
	//NSDecimalNumber *n = (NSDecimalNumber *)[NSDecimalNumber numberWithInt:0];
	//[n decimalNumberByAdding:nil];
	//abort(); // calls raise(SIGABRT); abort may delete temporary files etc
	raise(SIGABRT); // also SIGFPE, SIGSEGV
#endif
}

/*
 
 raise an exception
 
 */
- (IBAction)raiseException:(id)sender
{
	#pragma unused(sender)
	
	[NSException raise:@"Debug controller generated exception" format:nil, nil];
	[NSException raise:@"Debug controller generated exception" format:nil, nil];
}

/*
 
 run the collector
 
 */
- (IBAction)collect:(id)sender
{
	#pragma unused(sender)
	
	//[[NSGarbageCollector defaultCollector] collectExhaustively];
}

@end
