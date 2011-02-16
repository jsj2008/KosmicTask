//
//  MGSRemoteInterfaceController.m
//  Mother
//
//  Created by Jonathan on 23/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//


#import "MGSMother.h"
#import "MGSNetController.h"
#import "MGSNetworkInterfaceController.h"
#import "MGSNetServer.h"

@implementation MGSNetworkInterfaceController

@synthesize bonjour = _netController;

- (MGSNetworkInterfaceController *) init
{
	self = [super init];
	if (self) {
		//_connection = [[MGSMotherServerConnectionController alloc] init];
		//_socket = [[MGSMotherServerSocketController alloc] init];
		//_local = [[MGSMotherServerLocalController alloc] init];
		_netController = [[MGSNetController alloc] init];
	}

	return self;
}

// CLIENT methods

// start search for services
- (BOOL)searchForServices
{
	return [_netController searchForServices];
}

// resolve bonjour address
- (void)resolveAddress
{
	[_netController resolveServiceAddress:0 withTimeout:30];
}

// SERVER methods

// start server on port
- (BOOL)startServerOnPort:(UInt16)portNumber
{
	_Server = [[MGSNetServer alloc] init];
	if (![_Server acceptOnPort:portNumber]) {
		return NO;
	}
	
	// publish the service that is available on this port
	[_netController publishServerServiceOnPort:portNumber];
	
	return YES;
}
@end
