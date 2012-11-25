//
//  MGSMotherServer.m
//  Mother
//
//  Created by Jonathan on 04/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSMotherServer.h"
#import "MGSNetServerHandler.h"
#import "MGSServerRequestManager.h"
#import "MGSPortMapper.h"
#import "MGSDistributedNotifications.h"
#import "MGSPreferences.h"
#import "MySignalHandler.h"
#import "MGSInternetSharingServer.h"
#import "MGSSecurity.h"
#import "MGSServerPreferencesRequest.h"
#import "MGSServerPowerManagement.h"
#import "MGSTempStorage.h"

// class extension
@interface MGSMotherServer()
- (void)receivedSignalNotification:(NSNotification *)note;
- (void)receivedPreferencesNotification:(NSNotification *)note;
@end

@implementation MGSMotherServer

@synthesize initialised = _initialised;
@synthesize externalPort = _externalPort;
@synthesize listeningPort = _serverPort;

/* 
 
 init
 
 */
- (id)init
{
	if ((self = [super init])) {
		_initialised = [self initialise];
	}

	return self;
}

/*
 
 initialise
 
 */
- (BOOL)initialise
{
	
	_serverPort = 0;
	
	[[MGSServerPowerManagement sharedController] registerForIOKitSleepNotification];
	 
	/* 
	 try and get SSL identity.
	 if not present in keychain then try and create it.
	 calling this here means that the identity should be prepared
	 in advance rather than trying to create it during socket connection.
	 we also want to do this before publishing our service.
	 */
    /*
     
     if client creates the certificate then the server has no default access
     and the user has to be promped to allow keychain access for the server.
     if logging in from a remote instance this causes the remote instance to hang
     indefinately while the local user is queried.
     
     */
	CFArrayRef certificatesArray = [MGSSecurity sslCertificatesArray];
	if (!certificatesArray){
		MLogInfo(@"could not retrieve SSL identity");
	}
	
	//=====================================================================
	// initialise the request handler by accessing the shared controller.
	// this will in turn initialise the script handler which will load the
	// script dict.
	// If this initialisation fails bail out as there is no point in
	// publishing the service
	//======================================================================
	MGSServerRequestManager *requestManager = [MGSServerRequestManager sharedController];
	if (!requestManager.initialised) {
		return NO;
	}
	
	// publish the server service
	_netServerHandler = [MGSNetServerHandler sharedController];

	// register observer for signal notification
	[[NSNotificationCenter defaultCenter] 
		addObserver:self 
		selector:@selector(receivedSignalNotification:) 
		name:MySignalNotification 
		object:nil];
	
	// register to receive server preferences request notification
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedPreferencesNotification:) 
															name:MGSDistNoteServerPreferencesRequest object:@"KosmicTask"];
	
	return YES;
}

/*
 
 start server on port string
 
 This method actually starts the server. It is the first thing called by
 the run-loop.
 
 */
- (void)startServerOnPortString:(NSString *)str
{
	// requires a run-loop.
	NSAssert ([[NSRunLoop currentRunLoop] currentMode] != nil, @"Run loop is not running");
	
	UInt16 port = [str intValue];
	_serverPort = (int)port;
	
	// accept connections on port
	if (![_netServerHandler startServerOnPort:port]) {
		exit(1);
	}
	
	// start the logging timer
	[[MLog sharedController] startTimer];
	
	// create internet sharing server
	_internetSharingServer = [[MGSInternetSharingServer alloc] initWithExternalPort:self.externalPort listeningPort:self.listeningPort];
}

/*
 
 external port
 
 */
- (int)externalPort
{
	int port = (int)[[MGSPreferences standardUserDefaults] integerForKey:MGSExternalPortNumber];
	
	if (port <= 0) {
		MLogInfo(@"External port is invalid: %d. Resetting to default.", port);
		port = MOTHER_IANA_REGISTERED_PORT;
	}
	return port;

}

/*
 
 register client
 
 */
- (BOOL)registerClient:(in byref id <MGSMotherClientProtocol>)client
{
	#pragma unused(client)
	
	return NO;
}

/*
 
 unregister client
 
 */
- (BOOL)unregisterClient:(in byref id <MGSMotherClientProtocol>)client
{
	#pragma unused(client)
	
	return NO;
}

/*
 
 dispose 
 
 call on termination
 
 */
- (void)dispose
{
	// delete the storage facility
	[[MGSTempStorage sharedController] deleteStorageFacility];;
	
	// dispose of internet sharing
	[_internetSharingServer dispose];
	
	// remove observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

/*
 
 received signal notification
 
 */
- (void)receivedSignalNotification:(NSNotification *)note
{
	int signalNo = [[note object] intValue];
	
	MLog(DEBUGLOG, @"signal received: %i", signalNo);
	
	// terminate signal
	if (signalNo == SIGTERM || signalNo == SIGINT) {
		
		[self dispose];
		
		exit(0);
	}
	
}
 
/*
 
 received preferences notification
 
 */
- (void)receivedPreferencesNotification:(NSNotification *)note
{
	if (![[note userInfo] isKindOfClass:[NSDictionary class]]) {
		MLogInfo(@"invalid server preferences notification object");
		return;
	}
	
	[MGSServerPreferencesRequest parseDictionary:[note userInfo]];
}
@end
