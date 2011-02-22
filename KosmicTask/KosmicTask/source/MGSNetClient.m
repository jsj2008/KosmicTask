//
//  MGSNetClient.m
//  Mother
//
//  Created by Jonathan on 28/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSAppController.h"
#import "MGSNetClient.h"
#import "MGSNetClientContext.h"
#import "MGSClientRequestManager.h"
#import "MGSClientTaskController.h"
#import "MGSPath.h"
#import "MGSImageManager.h"
#import "MGSMotherModes.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import "NSNetService_errors.h"
#import "MGSNetRequestPayload.h"
#import "MGSNetMessage.h"
#import "MGSBonjour.h"
#import "MGSAuthentication.h"
#import "MGSKeyChain.h"
#import "MGSSystem.h"
#import "MGSScript.h"
#import "MGSPreferences.h"
#import "MGSOutlineViewNode.h"
#import "MGSNetRequest+KosmicTask.h"

const char MGSNetClientRunModeContext;

// defaults
NSString *MGSDefaultBadHeartbeatLimit = @"MGSBadHeartbeatLimit";

// dictionary keys
NSString *MGSNetClientKeyAddress =@"address";
NSString *MGSNetClientKeyDisplayName = @"displayName";
NSString *MGSNetClientKeyKeepConnected = @"keepConnected";
NSString *MGSNetClientKeyPortNumber = @"portNumber";
NSString *MGSNetClientKeySecureConnection = @"secureConnection";

// key paths
NSString *MGSNetClientKeyPathHostStatus = @"hostStatus";
NSString *MGSNetClientKeyPathRunMode = @"applicationWindowContext.runMode";
NSString *MGSNetClientKeyPathScriptAccess = @"taskController.scriptAccess";

// class extension
@interface MGSNetClient()
- (void)queueOperation:(NSOperation *)theOp;
- (void)setNetService:(NSNetService *)aNetService;
- (void)assignHostImage;
- (void)getHostPort;
- (void)heartbeatReplyReceivedForNetClient: (MGSNetClient *)netClient;
- (void)heartbeatReplyNotReceivedForNetClient: (MGSNetClient *)netClient;
- (void)sendRequestQueue;
- (void)deleteSessionPassword;
@end

//
// each instance of MGSNetClient communicates with an
// instance of MGSNetServer
//
@implementation MGSNetClient

@synthesize netService = _netService;
@synthesize visible = _visible;
@synthesize serviceShortName = _serviceShortName;
@synthesize hostType = _hostType;
@synthesize serviceName = _serviceName;
@synthesize hostImage = _hostImage;
@synthesize hostStatus = _hostStatus;
@synthesize hostIcon = _hostIcon;
@synthesize hostUserName = _hostUserName;
@synthesize delegate = _delegate;
@synthesize useSSL = _useSSL;
@synthesize authenticationDictionary = _authenticationDictionary;
@synthesize hostViaBonjour = _hostViaBonjour;
@synthesize keepConnected = _keepConnected;
@synthesize taskController =  _taskController;
@synthesize clientStatus = _clientStatus;
@synthesize TXTRecordReceived = _TXTRecordReceived;
@synthesize initialRequestRetryCount = _initialRequestRetryCount;
@synthesize validatedConnection = _validatedConnection;
@synthesize sendExecuteValidation = _sendExecuteValidation;
@synthesize securePublicTasks = _securePublicTasks;

/*
 
 + initialize
 
 */

+ (void)initialize
{
	// if superclassed and super class does not implement initialize then
	// initialize gets called twice!
	if ( self == [MGSNetClient class] ) {
		
		// register with the MGSOutlineViewNode
		[MGSOutlineViewNode registerClass:self
								  options:[NSDictionary dictionaryWithObjectsAndKeys:@"serviceShortName", @"name", nil]];
	}
}

#pragma mark Instance control
/*
 
 init
 
 */
- (id)init
{
	return [self initWithNetService:nil];
}

//=======================================================
//
// initialise with NSNetService instance
//
// designated initialiser
//
// used for clients detected via Bonjour
//=======================================================
- (id)initWithNetService:(NSNetService *)aNetService
{
	if ((self = [super init])) {
		_visible = true;
		
		_taskController = [(MGSClientTaskController *)[MGSClientTaskController alloc] initWithNetClient:self];
		
		_clientStatus = MGSClientStatusNotAvailable;
		_authenticationDictionary = nil;
		_serviceName = @"";
		_serviceShortName = @"";
		_hostType = MGSHostTypeUnknown;
		self.hostStatus = MGSHostStatusNotYetAvailable;
		_badHeartbeatCount = 0;
		
		// create request queue
		_pendingRequests = [NSMutableArray arrayWithCapacity:10];
		
		// create request threads array
		_executingRequests = [NSMutableArray arrayWithCapacity:10];
		
		// create contexts map table and add context for application window.
		// window keys are weak so they don't stop windows from being deallocated
		_contexts = [NSMapTable mapTableWithWeakToStrongObjects];	
		[self addContextForWindow:[[NSApp delegate] applicationWindow]];
		
		_isResolving = NO;
		_useSSL = NO;
		_bonjourResolveTimeout = 5.0;
		[self setNetService:aNetService];
		_hostUserName = @"";
		_validatedConnection = YES; // default to validated
		_sendExecuteValidation = YES;
		
		// create net sockets array
		_hostViaBonjour = YES;
		_keepConnected = NO;
		_TXTRecordReceived = NO;
		_initialRequestRetryCount = 0;
		
		// register notification observers
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
	
		// add observer
		[self addObserver:self forKeyPath:MGSNetClientKeyPathRunMode options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:(void *)&MGSNetClientRunModeContext];

	}
	_hostPort = 0;
	_hostName = nil;
	return self;
}

