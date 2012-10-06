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
#import <arpa/inet.h>
#import "MGSBonjour.h"
#import "MGSPreferences.h"
#import "MGSLM.h"
#import "NSNetService+Mugginsoft.h"

#define LMTestInterval 1 * 60

static MGSNetServerHandler *_sharedController = nil;

// class extension
@interface MGSNetServerHandler()
- (void)serverDo:(NSTimer*)theTimer;
- (void)listenForServers;
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
		_domain = MGSBonjourDomain;
		_serviceType = MGSBonjourServiceType;
		
		// note that the service name must be different for each server
		// on the network otherwise an NSNetServicesCollisionError will occur
		// see http://developer.apple.com/qa/qa2001/qa1228.html
		// for notes on service naming
		_serviceName = [MGSBonjour serviceName];
		_netServer = [[MGSNetServer alloc] init];
		_LMTimer = nil;
        _resolvedNetServices = [NSMutableArray  arrayWithCapacity:10];
        _IPv4BonjourAddresses = [NSMutableSet setWithCapacity:10];
        _IPv6BonjourAddresses = [NSMutableSet setWithCapacity:10];
        _localNetworkAddresses = [NSMutableSet setWithCapacity:10];
        _bannedAddresses = [NSMutableSet setWithCapacity:10];
        
        // we should be able to load banned addresses up from a plist or preferences
#ifdef MUGGINSOFT_DEBUG
        //[_bannedAddresses addObject:@"192.168.10.50"];  // block this IP for connection block testing
#endif
        _netServer.localNetworkAddresses = _localNetworkAddresses;
        _netServer.bannedAddresses = _bannedAddresses;
        _addressesForHostName = [NSMutableDictionary dictionaryWithCapacity:10];
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
	
    [self listenForServers];
    
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

#pragma mark -
#pragma mark Bonjour listener

/*
 
 - listenForServers
 
 */
- (void)listenForServers
{
    /*
     
     rationale:
     
     we want to kknow if a request comes from the local domain or beyond.
     subnet filtering is an option but there are problems with IPv6 (as used by Bonjour)
     as the host prefixes may not agree , esp if DHCP6 or an IPv^ router is not used ie:
     on my local LAN the IPv6 addresses all have different 64 bit host prefixes.
     
     so we just tray and track the Bonjour connection status instead.
     
     */
    _serviceBrowser = [[NSNetServiceBrowser alloc] init];
	[_serviceBrowser setDelegate:self];
	[_serviceBrowser searchForServicesOfType:_serviceType inDomain:_domain];
}

/*
 
 - netServiceBrowserWillSearch:
 
 */
- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)netServiceBrowser
{
	MLog(DEBUGLOG, @"Service search starting: %@", netServiceBrowser);
}
/*
 
 - netServiceBrowser:didFindService:moreComing:
 
 */
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser
		   didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing
{
#pragma unused(netServiceBrowser)
#pragma unused(moreServicesComing)
	
    // resolve the address.
    // normally we do this prior to accessing the service but in this
    // case we need to know the IP in advance for request filtering purposes.
    [netService setDelegate:self];
    [netService resolveWithTimeout:5];
    
	MLog(DEBUGLOG, @"Service found: %@", netService);
}
/*
 
 - netServiceBrowser:moreComing:didNotSearch:
 
 */
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didNotSearch:(NSDictionary *)errorInfo
{
#pragma unused(netServiceBrowser)
	
	MLog(DEBUGLOG, @"Service did not search: %@", errorInfo);
	
	_serviceBrowser  = nil;
}

/*
 
 - netServiceBrowserDidStopSearch:
 
 */
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)netServiceBrowser
{
	MLog(DEBUGLOG, @"Service search stopped: %@", netServiceBrowser);
}

/*
 
 - netServiceBrowser:didRemoveService:moreComing:
 
 */
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser
		 didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing
{
#pragma unused(netServiceBrowser)
#pragma unused(moreServicesComing)
	
    NSNetService *resolvedNetService = nil;
    
    // the netService seems not to define its addresses at this stage.
    // hostName is also valid so we need to retain the addresses keyed by the description.
    // also the netService instance here is a different object to the resolved one we have
    // retained. but -isEqual can be used on the NSNetService instances
    NSSet *addresses = [netService mgs_addressStrings];
    if ([addresses count] == 0) {
        
        NSUInteger index = [_resolvedNetServices indexOfObject:netService]; // use isEqual: to find match
        if (index != NSNotFound) {
            resolvedNetService = [_resolvedNetServices objectAtIndex:index];

            NSSet *keyedAddresses = [_addressesForHostName objectForKey:[NSValue valueWithPointer: resolvedNetService]];
            if (keyedAddresses) {
                addresses = keyedAddresses;
            }
        }
    }

    if (addresses) {
        [_IPv4BonjourAddresses minusSet:addresses];
        [_IPv6BonjourAddresses minusSet:addresses];
        [_localNetworkAddresses minusSet:addresses];
    }
    
	MLog(DEBUGLOG, @"Removing service: %@", netService);
    MLogDebug(@"Remove: IPv4 Bonjour addresses:%@", _IPv4BonjourAddresses);
    MLogDebug(@"Remove: IPv6 Bonjour addresses:%@", _IPv6BonjourAddresses);
    MLogDebug(@"Remove: Local network addresses:%@", _localNetworkAddresses);
    
    if (resolvedNetService) {
        [_addressesForHostName removeObjectForKey:[NSValue valueWithPointer: resolvedNetService]];
        [_resolvedNetServices removeObject:resolvedNetService];
    }

}

#pragma mark -
#pragma mark NSNetServiceDelegate protocol

/*
 
 - netServiceDidResolveAddress:
 
 */
- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    MLog(DEBUGLOG, @"Service address resolved: %@", sender);

    // get IPv4 addresses
    NSSet *IPv4Addresses = [sender mgs_IPv4AddressStrings];
    [_IPv4BonjourAddresses unionSet:IPv4Addresses];
    [_localNetworkAddresses unionSet:IPv4Addresses];
    
    // get IPv6 addresses
    NSSet *IPv6Addresses = [sender mgs_IPv6AddressStrings];
    [_IPv6BonjourAddresses unionSet:IPv6Addresses];
    [_localNetworkAddresses unionSet:IPv6Addresses];

    // key all addresses by service pointer as non copyable.
    // should be okay as we have retained a ref to the sender
    // http://stackoverflow.com/questions/3509118/using-non-copyable-object-as-key-for-nsmutabledictionary
    [_addressesForHostName setObject:[sender mgs_addressStrings] forKey:[NSValue valueWithPointer:sender]];
    [_resolvedNetServices addObject:sender];
    
    MLogDebug(@"Resolve: IPv4 Bonjour addresses:%@", _IPv4BonjourAddresses);
    MLogDebug(@"Resolve: IPv6 Bonjour addresses:%@", _IPv6BonjourAddresses);
    MLogDebug(@"Resolve: Local network addresses:%@", _localNetworkAddresses);
}
/*
 
 - netService:didNotResolve:
 
 */
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    #pragma unused(errorDict)
    #pragma unused(sender)
    
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


