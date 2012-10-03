//
//  MGSNetClientManager.m
//  Mother
//
//  Created by Jonathan on 04/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSNetClientManager.h"
#import "MGSNetClient.h"
#import "MGSClientRequestManager.h"
#import "MGSBonjour.h"
#import "MGSBrowserViewController.h"
#import "MGSClientTaskController.h"
#import "MGSSaveConfigurationWindowController.h"
#import "MGSAppController.h"
#import "MGSNotifications.h"
#import "MGSPreferences.h"
#import "MGSLM.h"

NSString *MGSDefaultPersistentConnections = @"MGSPersistentConnections";
NSString *MGSDefaultExcludedMothers = @"MGSExcludedConnections";
NSString *MGSDefaultHeartBeatInterval = @"MGSHeartBeatInterval";
NSString *MGSDefaultStartDelay = @"MGSDefaultStartDelay";

// note that representing the class as a true singleton is perhaps poor design.
// the class defines a delegate which doesn't sit well with singleton design.
static MGSNetClientManager *_sharedController = nil;

// class extension
@interface MGSNetClientManager()
@property (readwrite) MGSNetClient *selectedNetClient;

- (void)sendHeartbeats:(NSTimer*)theTimer;
- (void)mgsAddClient:(MGSNetClient *)netClient;
- (void)mgsRemoveClient:(MGSNetClient *)netClient;
- (void)statusChanged:(NSNotification *)aNote;
- (void)netClientSelected:(NSNotification *)aNote;
@end

@interface MGSNetClientManager (Private)
- (BOOL)isAvailableClient:(MGSNetClient *)netClient;
- (BOOL)validateSearchParameters; 
- (NSString *) validateParameterString: (NSString *)aString;
- (void)invalidateSearch;
- (MGSNetClient *)findNetServiceOwner:(NSNetService *)netService;
- (BOOL) permitClientConnectionWithName:(NSString *)name;
- (void)connectToDeferredNetClient;
- (void)connectToNetClient:(MGSNetClient *)netClient;
@end

@implementation MGSNetClientManager

@synthesize serviceType = _serviceType;
@synthesize domain = _domain;
@synthesize delegate = _delegate;
@synthesize deferRemoteClientConnections = _deferRemoteClientConnections;
@synthesize selectedNetClient = _selectedNetClient;

#pragma mark -
#pragma mark Class Methods

/*
 
 shared controller singleton
 
 */
+ (id)sharedController
{
	@synchronized(self) {
		if (!_sharedController) {
			[[self alloc] init];	// assignment occurs below
		}
	}
	return _sharedController;
}

/*
 
 alloc with zone for singleton
 
 */
+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (_sharedController == nil) {
            _sharedController = [super allocWithZone:zone];
            return _sharedController;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
} 


#pragma mark -
#pragma mark Instance Methods

/*
 
 copy with zone for singleton
 
 */
- (id)copyWithZone:(NSZone *)zone
{
	#pragma unused(zone)
	
    return self;
}

/*
 
 init
 
 */
- (MGSNetClientManager *)init
{
	if ((self = [super init])) {
		_domain = MGSBonjourDomain;
		_serviceType = MGSBonjourServiceType;
		_deferRemoteClientConnections = YES;	
		// start heartbeat timer
		NSTimeInterval heartBeatInterval = [[NSUserDefaults standardUserDefaults] doubleForKey:MGSDefaultHeartBeatInterval];
		if (heartBeatInterval > 10) {	// sanity check heartbeat interval
			_heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:heartBeatInterval target:self selector:@selector(sendHeartbeats:) userInfo:nil repeats:YES];
		}
		
		[self invalidateSearch];
		
		// register notification observers
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusChanged:) name:MGSNoteLicenceStatusChanged object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(netClientSelected:) name:MGSNoteClientSelected object:nil];
	}
	return self;
}
/*
 
 check for unsaved configuration on net client.
 
 if net client is nil then all clients are checked
 
 */
