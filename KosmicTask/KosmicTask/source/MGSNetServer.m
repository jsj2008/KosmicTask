//
//  MGSNetServer.m
//  Mother
//
//  Created by Jonathan on 23/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import "MGSMother.h"
#import "MGSNetServer.h"
#import "MGSNetServerSocket.h"
#import "MGSAsyncSocket.h"

//
// each instance of MGSNetServer communicates with 
// numerous instances of MGSNetClient
//
@implementation MGSNetServer

@synthesize netService = _netService;

/*
 This method sets up the accept socket, but does not actually start it.
 Once started, the accept socket accepts incoming connections and creates new
 instances of MGSNetServerSocket to handle them.
 */
-(id) init
{
	self = [super init];
	_serverSockets = [[NSMutableArray alloc] initWithCapacity:2];
	
	// the acceptor socket will call the delegate - (BOOL)acceptOnPort:(UInt16)portNumber method
	// when a new socket connection request occurs
	_acceptorSocket = [[MGSAsyncSocket alloc] initWithDelegate:self];

	return self;
}

// tell acceptor socket to accept connections on given port
- (BOOL)acceptOnPort:(UInt16)portNumber
{
	NSAssert(_acceptorSocket, @"acceptor socket is nil");
	
	NSError *err = nil;
	if ([_acceptorSocket acceptOnPort:portNumber error:&err]) {
		MLogInfo(@"Server waiting for connections on port %u.", portNumber);
		return YES;
	} else {
		// If you get a generic CFSocket error, you probably tried to use a port
		// number reserved by the operating system.
		// More likely there is an instance of the server already bound to the port.
		MLogInfo(@"Server cannot accept connections on port %u. Error domain %@ code %d (%@). Exiting.", portNumber, [err domain], [err code], [err localizedDescription]);
		return NO;
	}	
}

/*
 
 socket disconnected
 
 */
- (void)netSocketDisconnect:(MGSNetSocket *)netSocket
{
	NSAssert([netSocket disconnectCalled], @"server socket not disconnected");
	
	// remove the socket
	[_serverSockets removeObject:netSocket];
	
	MLog(DEBUGLOG, @"Server socket removed. count is %i.", [_serverSockets count]);

}


@end

@implementation MGSNetServer(AsyncSocketDelegate)
/*
 This method is called when a connection is accepted and a new socket is created.
 This is a good place to perform housekeeping and re-assignment -- assigning an
 controller for the new socket, or retaining it. Here, I add it to the array of
 sockets. However, the new socket has not yet connected and no information is
 available about the remote socket, so this is not a good place to screen incoming
 connections. Use onSocket:didConnectToHost:port: for that.
 */
-(void) onSocket:(MGSAsyncSocket *)sock didAcceptNewSocket:(MGSAsyncSocket *)newSocket
{
	#pragma unused(sock)
	
	MLog(DEBUGLOG, @"Server socket %d accepting connection.", [_serverSockets count] + 1);
	
	MGSNetServerSocket *serverSocket = [[MGSNetServerSocket alloc] initWithAcceptSocket:newSocket];
	[serverSocket setDelegate:self];
	
	[_serverSockets addObject:serverSocket];
}
@end




