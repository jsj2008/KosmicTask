//
//  MGSAsyncSocket.m
//  Mother
//
//  Created by Jonathan on 05/08/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
//
// Note that this subclass may be unneccessary and that the base
// AsyncSocket class may function okay under GC but the initial releases of it did not
//
#import "MGSAsyncSocket.h"
#import "MGSMother.h"

MGS_INSTANCE_TRACKER_DEFINE;

@interface AsyncSocket()
- (void)doSendBytes;
- (void)doBytesAvailable;
- (void)close;
@end

@implementation MGSAsyncSocket

/*
 
 Designated initializer
 
 */
- (id) initWithDelegate:(id)delegate userData:(long)userData
{
	if ((self = [super initWithDelegate:delegate userData:userData])) {
		disconnectCalled = NO;
		readSuspended = NO;
		writeSuspended = NO;
        
        MGS_INSTANCE_TRACKER_ALLOCATE;
	}
	
	return self;
}

/*
 
 Return YES if -disconnect has been called on this socket
 
 */
- (BOOL)disconnectCalled
{
	return disconnectCalled;
}

/*
 
 finalize
 
// A resurrection error was occurring if called -disconnect during finalize
// (a resurrection error occurs when an object that has received a finalize message is referenced
// by a nongarbage object).
// To avoid this -disconnect must be called before finalization occurs.
// The design goal is not to attempt any work in the finalizer.
//
// see http://developer.apple.com/documentation/Cocoa/Conceptual/GarbageCollection/Introduction.html
//
 
 */
- (void)finalize
{
    MGS_INSTANCE_TRACKER_DEALLOCATE;
    
	// disconnect must be called for all instances
	if (!disconnectCalled) {
		MLogInfo (@"AsyncSocket finalize without prior disconnect call: %@", self);
	}
    
#ifdef MGS_LOG_FINALIZE    
	MLog(DEBUGLOG, @"MGSAsyncSocket finalized.");
#endif
    
	[super finalize];
}

/*
 
 close override
 
 */
- (void)close
{
	if (disconnectCalled == YES) {
		MLog(DEBUGLOG, @"MGSAsyncSocket repeat call to close");
		return;
	}	
	disconnectCalled = YES;

	// the superclass close method is private hence the use of perform selector
	SEL closeSelector = @selector(close);
	if ([AsyncSocket instancesRespondToSelector:closeSelector]) {	
		[super close];	// the id cast keeps the compiler content without need for a category		
		MLog(DEBUGLOG, @"MGSAsyncSocket closed.");
	} else {
		NSAssert (NO, @"AsyncSocket no longer responds to close message.");
	}	
}

#pragma mark Suspending
/*
 
 suspend write
 
 */
- (BOOL)isWriteSuspended
{
	return writeSuspended;
}
/*
 
 set suspend write
 
 */
- (void)setWriteSuspended:(BOOL)newValue
{
	writeSuspended = newValue;
	if (!writeSuspended) {
		[self doSendBytes];
	}
}
/*
 
 suspend read
 
 */
- (BOOL)isReadSuspended
{
	return readSuspended;
}
/*
 
 set suspend read
 
 */
- (void)setReadSuspended:(BOOL)newValue
{
	readSuspended = newValue;
	if (!readSuspended) {
		[self doBytesAvailable];
	}
}
/*
 
 do send bytes
 
 private method override
 
 */
- (void)doSendBytes
{
	if (!writeSuspended) {
		[super doSendBytes];	// id cast keeps compiler happy
	}
}
/*
 
 do bytes available
 
 private method override
 
 */
- (void)doBytesAvailable
{
	if (!readSuspended) {
		[super doBytesAvailable];
	}
}
@end