- (NSApplicationTerminateReply)checkForUnsavedConfigurationOnClient:(MGSNetClient *)netClient terminating:(BOOL)terminating
{
	NSMutableArray *netClients = nil;
	
	//===============================================
	// check for unsaved configuration on net client
	//===============================================
	_saveNetClient = netClient;
	if (netClient) {
		netClients = [NSMutableArray arrayWithObject:netClient];
	} else {
		netClients = _netClients;
	}
	
	unsigned needsSaving = 0;
	
	// Determine if there are any clients with unsaved configurations ...
	for (MGSNetClient *client in netClients) {
		if ([client.taskController isConfigurationEdited]) {
			needsSaving++;
		}
	}
	
	// if terminating then terminate when review complete
	_terminateAfterReviewChanges = terminating;
	
	if (needsSaving > 0) {
		
		// review save
		[self reviewSaveConfigurationAndQuitEnumeration:[NSNumber numberWithBool:YES]];
		
		return NSTerminateCancel;
	}
	
	// terminate approved
	return NSTerminateNow;
}
/*
 
 review save and quit enumeration
 
 */
- (void)reviewSaveConfigurationAndQuitEnumeration:(NSNumber *)contNumber 
{
	BOOL cont = [contNumber boolValue];
	
    if (cont) {
		NSMutableArray *netClients = nil;
		
		//===============================================
		// check for unsaved configuration on net client
		//===============================================
		if (_saveNetClient) {
			netClients = [NSMutableArray arrayWithObject:_saveNetClient];
		} else {
			netClients = _netClients;
		}
		
		// Determine if there are any clients with unsaved configurations ...
		for (MGSNetClient *client in netClients) {
			if ([client.taskController isConfigurationEdited]) {
				[self saveClientConfiguration:client doCallBack:YES];
				return;
			}
		}
		

		// we have finished saving configuration so check for unsaved documents
		NSApplicationTerminateReply terminateReply = [[NSApp delegate] checkForUnsavedDocumentsOnClient:_saveNetClient terminating:_terminateAfterReviewChanges];

		// if termination is approved then there are no more unsaved dociments
		if (terminateReply == NSTerminateNow) {
			
			// if terminate desired then do it
			if (_terminateAfterReviewChanges) {
				[NSApp terminate:self];
			} else {
				
				// otherwise post notification that save succeeded
				[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteClientSaveSucceeded object:self userInfo:nil];
			}
		}
    } else {
		//[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteClientSaveCancelled object:self userInfo:nil];
	}
	
}

/*
 
 save net client configuration changes.
 
 */
- (NSApplicationTerminateReply)saveClientConfiguration:(MGSNetClient *)netClient doCallBack:(BOOL)doCallBack
{
	
	// create config save sheet controller for net client
	MGSSaveConfigurationWindowController *saveConfigurationController = [(MGSSaveConfigurationWindowController *)[MGSSaveConfigurationWindowController alloc] initWithNetClient:netClient];
	[saveConfigurationController window];	// load it
	saveConfigurationController.doCallBack = doCallBack;
	
	// modal sheet for application window
	saveConfigurationController.modalForWindow = [[NSApp delegate] applicationWindow];
	
	// show the save configuration sheet
	if (![saveConfigurationController showSaveSheet]) {
		
		// no configuration save was required
		return NSTerminateNow;
	}
	
	// the save configuration sheet is displayed
	return NSTerminateCancel;
}


/*
 
 set delegate
 
 this is a singleton class so defining a delegate for it is not the best design.
 to stop the delegate being swapped out ensure that it can only be set once.
 a notifcation mechanism would have been better.
 
 */
- (void)setDelegate:(id <MGSNetClientManagerDelegate, NSObject> )object
{
	NSAssert(!_delegate, @"singleton delegate has already been set");
	_delegate = object;
}
/*
 
 send heartbeat request to all clients
 
 */
- (void)sendHeartbeats:(NSTimer*)theTimer
{	
	#pragma unused(theTimer)
	
	[_netClients makeObjectsPerformSelector:@selector(sendHeartbeat)];
}
/*
 
 request search all clients
 
 */
- (void)requestSearchAll:(NSDictionary *)searchDict withOwner:(id <MGSNetRequestOwner>)owner
{
	for (MGSNetClient *netClient in _netClients) {
		[netClient requestSearch:searchDict withOwner:owner];
	}
}
/*
 
 request search all but local client
 
 */
- (void)requestSearchShared:(NSDictionary *)searchDict withOwner:(id <MGSNetRequestOwner>)owner
{
	for (MGSNetClient *netClient in _netClients) {
		if (![netClient isLocalHost]) {
			[netClient requestSearch:searchDict withOwner:owner];
		}
	}
}
/*
 
 request search local client
 
 */
