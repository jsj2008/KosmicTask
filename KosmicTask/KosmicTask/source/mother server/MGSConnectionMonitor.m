//
//  MGSConnectionMonitor.m
//  Mother
//
//  Created by Jonathan on 16/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSConnectionMonitor.h"
#import "NSNetService_errors.h"

@implementation MGSConnectionMonitor 

@end

@implementation MGSConnectionMonitor (NSNetServiceDelegate)

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
	MLog(DEBUGLOG, @"failed to publish = %@", [NSNetService errorDictString:errorDict]);
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
	MLog(DEBUGLOG, @"failed to resolve = %@", [NSNetService errorDictString:errorDict]);
}

- (void)netServiceDidPublish:(NSNetService *)sender
{
	MLog(DEBUGLOG, @"did publish service name : %@ type: %@", [sender name], [sender type]);
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
	MLog(DEBUGLOG, @"did resolve address for service name : %@ type: %@", [sender name], [sender type]);
}

- (void)netServiceDidStop:(NSNetService *)sender
{
	MLog(DEBUGLOG, @"service did stop for service name : %@ type: %@", [sender name], [sender type]);
}
@end


@implementation MGSConnectionMonitor (NSConnectionDelegate)

- (BOOL) connection:(NSConnection *)ancestor shouldMakeNewConnection:(NSConnection *)conn
{
	MLog(DEBUGLOG, @"creating new connection: %d total connections", [[NSConnection allConnections] count]);
	
	return YES;
}

@end


@implementation MGSConnectionMonitor (NSConnectionNotification)
/*
 Posted when an NSConnection object is deallocated or when it’s notified that its 
 NSPort object has become invalid. The notification object is the NSConnection object. 
 This notification does not contain a userInfo dictionary.
 
 An NSConnection object attached to a remote NSSocketPort object cannot detect when 
 the remote port becomes invalid, even if the remote port is on the same machine. 
 Therefore, it cannot post this notification when the connection is lost. 
 Instead, you must detect the timeout error when the next message is sent.
 
 The NSConnection object posting this notification is no longer useful, 
 so all receivers should unregister themselves for any notifications involving the NSConnection object.
 */

- (void) connectionDidDie:(NSNotification *)note
{
	NSConnection *connection = [note object];
	MLog(DEBUGLOG, @"connection did die: %@", connection);
}
		  
- (void) connectionDidInitialize:(NSNotification *)note
{
	NSConnection *connection = [note object];
	MLog(DEBUGLOG, @"connection did initialize: %@", connection);
}
		  
@end