//=======================================================
//
// initialise with parameters from dictionary
//
// used for manually added clients
//
//=======================================================
- (id)initWithDictionary:(NSDictionary *)dict
{
	if ([self initWithNetService:nil]) {
		
		// get client properties
		NSString *address =  [dict objectForKey:MGSNetClientKeyAddress];
		NSString *displayName =  [dict objectForKey:MGSNetClientKeyDisplayName];
		NSInteger portNumber = [[dict objectForKey:MGSNetClientKeyPortNumber] intValue];
		
		if (nil == address || portNumber < 0) {
			MLog(DEBUGLOG, @"invalid client dictionary");
			return nil;
		}
		
		self.keepConnected = [[dict objectForKey:MGSNetClientKeyKeepConnected] boolValue];
		self.useSSL = [[dict objectForKey:MGSNetClientKeySecureConnection] boolValue];
		
		_hostName = address;
		_hostPort = portNumber;
		
		// set service name
		_hostType = MGSHostTypeRemote;
		_hostViaBonjour = NO;	// manual host
		self.serviceName = address;
		if (!displayName || [displayName length] == 0) {
			displayName = address;
		}
		_serviceShortName = displayName;
		
		self.hostStatus = MGSHostStatusNotYetAvailable;	// this will update the host icon
		
	}
	
	return self;
}

/*
 
 set our delegate
 
 */
- (void)setDelegate:(id)object
{
	_delegate = object;
	
	// task controller shares delegate
	_taskController.delegate = _delegate;
}

/*
 
 dictionary used to archive and restore client
 
 */
- (NSDictionary *)dictionary
{
	NSString *address =  _hostName;
	NSString *displayName =  _serviceShortName;
	NSInteger portNumber = _hostPort;
	
	if (!address) address = @"????";
	if (!displayName) displayName = @"";
	
	return [NSDictionary dictionaryWithObjectsAndKeys:address, MGSNetClientKeyAddress,
			displayName, MGSNetClientKeyDisplayName,
			[NSNumber numberWithInt:portNumber], MGSNetClientKeyPortNumber,
			[NSNumber numberWithBool:_keepConnected], MGSNetClientKeyKeepConnected,
			[NSNumber numberWithBool:_useSSL], MGSNetClientKeySecureConnection,			
			nil];
}

#pragma mark Contexts
/*
 
 add context for window
 
 */
- (BOOL)addContextForWindow:(NSWindow *)window
{
	if (![self contextForWindow:window]) {
		MGSNetClientContext *context = [[MGSNetClientContext alloc] initWithWindow:window];
		[_contexts setObject:context forKey:window];
		return YES;
	} 
	return NO;
}
/*
 
 remove context for window
 
 */
- (void)removeContextForWindow:(NSWindow *)window
{
	[_contexts removeObjectForKey:window];
}
/*
 
 context for window
 
 */
- (MGSNetClientContext *)contextForWindow:(NSWindow *)window
{
	MGSNetClientContext *context = [_contexts objectForKey:window];
	
	return context;
}
/*
 
 context for application window
 
 */
- (MGSNetClientContext *)applicationWindowContext
{
	MGSNetClientContext *context = [_contexts objectForKey:[[NSApp delegate] applicationWindow]];
	NSAssert(context, @"net client application context is nil");
	return context;
}

#pragma mark Images
/*
 
 probably an icns resource
 
 */
- (void)setHostImage:(NSImage *)image
{
	_hostImage = image;
	
	[self setHostIcon:[[[MGSImageManager sharedManager] smallImageCopy:_hostImage] copy]];
}

/*
 
 a 16 x 16 image
 use this for cells etc that do not scale the hostImage well
 
 */
- (void)setHostIcon:(NSImage *)image
{
	_hostIcon = image;
}

/*
 
 icon for secured connection status
 
 */
- (NSImage *)securityIcon
{
	if (_useSSL) {
		return [[[MGSImageManager sharedManager] lockLockedTemplate] copy];
	} else {
		return [[[MGSImageManager sharedManager] lockUnlockedTemplate] copy];
	}
}

/*
 
 icon for authentication status
 
 */
- (NSImage *)authenticationIcon
{
	if (_authenticationDictionary) {
		if (self.applicationWindowContext.runMode == kMGSMotherRunModePublic) {
			return [[[MGSImageManager sharedManager] dotTemplate] copy];
		} else {
			return [[[MGSImageManager sharedManager] tick] copy];
		}
	}
	
	return nil;
}