- (void)requestSearchLocal:(NSDictionary *)searchDict withOwner:(id <MGSNetRequestOwner>)owner
{
	[[self localClient] requestSearch:searchDict withOwner:owner];
}
/*
 
 request search client with service name
 
 */
- (BOOL)requestSearch:(NSDictionary *)searchDict clientServiceName:(NSString *)serviceName withOwner:(id <MGSNetRequestOwner>)owner
{
	MGSNetClient *client = [self clientForServiceName:serviceName];
	if (!client) {
		MLog(RELEASELOG, @"could not find client for search:", serviceName);
		return NO;
	}
	
	[client requestSearch:searchDict withOwner:owner];
	
	return YES;
}


/*
 
 start search for services
 
 */
- (BOOL)searchForServices
{
	if (_serviceBrowser) {
		return YES;
	}
	
	_serviceBrowser = [[NSNetServiceBrowser alloc] init];
	_netClients = [NSMutableArray array];
	_deferredNetClients = [NSMutableArray array];
	[_serviceBrowser setDelegate:self];
	[_serviceBrowser searchForServicesOfType:_serviceType inDomain:_domain];
	
	return YES;
}


// number of attached clients
- (NSInteger)clientsCount
{
	if (_netClients)	{
		return [_netClients count];
	} else {
		return 0;
	}
}

   
// number of hidden clients
- (NSInteger)clientsHiddenCount
{
	NSInteger count = 0;
	for (MGSNetClient *netClient in _netClients) {
		count += (netClient.visible ? 0 : 1);
	}
	return count;
}

- (NSInteger)clientsVisibleCount
{
	return ([self clientsCount] - [self clientsHiddenCount]);
}

// get client at index
- (MGSNetClient *)clientAtIndex:(NSUInteger)idx
{
	if (idx < [_netClients count]) {
		return [_netClients objectAtIndex:idx];
	} else {
		return nil;
	}
}

// get index of client
- (NSUInteger)indexOfClient:(MGSNetClient *)client
{
	return [_netClients indexOfObjectIdenticalTo:client];
}

/*
 
 - informDelegateClientListChanged
 
 */
 
- (void)informDelegateClientListChanged
{
	// message the delegate
	if (_delegate && [_delegate respondsToSelector:@selector(netClientHandlerClientListChanged:)]) {
		[_delegate netClientHandlerClientListChanged:self];
	}
}

// sort the array
- (void)sortUsingDescriptors:(NSArray *)descriptors
{
	[_netClients sortUsingDescriptors:descriptors];
}

// return the local client
- (MGSNetClient *)localClient
{
	return [self clientForServiceName: [MGSBonjour serviceName]];
}

/*
 
 add a static client
 
 a static client is one that is not discovered via mDNS
 
 */
- (void)addStaticClient:(MGSNetClient *)netClient
{
	NSAssert(netClient, @"net client is nil");

	// check if this client is already available.
	// this avoids repeat connections to the same client
	if ([self isAvailableClient:netClient]) {
		return;
	}
	
	// we can only add a static client if it is not connected.
	if (![netClient isConnected]) {
		
		// become the delegate.
		// this is a temporary delegation until we become connected
		netClient.delegate = self;
		
		// send out a heartbeat request.
		// if we get a netClientResponding: response then we have connected.
		[netClient sendHeartbeatNow];
		
		return;
	}
	
	// add static client
	[self mgsAddClient:netClient];

	// set delegate
	netClient.delegate = _delegate;
	
	[self informDelegateClientListChanged];
	
	[_delegate netClientHandlerClientFound:netClient];

}

/*
 
 - netClientResponding:
 
 */
- (void)netClientResponding:(MGSNetClient *)netClient
{
	// we only receive this delegate message while a manual connection
	// is trying to extablish a connection by sending out heartbeats
	
	// check if a manual connection
	if (![netClient hostViaBonjour]) {
		[self addStaticClient:netClient];
	} else {
		NSAssert(NO, @"unexpected response from net client");
	}
}

/*
 
 - netClientNotResponding:
 
 */
