//
//  MGSMotherServerController.m
//  Mother
//
//  Created by Jonathan on 11/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSMotherServerController.h"
#import "MGSMotherServerConnectionController.h"
#import "MGSMotherServerSocketController.h"
#import "MGSMotherServerLocalController.h"
#import "MGSNetController.h"


@implementation MGSMotherServerController

@synthesize connection = _connection;
@synthesize socket = _socket;
@synthesize local = _local;
@synthesize bonjour = _bonjour;

- (MGSMotherServerController *) init
{
	self = [super init];
	if (self) {
		_connection = [[MGSMotherServerConnectionController alloc] init];
		_socket = [[MGSMotherServerSocketController alloc] init];
		_local = [[MGSMotherServerLocalController alloc] init];
		_bonjour = [[MGSNetController alloc] init];
	}
	
	return self;
}


// start search for services
- (BOOL)searchForServices
{
	return [_bonjour searchForServices];
}

// resolve bonjour address
- (void)resolveAddress
{
	[_bonjour resolveServiceAddress:0 withTimeout:30];
}
 
@end