#pragma mark -
#pragma mark KVO
/*
 
 observe value for key path
 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == &MGSNetClientRunModeContext) {
		[self applySecurity];
		
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark -
#pragma mark Security

/*
 
 - setSecurePublicTasks:
 
 */
- (void)setSecurePublicTasks:(BOOL)aBool
{
	_securePublicTasks = aBool;
	
	[self applySecurity];
}

/*
 
 - applySecurity
 
 */
- (void)applySecurity
{
	if ([self applicationWindowContext].runMode == kMGSMotherRunModePublic) {
		self.useSSL = self.securePublicTasks;
	} else {
		self.useSSL = YES;
	}
}
#pragma mark -
#pragma mark Notification methods
/*
 
 application will terminate
 
 */
- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	#pragma unused(aNotification)
	
	[self deleteSessionPassword];
}

#pragma mark Request, service and connection handling
/*
 
 search the client
 
 */
- (void)requestSearch:(NSDictionary *)searchDict withOwner:(id <MGSNetRequestOwner>)owner
{
	[[MGSClientRequestManager sharedController] requestSearchNetClient:self searchDict:searchDict withOwner:owner];
}

/*
 
 set service name
 
 */
- (void)setServiceName:(NSString *)value
{
	_serviceName = value;
	
	if (_serviceName != nil && ![_serviceName isEqualToString:@""]) {
		
		// when service name defined delete any residual session passwords
		[[MGSAuthentication sharedController] deleteKeychainSessionPasswordForService:_serviceName];
	}
}


/*
 
 net service removed
 
 */
- (void)serviceRemoved
{
	// if still resolving the host then stop
	if (_isResolving) {
		[self.netService stop];
		_isResolving = NO;
	}
	
	// deal with items in queue
	for (MGSNetRequest *netRequest in [_pendingRequests copy]) {
		
		// on error send reply to delegate
		NSString *failureReason = NSLocalizedString(@"Service removed for host: %@", @"Host service removed error");
		failureReason = [NSString stringWithFormat:failureReason, [_netService hostName]];
		[self errorOnRequestQueue:netRequest code:MGSErrorCodeSendRequestMessage reason:failureReason];
	}
	
	[self setNetService:nil];
	
	// even though this client has been removed
	// it may live on through references to it from
	// the history so flag status as disconnected
	self.hostStatus = MGSHostStatusDisconnected;
	
	[self deleteSessionPassword];
	self.authenticationDictionary = nil;
	
	[_taskController saveLocalScriptProperties];
}
/*
 
 does this instance have a reference to the service?
 
 */
- (BOOL)hasService:(NSNetService *)netService
{
	/*// when netservice arg is received on service removal the hostname is mil
	MLog(DEBUGLOG, @" query hostName:%@ - existing hostName:%@", [netService hostName], [_netService hostName]);
	MLog(DEBUGLOG, @" query type:%@ - existing type:%@", [netService type], [_netService type]);
	
	if ([[netService hostName] isEqualToString: [_netService hostName]] &&
		[[netService type] isEqualToString: [_netService type]]) {
		return YES;
	}
	*/
	// from apple's PictureSharingBrowser example code
	// a simple pointer comparison fails here - isEqual must be overriden
	if ([netService isEqual:_netService]) {
		return YES;
	} 
	
	return NO;
}

/*
 
 is connected
 
 */
- (BOOL)isConnected
{
	switch (_hostStatus) {
			
		case MGSHostStatusNotYetAvailable:
		case MGSHostStatusDisconnected:
			return NO;

		case MGSHostStatusAvailable:
		case MGSHostStatusNotResponding:
			return YES;
	}
	
	return NO;
}
/*
 
 can connect
 
 in order for a client to be able to connect reliably to a server
 discovered via Bonjour
 
 */
- (BOOL) canConnect
{
	if (_hostViaBonjour) {
		
		// client needs to have received a TXTrecord specifying the connection SSL usage state
		if (self.TXTRecordReceived) {
			return YES;
		} 
		
		return NO;
	} else {
		
		// manual connections can proceed
		return YES;
	}
}
/*
 
 connect and send request
 
 */