- (void)netClientNotResponding:(MGSNetClient *)netClient
{
	// we only receive this delegate message while a manual connection
	// is trying to extablish a connection by sending out heartbeats

	// we sent a heartbeat to a remote manual host but received no reply
	
	// check if a manual connection
	if (![netClient hostViaBonjour]) {
		
		// routine heartbeats are only sent by default to already connected clients.
		// hence schedule our own here.
		[self performSelector:@selector(addStaticClient:) withObject:netClient afterDelay:60.0];

	} else {
		NSAssert(NO, @"unexpected response from net client");
	}
}

/*
 
 add client to array
 
 probably could have used an array controller instance and observed changes
 
 */
- (void)mgsAddClient:(MGSNetClient *)netClient
{
	// add client to array
	[_netClients addObject:netClient];
	
	// validate that we have not exceeded our connection limit
	BOOL connectionValidated = YES;
	if ([_netClients count] > [[MGSLM sharedController] seatCount]) {
		connectionValidated = NO;
	} 
	netClient.validatedConnection = connectionValidated;
}

/*
 
 mgs remove client from array
 
 */
- (void)mgsRemoveClient:(MGSNetClient *)netClient
{
	
	// remove client from array
	[_netClients removeObject:netClient];

	// revalidate clients
	[self validateClients];
}

/*
 
 validate clients
 
 */
- (void)validateClients
{
	NSUInteger seatCount = [[MGSLM sharedController] seatCount];
	
	for (NSUInteger idx = 0; idx < [_netClients count]; idx++) {
		MGSNetClient *netClientItem = [_netClients objectAtIndex:idx];
		netClientItem.validatedConnection = idx < seatCount ? YES : NO;
		
		//
		// flag to send execute validation
		//
		netClientItem.sendExecuteValidation = YES;
	}
	
}
/*
 
remove a static client
 
 */
- (void)removeStaticClient:(MGSNetClient *)netClient
{
	// only use this message to remove static clients
	if (netClient.hostViaBonjour) {
		return;
	}
	
	// remove the client
	[self mgsRemoveClient:netClient];
	
	[netClient serviceRemoved];

	[self informDelegateClientListChanged];

	// message delegate
	if (_delegate && [_delegate respondsToSelector:@selector(netClientHandlerClientRemoved:)]) {
		[_delegate netClientHandlerClientRemoved:netClient];
	}
}

/*
 
 - hostViaUserDictionaries
 
 */
- (NSMutableArray *)hostViaUserDictionaries
{
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:2];
	
	for (MGSNetClient *netClient in _netClients) {
		if (NO == netClient.hostViaBonjour) {
			[array addObject:[netClient dictionary]];
		}
	}
	return array;
}

/*
 
 restore persistent clients
 
 */
- (void)restorePersistentClients
{
	// retrieve persistent client array from defaults
	NSArray *persistentClients = [[NSUserDefaults standardUserDefaults] objectForKey:MGSDefaultPersistentConnections];
	if (nil == persistentClients) return;
	
	// iterate and reconnect clients
	for (NSDictionary *dict in persistentClients) {
		if (NO == [dict isKindOfClass:[NSDictionary class]]) continue;
		
		// create client from dictionary client 
		MGSNetClient *netClient = [[MGSNetClient alloc] initWithDictionary:dict];
		if (!netClient) {
			continue;
		}
		
		// try and add the client
		[self addStaticClient:netClient];
	}
	
}

/*
 
 - clientForServiceName:
 
 */
- (MGSNetClient *)clientForServiceName:(NSString *)serviceName
{
	// look for client name match
	MGSNetClient *netClient;
	for (netClient in _netClients) {
		if ([[netClient serviceName] isEqualToString:serviceName]) {
			return netClient;
		}
	}
	
	return nil;
}

#pragma mark -
#pragma mark Notification callbacks

/*
 
 licence status has changed
 
 */
- (void)statusChanged:(NSNotification *)aNote
{
	#pragma unused(aNote)
	
	// validate clients when licence status changed
	[self validateClients];
}

/*
 
 net client selected
 
 */
- (void)netClientSelected:(NSNotification *)aNote
{
	NSDictionary *userInfo = [aNote userInfo];
	MGSNetClient *netClient  = [userInfo objectForKey:MGSNoteNetClientKey];
	NSAssert(netClient, @"net client is nil");
	self.selectedNetClient = netClient;	
}
@end


//
// NSNetServiceBrowser delegate methods
//
@implementation MGSNetClientManager (NetServiceBrowserDelegate)

