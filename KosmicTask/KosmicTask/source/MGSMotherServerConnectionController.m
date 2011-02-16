//
//  MGSMotherClient.m
//  Mother
//
//  Created by Jonathan on 11/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSMotherServerConnectionController.h"
#import "MGSMotherClient.h"
#import <sys/socket.h>
#import <netinet/in.h>

@interface MGSMotherServerConnectionController (Private)
- (void)cleanup;
@end

@implementation MGSMotherServerConnectionController

// synthesize properties
@synthesize connected = _serverConnected;
@synthesize hostName = _hostName;

- (MGSMotherServerConnectionController *)init
{
	if (self = [super init]) {
		_serverConnected = NO;
		self.hostName = @"127.0.0.1";
		
		_clientController = [[MGSMotherClient alloc] init];
	}
	return self;
}

// connect to address
// addressData contains a socket structure wrapped in an NSData
- (BOOL)connectToAddress:(NSData *)addressData
{
	
	// disconnect of connected
	if (self.connected)
	{
		[self disconnect];
	}

	// create the send port
	NSSocketPort *sendPort;
	//sendPort = [[NSSocketPort alloc] initRemoteWithTCPPort:8081 host:self.hostName];
	sendPort = [[NSSocketPort alloc] initRemoteWithProtocolFamily:AF_INET 
									socketType:SOCK_STREAM protocol:IPPROTO_TCP address:addressData];
	if (!sendPort) {
		MLog(DEBUGLOG, @"cannot create send port");
		return NO;
	}

	// connection initialised notifcation
	// must be set before connection is initialised hen nil argument
	// of limited use
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(connectionDidInitialize:)
												 name:NSConnectionDidInitializeNotification
											   object:nil];
	// create connection
	NSConnection *connection = [NSConnection connectionWithReceivePort:nil sendPort:sendPort];
	if (!connection) {
		MLog(DEBUGLOG, @"cannot create connection");
		return NO;
	}

	// connection died notifcation
	// also of limited use for remote connections
	[[NSNotificationCenter defaultCenter] addObserver:self 
											selector:@selector(connectionDidDie:)
												 name:NSConnectionDidDieNotification
											   object:connection];
	// set timeouts
	[connection setRequestTimeout:10.0];
	[connection setReplyTimeout:10.0];
	
	// connect to server
	@try {
		
		// get the proxy
		// note that if the host cannot reply there can be a 75sec wait for the socket to timeout
		// before an NSPortTimeoutException is raised
		_motherServerProxy = [connection rootProxy];
		if (_motherServerProxy == nil) {
			MLog(DEBUGLOG, @"Failed to connect to server %@", self.hostName);
			_serverConnected = NO;
			return NO;
		}

		// set protocol
		[_motherServerProxy setProtocolForProxy:@protocol(MGSMotherServerProtocol)];
		_serverConnected = YES;
		
		// register client
		if (![_motherServerProxy registerClient:_clientController]) {
			MLog(DEBUGLOG, @"Client cannot register with server");
			[self cleanup];
			return NO;			
		}
	}
	@catch (NSException *e) {
		MLog(DEBUGLOG, @"Exception - unable to connect to server proxy: %@", e),
		[self cleanup];
		return NO;
	}
	
	return YES;
}

// disconnect from the remote server
- (BOOL)disconnect
{
	// the remote socket object cannot tell if the connection
	// is invalidated by the client hence when the
	// client is unregistered the server will invalidate its own connection
	if (_motherServerProxy) {
		@try {
			[_motherServerProxy unregisterClient:_clientController];
			MLog(DEBUGLOG, @"client disconnected from remote server");
		}
		@catch (NSException *e) {
			MLog(DEBUGLOG, @"error disconnecting client from remote server");
		}
	}
	
	[self cleanup];
	return YES;
}
@end

@implementation MGSMotherServerConnectionController (Private)

- (void) cleanup
{
	NSConnection *connection = [_motherServerProxy connectionForProxy];
	[[connection sendPort] invalidate];
	[connection invalidate];
	_motherServerProxy = nil;
	_serverConnected = NO;
	MLog(DEBUGLOG, @"client connection invalidated");
}

@end

@implementation MGSMotherServerConnectionController (NSConnectionNotification)

// when a remote socket connection dies unexpectedly the local connection 
// is not informed so this notification will only be raised when the
// client terminates the connection
- (void) connectionDidDie:(NSNotification *)note
{
	NSConnection *connection = [note object];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSConnectionDidDieNotification object:connection];
	MLog(DEBUGLOG, @"client connection did die: %@", connection);
}

- (void) connectionDidInitialize:(NSNotification *)note
{
	NSConnection *connection = [note object];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSConnectionDidInitializeNotification object:connection];
	MLog(DEBUGLOG, @"client connection did initialize: %@", connection);
}

@end