- (void)connectAndSendRequest:(MGSNetRequest *)netRequest
{	
	NSAssert(netRequest, @"net request is nil");
	NSAssert(netRequest.delegate, @"net request delegate is nil");
	
	// this method does not expect the request to have its negotiation
	// already queued
	if ([netRequest queuedNegotiateRequest]) {
		[self errorOnRequestQueue:netRequest code:MGSErrorCodeSendRequestMessage reason:@"Request negotiation already queued."];
	}
	
	// prepare connection negotiation
	if (![netRequest prepareConnectionNegotiation]) {
		[self errorOnRequestQueue:netRequest code:MGSErrorCodeSendRequestMessage reason:@"Prepare connection negotiation failure failure."];
		
		return;
	}
	
	// if we have a chain of requests get the next one to send
	netRequest = [netRequest nextQueuedRequestToSend];
		
	// check client connected
	if (![self isConnected]) {
		
		// get request command
		BOOL canSend = NO;
		NSString *command = [netRequest.requestMessage command];
		
		NSAssert(command, @"net request command is nil");
		
		// allow heartbeat to be sent
		if ([command caseInsensitiveCompare:MGSNetMessageCommandHeartbeat] == NSOrderedSame) {
			canSend = YES;
		}
		
		if (!canSend) {
			
			// on error send reply to delegate
			NSString *failureReason = NSLocalizedString(@"Connection to host not available: %@", @"Host connection error");
			failureReason = [NSString stringWithFormat:failureReason, _hostName];
			[self errorOnRequestQueue:netRequest code:MGSErrorCodeSendRequestMessage reason:failureReason];
			
			// should we send another heartbeat request?
			
			return;
		}
	}

	// If host not determined by Bonjour then there is no resolving to be done.
	// or
	// If prev request sent on same connection
	//
	// Send request directly.
	if (!_hostViaBonjour || netRequest.prevRequest) {
		
		// add request to queue
		[_pendingRequests addObject:netRequest];
		
		// send the queue.
		// this can occur immediately as we have no resolving to perform
		[self sendRequestQueue];
		
		return;
	}
	
	// the netservice may have disconnected in which case we will not be able to resolve
	// our address
	if (!_netService) {
		
		// on error send reply to delegate
		NSString *failureReason = NSLocalizedString(@"Host service no longer available: %@", @"Cannot find host error");
		failureReason = [NSString stringWithFormat:failureReason, _hostName];
		[self errorOnRequestQueue:netRequest code:MGSErrorCodeSendRequestMessage reason:failureReason];
		
		return;
	}

	// resolving request
	netRequest.status = kMGSStatusResolving;
	
	// queue our request
	[_pendingRequests addObject:netRequest];

	// if currently resolving then nothing more to do
	if (_isResolving) {
		MLog(DEBUGLOG, @"Client is resolving: request has been queued. Queue size is: %i", [_pendingRequests count]);
		return;
	}
			
	// resolve the address.
	// it is recommended that the service address is always
	// resolved rather than cached.
	// the host name and IP can change but as long as the
	// service name remains constant the host will be resolved
	_isResolving = YES;
	[_netService resolveWithTimeout:_bonjourResolveTimeout];
	
	return;
}

/*
 
 send a heartbeat request for self
 
 */
- (void)sendHeartbeat
{
	// send heartbeat request to available hosts and those who have been
	// recently available but are now flagged as not responding.
	// a host should only get into the MGSHostStatusNotResponding state is a network
	// comms error occurs of the host crashes.
	if (_hostStatus == MGSHostStatusAvailable || _hostStatus == MGSHostStatusNotResponding ||
		(NO == _hostViaBonjour)) {	// manual host not connected
		
		if (_hostType == MGSHostTypeRemote) {
			[self sendHeartbeatNow];
		}
	}
}

/*
 
 - sendHeartbeatNow
 
 */
- (void)sendHeartbeatNow
{
	[[MGSClientRequestManager sharedController] requestHeartbeatForNetClient:self withOwner:self];
}

/*
 
 set the run mode
 
 */
- (void)setRunMode:(eMGSMotherRunMode)mode forWindow:(NSWindow *)window
{	
	// currently not called!
	
	// if window nil get app window
	if (!window) {
		window = [[NSApp delegate] applicationWindow];
	}
	
	
	// get context
	MGSNetClientContext *context = [self contextForWindow:window];
	NSAssert(context, @"net client context nil for window");
	
	if (context.runMode == mode) {
		return;
	}
	context.runMode = mode;
	
	// pending run mode reset
	context.pendingRunMode = context.runMode;
	
	switch (context.runMode) {
			
			// run actions
		case kMGSMotherRunModePublic:
			[self deleteSessionPassword];
			
			break;
			
		case kMGSMotherRunModeAuthenticatedUser:;
		case kMGSMotherRunModeConfigure:;
			
			break;
			
			
		default:
			NSAssert(NO, @"invalid edit mode");
			break;
	}
}


/*
 
 - hostName
 
 */
- (NSString *)hostName
{
	return _hostName;
}

/*
 
 - hostPort
 
 */
- (UInt16) hostPort
{
	return _hostPort;
}
/*
 
 set the host connection status
 
 */