// browser search starting
- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)netServiceBrowser
{
	MLog(DEBUGLOG, @"Service search starting: %@", netServiceBrowser);
}

// matching service found
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser 
		   didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing
{
	#pragma unused(netServiceBrowser)
	#pragma unused(moreServicesComing)
	
	MLog(DEBUGLOG, @"Service found: %@", netService);
	
	// determine if the connection of this service is permitted.
	// [netService name] will be qualified: ie somemother.local
	if (NO == [self permitClientConnectionWithName:[netService name]]) {
		MLog(DEBUGLOG, @"This KosmicTask server has been excluded: %@", [netService name]);
		return;
	}
	
	// see if a client already exists for the service
	MGSNetClient *netClient = [self clientForServiceName:[netService name]];
	if (netClient) {
		
		// if managed to resolve the service then flag it as available.
		[netClient setHostStatus:MGSHostStatusAvailable];
		MLog(DEBUGLOG, @"client already exists for service");
		return;
	}

	// create net client for service
	netClient = [[MGSNetClient alloc] initWithNetService:netService];

	// defer connections?
	BOOL deferConnections = [[NSUserDefaults standardUserDefaults] boolForKey:MGSDeferRemoteClientConnections];
	
	if (!deferConnections) {
		
		[self mgsAddClient:netClient];		
		[self connectToNetClient:netClient];
		
	} else {
			
		// if local host not yet found then cache the clients to speed launch time
		// and help ensure that we connect to the local host first
		if ([netClient isLocalHost] || !_deferRemoteClientConnections) {
			
			[self mgsAddClient:netClient];
			
			// delay connection to remote clients. this is to allow the remote host
			// to service local startups first.
			NSTimeInterval delay = [netClient isLocalHost] ? 0.0 : [[NSUserDefaults standardUserDefaults] doubleForKey:MGSRemoteClientConnectionDelay];
			
			[self performSelector:@selector(connectToNetClient:) withObject:netClient afterDelay:delay];
			
		} else {
			[_deferredNetClients addObject:netClient];
			
			// allow connect to deferred net clients after delay even if local host not found.
			// this should preserve network connections even if the local host goes down.
			[self performSelector:@selector(undeferRemoteClientConnections) 
				withObject:nil 
				afterDelay:[[NSUserDefaults standardUserDefaults] doubleForKey:MGSDeferredClientConnectionTimeout]];
		}
		
	}
}

/*
 
 undefer remote client connections
 
 */
- (void)undeferRemoteClientConnections
{
	self.deferRemoteClientConnections = NO;
}

/*
 
 defer remote client connections
 
 */
- (void)setDeferRemoteClientConnections:(BOOL)aBool
{
	_deferRemoteClientConnections = aBool;
	
	// if no longer deferring then connect to deferred client
	if (!_deferRemoteClientConnections) {
		[self performSelector:@selector(connectToDeferredNetClient) withObject:nil afterDelay:.5];
	}
}


// did not search
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didNotSearch:(NSDictionary *)errorInfo
{
	#pragma unused(netServiceBrowser)
	
	MLog(DEBUGLOG, @"Service did not search: %@", errorInfo);
	
	[self invalidateSearch];
}

// search stopped
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)netServiceBrowser
{
	MLog(DEBUGLOG, @"Service search stopped: %@", netServiceBrowser);
}

// service removed
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser 
		 didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing
{
	#pragma unused(netServiceBrowser)
	#pragma unused(moreServicesComing)
	
	MLog(DEBUGLOG, @"Removing service: %@", netService);
	
	MGSNetClient *removedClient = nil;
	
	// get the client for the service
	for (MGSNetClient *netClient in _netClients) {
		if ([netClient hasService: netService]) {
			removedClient = netClient;
			[self mgsRemoveClient:removedClient];
			break;
		}
	}

	// if service client not found then exit.
	// it may have been on our excluded list.
	if (!removedClient) {
		return;
	}
	
	// tell client its service has been removed
	[removedClient serviceRemoved];
	
	[self informDelegateClientListChanged];
	
	// message delegate
	if (_delegate && [_delegate respondsToSelector:@selector(netClientHandlerClientRemoved:)]) {
		[_delegate netClientHandlerClientRemoved:removedClient];
	}
}

@end

//
// private methods
//
@implementation MGSNetClientManager (Private)

/*
 
 - isAvailableClient:
 
 */
