/*
 *  SendAppleEventTest.m
 *  NDScriptTest
 *
 *  Created by Nathan Day on 26/03/05.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "SendAppleEventTest.h"

@implementation SendAppleEventTest

+ (unsigned int)numberOfThreads
{
	return 10;
}

#ifndef __OBJC_GC__

- (void)dealloc
{
	[super dealloc];
	[scriptRunner release];
}
#endif

- (void)createAppleEventTargets
{
	if( scriptRunner == nil )
	{
		unsigned int		theInstanceCount,
							theNumberOfThreads = [[self class] numberOfThreads];
		NSMutableArray		* theArray = [[NSMutableArray alloc] initWithCapacity:theNumberOfThreads];
		
		for( theInstanceCount = 0; theInstanceCount < theNumberOfThreads; theInstanceCount++ )
			[theArray addObject:[self sendAppleEventTargetWithMessage:[[NSString alloc] initWithFormat:@"Instance %u", theInstanceCount+1]]];
		
		scriptRunner = theArray;
	}
}

- (void)run
{
	[self createAppleEventTargets];
	inProgressThreads = [scriptRunner count];
	[scriptRunner makeObjectsPerformSelector:@selector(run)];
}

- (SendAppleEventTarget *)sendAppleEventTargetWithMessage:(NSString *)aMessage
{
	return [[SendAppleEventTarget alloc] initWithMessage:aMessage owner:self];
}

- (void)finished
{
	if( DecrementAtomic( &inProgressThreads ) == 1 )
	{
		[[[NSApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(finishedTest:) withObject:nil waitUntilDone:NO];
	}
}

@end


@implementation SendAppleEventTarget

+ (id)sendAppleEventTargetWithMessage:(NSString *)aMessage owner:(id)anOnwer
{
	return [[[self alloc] initWithMessage:aMessage owner:anOnwer] autorelease];
}

- (id)initWithMessage:(NSString *)aMessage owner:(id)anOwner
{
	if( (self = [super init]) != nil )
	{
		message = [aMessage retain];
		owner = anOwner;
		[self script];
	}
	return self;
}

#ifndef __OBJC_GC__

- (void)dealloc
{
	[script release];
	[message release];
	[super dealloc];
}

#endif

- (void)run
{
#if 1
	[[self script] execute];
	[owner finished];
#else
	[self script];
	[self retain];
	[NSThread detachNewThreadSelector:@selector(threadEntry:) toTarget:self withObject:message];
#endif
}

- (void)threadEntry:(id)aMessage
{
	NSAutoreleasePool		* pool = [[NSAutoreleasePool alloc] init];
	@try
	{
		if( ![[self script] execute] )
			NSLog( @"Error\n%@", [[[self script] componentInstance] error] );
	}
	@catch( NSException * anException )
	{
		@throw anException;
	}
	@finally
	{
		[owner finished];
		[[[self script] componentInstance] setAppleEventSendTarget:nil];
#if 0
		[self release];
#endif
		[pool release];
	}
}

+ (NSString *)targetApplicationName
{
	return @"NDScriptTest";
}

+ (unsigned int)numberOfAppleScriptrepeats
{
	return 20;
}

- (NDScriptContext *)script
{
	if( script == nil )
	{
		NDComponentInstance		* theCompentInstance = [NDComponentInstance componentInstance];
		NSString						* theSource = [NSString stringWithFormat:@"on run\n\ttell application \"%@\"\n\t\trepeat with theIndex from 1 to %i\n\t\t\tdisplay logging message \"%@\" & \", count \" & theIndex\n\t\tend repeat\n\tend tell\nend run", [[self class] targetApplicationName], [[self class] numberOfAppleScriptrepeats], message];
		if( (script = [[NDScriptContext alloc] initWithSource:theSource componentInstance:[NDComponentInstance componentInstance]]) != nil )
		{
			[theCompentInstance setAppleEventSendTarget:self currentProcessOnly:YES];
		}
		else
		{
				NSLog(@"Errors: %@", [theCompentInstance error]);
		}
	}
	return script;
}

struct ForwardingData
{
	NSAppleEventDescriptor	* result,
									* appleEventDescriptor;
	AESendMode					sendMode;
	AESendPriority				sendPriority;
	long							timeOutInTicks;
	AEIdleUPP					idleProc;
	AEFilterUPP					filterProc;

};
- (NSAppleEventDescriptor *)sendAppleEvent:(NSAppleEventDescriptor *)anAppleEventDescriptor
											 sendMode:(AESendMode)aSendMode
										sendPriority:(AESendPriority)aSendPriority
									 timeOutInTicks:(long)aTimeOutInTicks
											 idleProc:(AEIdleUPP)anIdleProc
										  filterProc:(AEFilterUPP)aFilterProc
{
#if 0
	return [[script componentInstance] sendAppleEvent:anAppleEventDescriptor
														  sendMode:aSendMode
													 sendPriority:aSendPriority
												  timeOutInTicks:aTimeOutInTicks
														  idleProc:anIdleProc
														filterProc:aFilterProc];
#else
	NSMutableData		* theData = [NSMutableData dataWithCapacity:sizeof(struct ForwardingData)];
	struct ForwardingData		* theForwardingData = (struct ForwardingData*)[theData mutableBytes];
	theForwardingData->appleEventDescriptor = anAppleEventDescriptor;
	theForwardingData->sendMode = aSendMode;
	theForwardingData->sendPriority = aSendPriority;
	theForwardingData->timeOutInTicks = aTimeOutInTicks;
	theForwardingData->idleProc = anIdleProc;
	theForwardingData->filterProc = aFilterProc;
	[self performSelectorOnMainThread:@selector(mainRunloopEntry:) withObject:theData waitUntilDone:YES];
	[theForwardingData->result autorelease];
	return theForwardingData->result;
#endif
}

- (void)mainRunloopEntry:(id)aData
{
	struct ForwardingData		* theForwardingData = (struct ForwardingData*)[aData mutableBytes];
	theForwardingData->result =
		[[[script componentInstance] sendAppleEvent:theForwardingData->appleEventDescriptor sendMode:theForwardingData->sendMode sendPriority:theForwardingData->sendPriority timeOutInTicks:theForwardingData->timeOutInTicks idleProc:theForwardingData->idleProc filterProc:theForwardingData->filterProc] retain]; 
}

@end