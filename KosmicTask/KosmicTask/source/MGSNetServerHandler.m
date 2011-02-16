//
//  MGSNetController.m
//  Mother
//
//  Created by Jonathan on 17/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSNetServerHandler.h"
#import "MGSNetServer.h"
#import "MGSNetClient.h"
#import "NSNetService_errors.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import "MGSBonjour.h"
#import "MGSPreferences.h"
#import "MGSLM.h"

#define LMTestInterval 1 * 60

static MGSNetServerHandler *_sharedController = nil;

// class extension
@interface MGSNetServerHandler()
- (void)serverDo:(NSTimer*)theTimer;
@end

@interface MGSNetServerHandler (Private)
// server
- (void)publishServerServiceOnPort:(UInt16)portNumber;

@end

@implementation MGSNetServerHandler

@synthesize serviceType = _serviceType;
@synthesize serviceName = _serviceName;
@synthesize domain = _domain;
@synthesize delegate = _delegate;


#pragma mark -
#pragma mark Class Methods

+ (id)sharedController
{
	if (!_sharedController) {
		_sharedController = [[self alloc] init];
	}
	return _sharedController;
}

#pragma mark -
#pragma mark Instance Methods

- (MGSNetServerHandler *)init
{
	if ((self = [super init])) {
		self.domain = MGSBonjourDomain;
		self.serviceType = MGSBonjourServiceType;
		
		// note that the service name must be different for each server
		// on the network otherwise an NSNetServicesCollisionError will occur
		// see http://developer.apple.com/qa/qa2001/qa1228.html
		// for notes on service naming
		self.serviceName = [MGSBonjour serviceName];
		_netServer = [[MGSNetServer alloc] init];
		_LMTimer = nil;
	}
	return self;
}

// start server on port
- (BOOL)startServerOnPort:(UInt16)portNumber
{

	if (![_netServer acceptOnPort:portNumber]) {
		return NO;
	}
	
	// publish the service that is available on this port
	[self publishServerServiceOnPort:portNumber];
	
	// start the licence manager timer
	if (!_LMTimer) {
		_LMTimer = [NSTimer scheduledTimerWithTimeInterval:LMTestInterval target:self selector:@selector(serverDo:) userInfo:nil repeats:YES];
	}

	return YES;
}

/*
 
 licence manager timer has expired
 
 sensitive message name is not descriptive 
 
 */
- (void)serverDo:(NSTimer*)theTimer
{	
	#pragma unused(theTimer)
	
	MGSLM *licenceManager = [MGSLM sharedController];
	if (!licenceManager) {
		goto errorExit;
	}
	
	NSInteger licenceMode = [licenceManager mode];
	switch (licenceMode) {
		case MGSValidLicenceMode:
			break;
						
		case MGSInvalidLicenceMode:
		default:
			goto errorExit;
	}
	
	return;
	
errorExit:;
	MLog(RELEASELOG, @"KosmicTask server has detected an invalid or missing licence file. Server is terminating.\n");
	exit(1);
}

/*
 * update TXT record
 * see Technical Q&A QA1389
 */
- (void)updateTXTRecord
{
	//
	// set the text record
	// note that this only becomes accessible to the client after the
	// service has been resolved unless it is being monitored.
	//
	NSString *userName = NSUserName();
	BOOL sslEnabled = [[MGSPreferences standardUserDefaults] boolForKey:MGSEnableServerSSLSecurity withPreSync:YES];
	NSInteger usernameDisclosureMode = [[MGSPreferences standardUserDefaults] integerForKey:MGSUsernameDisclosureMode];
	
	MLog(DEBUGLOG, @"updating TXT record");
	
	// seems only to function well when objects are strings (or perhaps can be UTF-8 encoded)
	NSDictionary *txtDictionary = [NSDictionary dictionaryWithObjectsAndKeys: 
								   (usernameDisclosureMode == DISCLOSE_USERNAME_TO_NONE ?  @"" : userName), MGSTxtRecordKeyUser, 
								   (sslEnabled ? MGS_TXT_RECORD_YES : MGS_TXT_RECORD_NO), MGSTxtRecordKeySSL,
								   nil];
	
	// Note that the client needs to be in receipt of this information before attempting
	// to use the network connection. The client HAS to know the current SSL state.
	NSData *TXTRecord = [NSNetService dataFromTXTRecordDictionary:txtDictionary];
	if (![_netServer.netService setTXTRecordData: TXTRecord]) {
		MLog(DEBUGLOG, @"failed to set NSNetService text record");
	}
	
}
@end

//
// NSNetService delegate methods
//
@implementation MGSNetServerHandler (NetServiceDelegate)

//
// server delegate messages
//

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
	#pragma unused(sender)
	
	MLog(DEBUGLOG, @"failed to publish = %@", [NSNetService errorDictString:errorDict]);
}

- (void)netServiceDidPublish:(NSNetService *)sender
{
	MLog(DEBUGLOG, @"did publish service name : %@ type: %@", [sender name], [sender type]);
	//[self updateTXTRecord];
}
@end

//
// private methods
//
@implementation MGSNetServerHandler (Private)

// publish service via Bonjour on portNumber
- (void)publishServerServiceOnPort:(UInt16)portNumber
{
	
	if (!_netServer) {
		MLog(DEBUGLOG, @"must startServerOnPort before publishing");
		return;
	}
	
	NSNetService *netService = [[NSNetService alloc] initWithDomain:self.domain type:self.serviceType name:self.serviceName port:portNumber];
	_netServer.netService = netService;
	[netService setDelegate:self];	
	[self updateTXTRecord];
	[netService publish];
}

@end