- (BOOL)isAvailableClient:(MGSNetClient *)aClient
{
	
	for (MGSNetClient *netClient in _netClients) {
		if ([[netClient serviceShortName] caseInsensitiveCompare:[aClient serviceShortName]] == NSOrderedSame) {
			return YES;
		}
	}

	
	return NO;
}

/*
 
 connect to deferred net clients
 
 */
- (void)connectToDeferredNetClient
{
	if (!_deferredNetClients || [_deferredNetClients count] == 0) return;
	
	MGSNetClient *netClient = [_deferredNetClients objectAtIndex:0];
	[_deferredNetClients removeObject:netClient];
	[self mgsAddClient:netClient];
	[self connectToNetClient:netClient];
	
	if ([_deferredNetClients count] > 0) {
		[self performSelector:_cmd withObject:nil afterDelay:0.2];
	}
}

/*
 
 connect to net client
 
 */
- (void)connectToNetClient:(MGSNetClient *)netClient
{
	// the net service for this client may have shutdown
	if (!netClient.netService) {
		return;
	}
	
	netClient.delegate = _delegate;
	
	[self informDelegateClientListChanged];
	
	// message delegate
	if (_delegate && [_delegate respondsToSelector:@selector(netClientHandlerClientFound:)]) {
		[_delegate netClientHandlerClientFound:netClient];
	}	
}

// determines if client will be allowed to connect
- (BOOL)permitClientConnectionWithName:(NSString *)clientName
{
	// get our excluded mother list
	NSArray *excludedMothers = [[NSUserDefaults standardUserDefaults] objectForKey:MGSDefaultExcludedMothers];
	if (nil == excludedMothers) {
		return YES;
	}
	
	for (NSDictionary *dict in excludedMothers) {
		if (NO == [dict isKindOfClass:[NSDictionary class]]) continue;
		NSString *address = [dict objectForKey: MGSNetClientKeyAddress];
		if (!address) continue;
		
		// note that the client name maybe be qualified ie: somemother.local
		if ([address isEqualToString:clientName]) {
			return NO;
		}
	}

	return YES;
}

- (BOOL)validateSearchParameters
{
	//self.domain = [self validateParameterString:_domain];
	_serviceType = [self validateParameterString:_serviceType];	
	if (!self.domain || !self.serviceType) {
		return NO;
	}
	
	return YES;
}

- (NSString *) validateParameterString: (NSString *)aString
{	
	if (!aString) return nil;
	NSString *trimmedString = [aString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (trimmedString == @"") return nil;
	
	return trimmedString;
}

- (void)invalidateSearch
{
	_serviceBrowser = nil;
	_netClients = nil;
}

/*
// handle the netservice address resolved
- (void)handleServiceAddressResolved: (NSNetService *)netService
{
	MGSNetClient *netClient = [self findNetServiceOwner:netService];

	NSArray *addresses = [netService addresses];
	if (!addresses || [addresses count] == 0) {
		[self handleServiceAddressNotResolved:netService];
		return;
	}
	
	// host is now available
	netClient.hostStatus = MGSHostStatusAvailable;	
	
	// message the delegate
	if (_delegate && [_delegate respondsToSelector:@selector(netClientHandlerDidResolve:)]) {
		[_delegate netClientHandlerDidResolve:netClient];
	}
	
	// update the tableview
	[self informDelegateClientDataUpdated];
}
*/
// handle the netservice address not resolved
/*- (void)handleServiceAddressNotResolved:(NSNetService *)netService
{
	MGSNetClient *netClient = [self findNetServiceOwner:netService];
	
	netClient.hostStatus = MGSHostStatusAddressNotResolved;
	
	// message delegate
	if (_delegate && [_delegate respondsToSelector:@selector(netClientHandlerDidNotResolve:)]) {
		[_delegate netClientHandlerDidNotResolve:netClient];
	}
}
*/
// find the MGSNetService object that owns the NSNetService
- (MGSNetClient *)findNetServiceOwner:(NSNetService *)netService
{
	for (MGSNetClient *netClient in _netClients) {
		// if (netClient.netService == netService) {
		// this is a better test
		// see notes on removing service test
		if ([netClient.netService isEqual:netService]) {
			return netClient;
		}
	}
	MLog(DEBUGLOG, @"cannot find owner for net service: %@", netService);
	return nil;
}

@end