- (void)setHostStatus:(MGSHostStatus)hostStatus
{
	//MGSHostStatus prevHostStatus = _hostStatus;
	_hostStatus = hostStatus;
	BOOL assignImage = NO;
	
	switch (_hostStatus) {
			// host not yet connected or has become disconnected
		case MGSHostStatusNotYetAvailable:	
			assignImage = YES;
			
			// if not connected but have scripts then delete them
			if (YES == [_taskController hasScripts]) {
				[_taskController clearScripts];
				self.clientStatus = MGSClientStatusNotAvailable;
				
				// clear the authentication dictionary as we will want to re-autheticate if a
				// manual client reconnects
				self.authenticationDictionary = nil;
				if (_delegate && [_delegate respondsToSelector:@selector(netClientScriptDictUpdated:)]) {
					[_delegate netClientScriptDictUpdated:self];
				}
			}
			break;
			
			
			// host was available but not currently responding
		case MGSHostStatusNotResponding:
			//_badHeartbeatCount++;
			assignImage = YES;
			break;
			
			// host has disconnected normally and client set to be deleted
		case MGSHostStatusDisconnected:  
			_netService = nil;
			break;
			
			// host now available 
		case MGSHostStatusAvailable:			
			assignImage = YES;
			
			// host was previously not responding but has done so now.
			//if (prevHostStatus == MGSHostStatusNotResponding) {
			//	_badHeartbeatCount = 0;
			//}
			
			break;
			
		default:
			NSAssert1(NO, @"invalid host status %@", _hostStatus);
			break;
			
	}
	
	// get an image to represent the current host status
	if (assignImage) {
		;
	}
	
	[self assignHostImage];
}


#pragma mark MGSNetSocket delegate messages
/*
 
 net socket disconnected
 
 */
- (void)netSocketDisconnect:(MGSNetSocket *)netSocket
{
	NSAssert([netSocket disconnectCalled], @"disconnect not called on MGSNetClientSocket");
	
	// remove the netsocket
	//[_netSockets removeObject:netSocket];
	
	[_executingRequests removeObject:netSocket.netRequest];
	
	MLog(DEBUGLOG, @"MGSNetClient: %@ socket removed: executing request count is %i", _serviceName, [_executingRequests count]);
}


#pragma mark Properties
/*
 
 return YES if this client is local host
 
 */
- (BOOL)isLocalHost
{
	NSString *thisHostName = [[MGSSystem sharedInstance] localHostName];
	
	if ([_serviceName isEqualToString:thisHostName]) {
		return YES;
	} else {
		return NO;
	}
}

/*
 
 provides a host sort index
 
 */
- (int)hostSortIndex
{
	if (_hostType == MGSHostTypeLocal) return 0;	// local host
	if (_hostViaBonjour) return 1;					// bonjour host
	return 2;										// other hosts
}

#pragma mark MGSNetRequest delegate messages
/*
 
 request reply
 
 */
-(void)netRequestResponse:(MGSNetRequest *)netRequest payload:(MGSNetRequestPayload *)payload
{
	// validate response
	MGSNetClient *netClient = netRequest.netClient;
	
	// authenticate request
	if ([netRequest.requestCommand isEqualToString:MGSNetMessageCommandAuthenticate]) {
		
	// heartbeat request
	} else if ([netRequest.requestCommand isEqualToString:MGSNetMessageCommandHeartbeat]) {
		
		// if payload error then heartbeat failed
		if (nil != payload.requestError) {
			[self heartbeatReplyNotReceivedForNetClient:netClient];
		} else {
			[self heartbeatReplyReceivedForNetClient:netClient];
		}
		
	} else {
		[MGSError clientCode:MGSErrorCodeInvalidCommandReply];
		return;
	}
	
	//_authenticationDictionary = payload.dictionary;
}

#pragma mark Authentication handling
/*
 
 request authentication
 
 */
- (void)requestAuthentication
{
	[[MGSClientRequestManager sharedController] requestAuthenticationForNetClient:self withOwner:self];
}


/*
 
 set authentication dictionary.
 the dictionary should only be set following a successful authentication.
 the presence of the dictionary therefore confirms a successful authentication
 
 */
- (void)setAuthenticationDictionary:(NSDictionary *)dict
{
	_authenticationDictionary = dict;
	
	// inform delegate
	if (_delegate && [_delegate respondsToSelector:@selector(netClientAuthenticationStatusChanged:)]) {
		[_delegate netClientAuthenticationStatusChanged:self];
	}	
}

/*
 
 return the authentication dictionary
 
 */
- (NSDictionary *)authenticationDictionary
{
	return _authenticationDictionary;
}
/*
 
 return the authentication dictionary dependent on run mode
 
 */
- (NSDictionary *)authenticationDictionaryForRunMode
{
	if ([self isLocalHost] && !self.authenticationDictionary) {
		self.authenticationDictionary = [[MGSAuthentication sharedController] 
										 responseDictionaryforSessionService:self.serviceName 
										 password:[MGSAuthentication localHost] 
										 username:[MGSAuthentication localHost]];
	}
	
	switch (self.applicationWindowContext.runMode) {
			
			// do not want to authenticate public mode even if the
			// auth dict is available
		case kMGSMotherRunModePublic:
			return nil;
			break;
			
		case kMGSMotherRunModeAuthenticatedUser:
		case kMGSMotherRunModeConfigure:
			return self.authenticationDictionary;
			break;
			
			
		default:
			NSAssert(NO, @"invalid run mode");
			break;
	}
	
	return nil;
}

// authenticated convenience method
- (BOOL)isAuthenticated
{
	return (nil == _authenticationDictionary ? NO : YES);
}

#pragma mark TXT record handling
/*
 
 update the txt record
 
 */
- (void)TXTRecordUpdate
{
	if (_delegate && [_delegate respondsToSelector:@selector(netClientTXTRecordUpdated:)]) {
		[_delegate netClientTXTRecordUpdated:self];
	}
}

#pragma mark Operations

/*
 
 can edit script
 
 */
- (BOOL)canEditScript:(MGSScript *)script
{
	// can only edit bundled scripts on local host
	if ([script isBundled]) {
		return [[MGSPreferences standardUserDefaults] boolForKey:MGSAllowEditApplicationTasks] && [self isLocalHost];
	}
	
	return YES;
	
}

#pragma mark -
#pragma mark NSOperation
/*
 
 queue an operation
 
 */
- (void)queueOperation:(NSOperation *)theOp
{
	// lazy
	if (!_operationQueue) {
		_operationQueue = [NSOperationQueue new];
	}
	
	[_operationQueue addOperation:theOp];
}

#pragma mark -
#pragma mark Request sending

/*
 
 - sendRequestQueue
 
 */
- (void)sendRequestQueue
{
	NSAssert(!_isResolving, @"Cannot send request queue while resolving.");
	
	// send each queued request
	for (MGSNetRequest *request in [_pendingRequests copy]) {
		
		// remove item from pending queue
		[_pendingRequests removeObject:request];

		/*

		 see http://projects.mugginsoft.net/view.php?id=866
		 
		 if the net request class has a network thread then use it
		 
		 */
		if ([MGSNetRequest networkThread]) {
			
			// send request on network thread
			[request performSelector:@selector(sendRequestOnClientSocket) 
							onThread:[MGSNetRequest networkThread] 
						  withObject:nil 
					   waitUntilDone:NO];
			
		} else {
			[request sendRequestOnClientSocket];
		}
		
		// add request to executing queue
		[_executingRequests addObject:request];		
	}
	
}


/*
 
 delete session password
 
 */
- (void)deleteSessionPassword
{
	if (_authenticationDictionary) {
		[[MGSAuthentication sharedController] deleteKeychainSessionPasswordForService:_serviceName withDictionary:_authenticationDictionary];
	}	
}

	
// heartbeat reply received for self
-(void)heartbeatReplyReceivedForNetClient: (MGSNetClient *)netClient
{
	_badHeartbeatCount = 0;
	
	// switch on previous status
	switch (_hostStatus) {
			
		case MGSHostStatusDisconnected: 
			MLog(DEBUGLOG, @"unexpected heartbeat reply received for host status:%i", _hostStatus);
			break;	
			
		// host was not connected/responding but has now replied
		case MGSHostStatusNotYetAvailable:	
		case MGSHostStatusNotResponding:
			[self setHostStatus:MGSHostStatusAvailable];
			MLog(DEBUGLOG, @"%@ now responding", [netClient serviceName]);
			break;
			
			// host available
			// normally expect the heartbeat to return with the host in this status
		case MGSHostStatusAvailable:
			
			break;
			
		default:
			NSAssert1(NO, @"invalid host status %@", _hostStatus);
			break;
			
	}

	// tell the delegate.
	// of course the delegate could observe the old/prev host status but this
	// message is more convenient
	if (_delegate && [_delegate respondsToSelector:@selector(netClientResponding:)]) {
		[_delegate netClientResponding:netClient];
	}
	

}

// heartbeat not received for self
// a timeout or error has occurred
-(void)heartbeatReplyNotReceivedForNetClient: (MGSNetClient *)netClient
{
	switch (_hostStatus) {
		case MGSHostStatusNotYetAvailable:					
		case MGSHostStatusDisconnected: 
			MLog(DEBUGLOG, @"unexpected heartbeat reply not received for host status:%i", _hostStatus);
			break;	
			
		// host was already not responding and still isn't
		case MGSHostStatusNotResponding:;
			int heartbeatLimit = [[NSUserDefaults standardUserDefaults] integerForKey:MGSDefaultBadHeartbeatLimit];
			
			// mark non bonjour host as disconnected after successive bad heartbeats
			if (++_badHeartbeatCount == heartbeatLimit && _hostViaBonjour == NO) {
				[self setHostStatus:MGSHostStatusNotYetAvailable];
			}
			MLog(DEBUGLOG, @"%@ not responding", [netClient serviceName]);
			break;
			
			// host was available but now not responding
		case MGSHostStatusAvailable:	
			[self setHostStatus:MGSHostStatusNotResponding];
			MLog(DEBUGLOG, @"%@ not responding", [netClient serviceName]);
			break;
			
		default:
			NSAssert1(NO, @"invalid host status %@", _hostStatus);
			break;
			
	}
	
	// tell the delegate.
	if (_delegate && [_delegate respondsToSelector:@selector(netClientNotResponding:)]) {
		[_delegate netClientNotResponding:netClient];
	}
	
}

	
// resolve the host address and name from the netservice
- (void)getHostPort
{
	NSAssert(_netService, @"net service is nil");
	
	NSArray *addresses = [_netService addresses];
	NSAssert(addresses && [addresses count] > 0, @"invalid netservice addresses");

	
	// address is held as a struct in an NSData
	NSData *addressData = [addresses objectAtIndex:0];
	
	// extract port number
	// note that we could have used this structure to form our AsyncSocket
	// rather than the netService host name and socket.
	struct sockaddr	*address		= (struct sockaddr *)[addressData bytes];
	//uint16_t		family			= 0;
	uint16_t		port			= 0;
	
	if(address->sa_family == AF_INET) {
		MLog(DEBUGLOG, @"family is AF_INET");
		//family	= AF_INET;
		port	= ntohs(((struct sockaddr_in *)address)->sin_port);
		
	} else if(address->sa_family == AF_INET6) {
		MLog(DEBUGLOG, @"family is AF_INET6");
		//family	= AF_INET6;
		port	= ntohs(((struct sockaddr_in6 *)address)->sin6_port);
		
	} else {
		@throw [NSException exceptionWithName:@"MGSUnknownAddressFamily"
									   reason:@"The address family is unknown"
									 userInfo:nil];				
	}
	
	MLog(DEBUGLOG, @"service is on port %d", port);
	MLog(DEBUGLOG, @"service is on host %@", [_netService hostName]);
	
	// host port
	_hostPort = port;	
}


// assign host image according to current status
- (void)assignHostImage
{
	NSImage *image = nil;
	
	switch (_hostStatus) {
		// host not yet connected
		case MGSHostStatusNotYetAvailable:	
			
		// host has disconnected normally and client set to be deleted
		case MGSHostStatusDisconnected:  
			if (_hostType == MGSHostTypeLocal) {
				image = [[[MGSImageManager sharedManager] localHostUnavailable] copy];
			} else if (_hostViaBonjour) {
				image = [[[MGSImageManager sharedManager] remoteHostUnavailable] copy];
			} else {
				image = [[[MGSImageManager sharedManager] manualHostUnavailable] copy];
			}
			break;

		// host was available but not currently responding
		case MGSHostStatusNotResponding:
			if (_hostType == MGSHostTypeLocal) {
				image = [[[MGSImageManager sharedManager] localHostNotResponding] copy];
			} else if (_hostViaBonjour) {
				image = [[[MGSImageManager sharedManager] remoteHostNotResponding] copy];
			}else {
				image = [[[MGSImageManager sharedManager] manualHostNotResponding] copy];
			}
			break;
			
		// host available and responding - address was resolved
		case MGSHostStatusAvailable:			 
			if (_hostType == MGSHostTypeLocal) {
				image = [[[MGSImageManager sharedManager] localHostAvailable] copy];
			} else if (_hostViaBonjour) {
				image = [[[MGSImageManager sharedManager] remoteHostAvailable] copy];
			} else {
				image = [[[MGSImageManager sharedManager] manualHostAvailable] copy];
			}
			break;
			
		default:
			NSAssert1(NO, @"invalid host status %@", _hostStatus);
			return;
			
	}
	
	self.hostImage = image;
}

- (void)setNetService:(NSNetService *)aNetService
{
	// netservice may be nil after client disconnects from host.
	// though not active the client may live on within a history action.
	//
	// note that when a non nil service is first set the service will not have resolved
	// so its address and hostname will be unvailable.
	_netService = aNetService;
	if (!_netService) {
		// leave service name etc as is in case of reconnection
		return;
	}	
	
	[_netService setDelegate:self];
	[_netService startMonitoring];	// monitor TXTRecord changes: see Technical Q&A QA1389
	
	// host name
	self.serviceName = [_netService name];	// service name will be host name
	NSAssert(_serviceName, @"host name is nil");
	
	// short host name
	self.serviceShortName = [MGSPath hostNameMinusLocalLink:_serviceName];
	NSString *localHostName = [[MGSSystem sharedInstance] localHostName];
	localHostName = [MGSPath hostNameMinusLocalLink:localHostName];
		
	// set host type
	if ([_serviceShortName compare:localHostName options:NSCaseInsensitiveSearch] == NSOrderedSame) {
		self.hostType = MGSHostTypeLocal; 
	} else {
		self.hostType = MGSHostTypeRemote;
	}
	
}

// error on request
- (void) errorOnRequestQueue:(MGSNetRequest *)netRequest code:(NSInteger)code reason:(NSString *)failureReason
{
	// remove request from queue
	[_pendingRequests removeObject:netRequest];
	
	// on error send reply to delegate
	netRequest.error = [MGSError clientCode:code reason:failureReason]; 

	if (netRequest.delegate &&
		[netRequest.delegate respondsToSelector:@selector(netRequestReplyOnClient:)]) {
		
		// perform this on the next iteration of the run loop.
		[netRequest.delegate performSelector:@selector(netRequestReplyOnClient:) withObject:netRequest afterDelay:0];
	}
}

@end

//
// NSNetService delegate methods
//

#pragma mark - NSNetService delegate methods

@implementation MGSNetClient(NetServiceDelegate)

// did not resolve address
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
	#pragma unused(sender)
	
	_isResolving = NO;
	
	// send reply to each request delegate
	for (MGSNetRequest *netRequest in [_pendingRequests copy]) {
		
		NSInteger serviceErrorCode = [[errorDict objectForKey:NSNetServicesErrorCode] intValue];
		NSString *serviceError = [NSNetService errorDictString:errorDict];
		
		// on error send reply to owner
		NSString *failureReason = NSLocalizedString(@"Cannot resolve host: %@. NSNetService code: %i: %@", @"Cannot resolve host error");
		failureReason = [NSString stringWithFormat:failureReason, [_netService hostName], serviceErrorCode, serviceError];
		[self errorOnRequestQueue:netRequest code:MGSErrorCodeSendRequestMessage reason:failureReason];
	}
}

// did resolve address
- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
	//MLog(DEBUGLOG, @"client did resolve bonjour address");
	// see the apple picture sharing browser example
	// where the sender is not stopped until an IPV4 address is received
	// but asyncsocket can handlle IPV6 - a windows box maybe could not.
	// Iterate through addresses until we find an IPv4 address
	/* from the applke code
	 for (index = 0; index < [[sender addresses] count]; index++) {
	 address = [[sender addresses] objectAtIndex:index];
	 socketAddress = (struct sockaddr *)[address bytes];
	 
	 if (socketAddress->sa_family == AF_INET) break;
	 }
	 
	 // Be sure to include <netinet/in.h> and <arpa/inet.h> or else you'll get compile errors.
	 
	 if (socketAddress) {
	 switch(socketAddress->sa_family) {
	 case AF_INET:
	 if (inet_ntop(AF_INET, &((struct sockaddr_in *)socketAddress)->sin_addr, buffer, sizeof(buffer))) {
	 ipAddressString = [NSString stringWithCString:buffer];
	 portString = [NSString stringWithFormat:@"%d", ntohs(((struct sockaddr_in *)socketAddress)->sin_port)];
	 }
	 
	 // Cancel the resolve now that we have an IPv4 address.
	 [sender stop];
	 [sender release];
	 serviceBeingResolved = nil;
	 
	 break;
	 case AF_INET6:
	 // PictureSharing server doesn't support IPv6
	 return;
	 }
	 } 
	 */
	// stop the resolve
	[sender stop];	// is one address not  enough? see notes above
	_isResolving = NO;
	
	_hostName = [_netService hostName];	// use net

	[self getHostPort];
	[self sendRequestQueue];
	
}

/*
 NSNetServices (New since WWDC 2007)
 
 NSNetServices' behavior in handling timeouts is slightly different than what is provided by CFNetServices. 
 In Leopard, CFNetServices will unconditionally report a timeout error when the timeout chosen in
 CFNetServiceResolveWithTimeout() is hit, regardless of whether or not any addresses were actually resolved.
 
 NSNetServices will only report an NSNetServicesTimeoutError to the delegate's 
 netService:didNotResolve: callback if no addresses were resolved by a call to -[NSNetService resolve] or 
 -[NSNetService resolveWithTimeout:]. If addresses have been resolved, when the timeout is reached the delegate 
 will be notified on its -netServiceDidStop: delegate method.
 
 This will also be sent when we initiate a stop programmatically.
 */
- (void)netServiceDidStop:(NSNetService *)sender
{
	#pragma unused(sender)
	
	// this will be called for all resolve requests
	//MLog(DEBUGLOG, @"service did stop for service name : %@ type: %@", [sender name], [sender type]);
}

/*
 * txt record data updated
 *
 * A connection issue was arising here on application startup.
 * Connection to the local sever was intermittent with SSL enabled. Fine otherwise.
 * Logs indicated that SSL was not enabled on the client but WAS enabled on the server.
 * The client can only learn the correct SSL status of a client after the successful receipt
 * of a TXTRecordData that declares the server status.
 */
- (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data
{
	#pragma unused(sender)
	
	// if host not discovered via Bonjour then quit.
	// this should not occur in use but it may so in testing if a Mother
	// has been excluded to mimic a true remote Mother
	if (NO == _hostViaBonjour) {
		MLog(DEBUGLOG, @"TXT record update rejected for remote host");
		return;
	}
	
	MLog(DEBUGLOG, @"TXT record updated");

	// note that TXTRecord dictionary keys are recognised as UTF8 encoded but that objects
	// must be manually dearchived.	
	NSDictionary *txtDictionary = [NSNetService dictionaryFromTXTRecordData:data];
	
	// user name
	// the server may or may not dislose the username. if not disclosed the name is simply @"".
	NSString *user = [[NSString alloc] initWithData:[txtDictionary objectForKey:MGSTxtRecordKeyUser] encoding:NSUTF8StringEncoding]; 
	self.hostUserName = user;
	
	// SSL
	NSString *ssl = [[NSString alloc] initWithData:[txtDictionary objectForKey:MGSTxtRecordKeySSL] encoding:NSUTF8StringEncoding]; 
	self.securePublicTasks = ([ssl isEqualToString:MGS_TXT_RECORD_YES] ? YES : NO);

	self.TXTRecordReceived = YES;
	
	[self TXTRecordUpdate];
}

@end




