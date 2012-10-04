//
//  MGSNetRequest.m
//  Mother
//
//  Created by Jonathan on 30/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import "MGSMother.h"
#import "MGSNetMessage.h"
#import "MGSNetHeader.h"
#import "MGSNetRequest.h"
#import "MGSNetClient.h"
#import "MGSAsyncSocket.h"
#import "MGSNetSocket.h"
#import "MGSError.h"
#import "MGSAuthentication.h"
#import "MGSRequestProgress.h"
#import "MGSPreferences.h"
#import "MGSScriptPlist.h"
#import "MGSNetNegotiator.h"

enum MGSNetRequestFlags {
	kCommandBasedNegotiation      = 1 <<  0,  // If set, command based negotiation should be used
};

static 	unsigned long int requestSequenceID = 0;		// request sequence counter
static NSThread *networkThread = nil;

// class extension
@interface MGSNetRequest()
+ (void)runNetworkThread;
@property (readwrite) NSUInteger flags;
@property (readwrite) MGSNetMessage *requestMessage;
@property (readwrite) MGSNetMessage *responseMessage;
@end

@interface MGSNetRequest(Private)
-(void)initialise;
@end

@implementation MGSNetRequest

@synthesize requestMessage = _requestMessage;
@synthesize responseMessage = _responseMessage;
@synthesize netClient = _netClient;
@synthesize status = _status;	// required to be atomic
@synthesize delegate = _delegate;
@synthesize owner = _owner;
@synthesize error = _error; // required to be atomic
@synthesize readTimeout = _readTimeout; // required to be atomic
@synthesize writeTimeout = _writeTimeout; // required to be atomic
@synthesize requestID = _requestID;
@synthesize ownerObject = _ownerObject;
@synthesize ownerString = _ownerString;
@synthesize allowUserToAuthenticate = _allowUserToAuthenticate;
@synthesize sendUpdatesToOwner = _sendUpdatesToOwner;
@synthesize prevRequest = _prevRequest;
@synthesize nextRequest = _nextRequest;
@synthesize childRequests = _childRequests;
@synthesize parentRequest = _parentRequest;
@synthesize netSocket = _netSocket;
@synthesize flags = _flags;
@synthesize chunksReceived = _chunksReceived;
@synthesize requestType = _requestType;

#pragma mark Class methods

/*
 
 + initialize
 
 */
+ (void)initialize
{
	if ( self == [MGSNetRequest class] ) {
		BOOL useSeparateNetworkThread = [[NSUserDefaults standardUserDefaults] boolForKey:MGSUseSeparateNetworkThread];

		if (useSeparateNetworkThread) {
			
			/*
			 no reason why not to use an NSOperationQueue and run the run loop in main();
			 
			 messages can be sent with
			 
			 NSRunLoop  (void)performSelector:(SEL)aSelector target:(id)target argument:(id)anArgument order:(NSUInteger)order modes:(NSArray *)modes
			 
			 The NSOperation would need to set a property identifying its runloop.
			 
			 */
			// create the network thread
			networkThread = [[NSThread alloc] initWithTarget:self selector:@selector(runNetworkThread) object:nil];

			// start the network thread
			[networkThread start];
		}
	}
}

/*
 
 + runNetworkThread
 
 */
+ (void)runNetworkThread
{
	/*
	 
	 The network thread receives all callbacks from the network requests
	 and handles all message and attachment storing
	 
	 */
	do
	{
		// run the run loop
		CFRunLoopRunInMode(kCFRunLoopDefaultMode, 10, NO);
	}
	while (YES);
	
}

/*
 
 + networkThread
 
 */
+ (NSThread *)networkThread
{
	return networkThread;
}

/*
 
 request with client
 
 */
+ (id)requestWithClient:(MGSNetClient *)netClient
{
	return [[self alloc] initWithNetClient:netClient];
}

/*
 
 request with client command
 
 */
+ (id)requestWithClient:(MGSNetClient *)netClient command:(NSString *)command
{
	NSAssert(netClient, @"net client is nil");
	
	// create request on client
	MGSNetRequest *netRequest = [self requestWithClient:netClient];
	NSAssert(netRequest, @"net request is nil");
	
	// set the command
	// 1. MGSNetMessageCommandParseScript - the message contains a script dict to be parsed
	// 2. MGSNetMessageCommandHeartbeat - the message contains no dict - just a simple command
	//
	[netRequest.requestMessage setCommand:command];
	
	// set request timeouts
	if ([command isEqualToString:MGSNetMessageCommandHeartbeat]) {
		netRequest.readTimeout = 15.0;
		netRequest.writeTimeout = 15.0;
	}
	/*
	 else if ([command isEqualToString:MGSNetMessageCommandParseScript]) {
	 netRequest.readTimeout = -1;	// system default
	 netRequest.writeTimeout = -1;
	 }
	 */
	return netRequest;
}

/*
 
 request with connected socket
 
 */
+ (id) requestWithConnectedSocket:(MGSNetSocket *)netSocket
{
	return [[self alloc] initWithConnectedSocket:netSocket];
}

/*
 
 send request error to owner
 
 */
+ (void)sendRequestError:(MGSNetRequest *)request to:(id)owner
{
	if (owner && [owner respondsToSelector:@selector(netRequestResponse:payload:)]) {
		
		// if no error defined then define one
		if (!request.error) {
			[request setErrorCode:MGSErrorCodeDefaultRequestError description:nil];
		}
		
		// the response mechanism must deal with all errors
		[owner netRequestResponse:request payload:nil];
	}
}


#pragma mark Instance methods

/*
 
 - resetMessages
 
 */
- (void)resetMessages
{
	self.requestMessage = [[MGSNetMessage alloc] init];		// request will be received from client
    [self.requestMessage releaseDisposable];
    
	self.responseMessage = [[MGSNetMessage alloc] init];	// reply will be sent to client
    [self.responseMessage releaseDisposable];
}

/*
 
 - inheritConnection:
 
 */
- (void)inheritConnection:(MGSNetRequest *)request
{
	_netSocket = request.netSocket;
	_netSocket.netRequest = self;
}

/*
 
 - sent
 
 */
- (BOOL)sent
{
	// if the status is received then the request has been sent and a reply received
	return (self.status == kMGSStatusMessageReceived);
}

/*
 
 send error to owner
 
 */
- (void)sendErrorToOwner
{
	[[self class] sendRequestError:self to:self.owner];
}

/*
 
 SERVER SIDE - init with connected socket
 this request will reside on the server
 
 */
-(MGSNetRequest *)initWithConnectedSocket:(MGSNetSocket *)netSocket
{
	NSAssert(!_netClient, @"client detected");
	
	if ((self = [super init])) {
		
		[self initialise];
		
		if (![netSocket isConnected]) {
			MLog(DEBUGLOG, @"socket not connected");
			[self setErrorCode:0 description:NSLocalizedString(@"socket not connected", @"error on socket")];
			_status = kMGSStatusNotConnected;
		} else {
			_status = kMGSStatusConnected;
		}	
		
		_netSocket = netSocket;
	}
	return self;
}

/*
 
 CLIENT SIDE - initialise with net client
 this request will reside on the client
 
 */
-(MGSNetRequest *)initWithNetClient:(MGSNetClient *)netClient
{
	NSAssert(!_netSocket, @"socket detected");
	
	if ((self = [super init])) {
		
		// initialse the instance
		[self initialise];

		// retain our net client
		_netClient = netClient;
		
		// if net client is local host then flag this in the request message
		if([_netClient isLocalHost]) {
			[_requestMessage setMessageOriginIsLocalHost:YES];
		}
	}
	return self;
}

/*
 
 - sendRequestOnClient
 
 */
- (void)sendRequestOnClient
{
	NSAssert(_netClient, @"netclient is nil");	
	
	// the server will need to be informed of how timeouts are to be handled.
	// so pass the request timeout info in the header
	_requestMessage.header.requestTimeout = (NSInteger)_writeTimeout;
	_requestMessage.header.responseTimeout = (NSInteger)_readTimeout;
	
	// send request message
	[_netClient connectAndSendRequest:self];	
}

/*
 
 - sendRequestOnClientSocket
 
 */
- (void)sendRequestOnClientSocket
{

	/*===================================================
	 =
	 = if requests are being handled concurrently then
	 = this method will NOT be called on the main thread
	 =
	 ====================================================
	 */
	NSString *failureReason = nil;
	@try {
		// create net socket
		MGSNetClientSocket *netSocket = [[MGSNetClientSocket alloc] init];
		[netSocket setDelegate:_netClient];
		

		//
		// connect to host using NetClient properties
		//
		// the netSocket infrastructure will attach to the current threads runloop.
		// hence we need to have established our socket by the time we call this method.
		// note that we can change the run loop once the sochet has been created but I
		// think that will make little pratical difference in this case.
		//
		// see http://projects.mugginsoft.net/view.php?id=866
		//
        
        //
        // note that we connect to the hostname not the host IP (which we have).
        // this means that another DNS lookup will likely have to occur.
        // it also means that the network stack we use will determine whether we
        // connect via IPv4 or IPv6.
        
        // if our host name is a bonjour host (.local) we will likely get ap IPv6 connection.
        // a TLD address or explicit IPv4 address wil give us an IPv4 connection.
        // so, in the case of Bonjour we could likely force all connections to be on IPv4
        // by using the IPv4 address we probably obtained (as all modern Bonjour hosts run Ipv4 + 6)
        // when looking up the port number.
        
        NSString *hostName = [_netClient hostName]; // DNS host name
        
        // if client defines an addressString then use it.
        // this should prevent additional DNS lookups and should
        // allow selection of IPv4 or IPv6 by the client.
        
        // at pesent a scoket error occurs if we use the IPv6 address directly.
        if (_netClient.addressString && !_netClient.useIPv6) {
            hostName = _netClient.addressString;
        }
		if ([netSocket connectToHost:hostName onPort:[_netClient hostPort] forRequest:self]) {
			
			_netSocket = netSocket;
			
			// send request message - raises on error
			[_netSocket sendRequest];
			
		} else {
			failureReason = NSLocalizedString(@"Cannot connect to host: %@", @"Cannot connect to host error");
		} 
	} @catch (NSException *e) {
		failureReason = [e reason];
	}
	
	// on error send reply to delegate
	if (failureReason) {
		failureReason = [NSString stringWithFormat:failureReason, [_netClient hostName]];		
		[self.netClient errorOnRequestQueue:self code:MGSErrorCodeSendRequestMessage reason:failureReason];
	}
}

/*
 
 send response on socket
 
 */
- (void)sendResponseOnSocket
{
	NSAssert(_netSocket, @"socket is nil");

	// the client will need to be informed of how timeouts are to be handled.
	// so pass the request timeout info in the header
	_responseMessage.header.requestTimeout = (NSInteger)_readTimeout; 
	_responseMessage.header.responseTimeout = (NSInteger)_writeTimeout; 
    
    // identify the request that matches the response
    [_responseMessage setMessageObject:[_requestMessage messageUUID] forKey:MGSMessageKeyRequestUUID];
    
	// send response message - raises on error
	[_netSocket sendResponse];	
} 
/*
 
 send response chunk on socket
 
 */
- (void)sendResponseChunkOnSocket:(NSData *)data
{
    // send response message - raises on error
	[_netSocket sendResponseChunk:data];
}

/*
 
 socket disconnected
 
 this method is called from multiple threads
 
 */
- (void)setSocketDisconnected
{
	self.status = kMGSStatusDisconnected;
    
#ifdef MGS_LOG_DISCONNECT
    NSLog(@"socket disconnected for request: %@", self.requestMessage.messageDict);
#endif
}

/*
 
 setStatus:
 
 this method is called from multiple threads
 
 */
- (void)setStatus:(eMGSRequestStatus)value
{

	@synchronized (self) {
		_status = value;

		if (self.sendUpdatesToOwner) {
			// message owner with request status change for net request
			// this should only be implemented by owners that need 
			// to examine the request properties, such as the requestID
			// note that an observation could have done the trick just as well.
			if (_owner && [_owner respondsToSelector:@selector(netRequestUpdate:)]) {
				[_owner performSelectorOnMainThread:@selector(netRequestUpdate:) withObject:self waitUntilDone:NO];
			}
		}
	}
}

/*
 
 -chunkStringReceived
 
 */
- (void)chunkStringReceived:(NSString *)chunk {
    
    if (_owner && [_owner respondsToSelector:@selector(netRequestChunkReceived:)]) {
        
        if (!_chunksReceived) {
            _chunksReceived = [NSMutableArray arrayWithCapacity:5];
        }
        [_chunksReceived addObject:chunk];

        // thw chunks will have been removed by the time the following is scheduled to execute
        //[_owner performSelectorOnMainThread:@selector(netRequestChunkReceived:) withObject:self waitUntilDone:NO];

        // tell owner that a chunk is available
        [_owner netRequestChunkReceived:self];
        
        // for now we do not preserve the chunks.
        // in time we may wish to write them to file.
        [_chunksReceived removeAllObjects];
    }
    

}


#pragma mark -
#pragma mark Message handling
/*
 
 - setRequestMessage:
 
 */
- (void)setRequestMessage:(MGSNetMessage *)value
{
    [_requestMessage releaseDisposable];
    _requestMessage = value;
    [_requestMessage retainDisposable];
}

/*
 
 - setResponseMessage:
 
 */
- (void)setResponseMessage:(MGSNetMessage *)value
{
    [_responseMessage releaseDisposable];
    _responseMessage = value;
    [_responseMessage retainDisposable];
}

#pragma mark -
#pragma mark Request child handling

/*
 
 - addChildRequest:
 
 */
- (void)addChildRequest:(MGSNetRequest *)request
{
    [self.childRequests addObject:request];
    request.parentRequest = self;
}
/*
 - sendChildRequests
 
 */
- (void)sendChildRequests
{
    for (MGSNetRequest *auxiliaryRequest in self.childRequests) {
        [[self delegate] sendRequestOnClient:auxiliaryRequest];
    }
}
#pragma mark -
#pragma mark Request queue handling

/*
 
 - firstRequest
 
 */
- (MGSNetRequest *)firstRequest
{
	MGSNetRequest *request = self;
	do {
		if (request.prevRequest == nil) {
			break;
		}
		request = request.prevRequest;
	} while (YES);
	
	return request;
}

/*
 
 - queuedNegotiateRequest
 
 */
- (MGSNetRequest *)queuedNegotiateRequest
{
	MGSNetRequest *request = self;
	
	// look for negotiator
	do {
		if (request.requestMessage.isNegotiateMessage) {
			return self;
		}
	} while ((request = request.prevRequest));
	
	return nil;
	
}


/*
 
 - nextQueuedRequestToSend
 
 */
- (MGSNetRequest *)nextQueuedRequestToSend
{	
	MGSNetRequest *sendRequest = self;
	
	// look for a previous unsent request
	if (!sendRequest.sent) {
		MGSNetRequest *prevRequest = nil;
		
		while ((prevRequest = sendRequest.prevRequest)) {
			if (prevRequest.sent) {
				break;
			}
			sendRequest = prevRequest;
		}
	} else {
		MGSNetRequest *nextRequest = nil;
		
		// look for next unsent request
		while ((nextRequest = sendRequest.nextRequest)) {
			sendRequest = nextRequest;
			if (!nextRequest.sent) {
				break;
			}
		}
		
		if (sendRequest.sent) {
			sendRequest = nil;
		}
		
	}
	
	// if we have a previous request we inherit its connection
	if ([sendRequest prevRequest]) {
		[sendRequest inheritConnection:[sendRequest prevRequest]];
	}
	
	return sendRequest;
}

/*
 
 - nextOwnerInRequestQueue
 
 */
- (id)nextOwnerInRequestQueue
{
	MGSNetRequest *request = self;
	
	// look for next unsent request
	do {
		if (request.owner) {
			return request.owner;
		}
	} while ((request = request.nextRequest));
	
	return nil;
}
#pragma mark -
#pragma mark NSCopying

/*
 
 - prepareToResend
 
 */
- (void)prepareToResend
{

	if ([self isSocketConnected]) {
		[self disconnect];
	}
	_status = kMGSStatusNotConnected;
}

/*
 
 - copyWithZone:
 
 Creates a copy of a request suitable for sending.
 Once sent requests are disposed of and cannot be reused.
 
 */
- (id)copyWithZone:(NSZone *)zone
{
#pragma unused(zone)
    
    MGSNetRequest *copy = nil;
    if (self.netClient) {
        
        // make a copy
        copy = [[[self class] alloc] initWithNetClient:self.netClient];

        // copy the request message.
        // we don't copy the response.
        copy.requestMessage = [self.requestMessage copy];
        [copy.requestMessage releaseDisposable];
        
        // copy appropriate properties
        copy.delegate = self.delegate;
        copy.owner = self.owner;
        copy.ownerObject = self.ownerObject;
        copy.ownerString = self.ownerString;
        copy.allowUserToAuthenticate = self.allowUserToAuthenticate;
        copy.sendUpdatesToOwner = self.sendUpdatesToOwner;
        
    } else {
        // TODO: implement for server
    }
    
    return copy;
}

#pragma mark -
#pragma mark Flags

/*
 
 - commandBasedNegotiation
 
 */
- (BOOL)commandBasedNegotiation
{
	return (self.flags & kCommandBasedNegotiation);
}


#pragma mark -
#pragma mark Error handling

/*
 
 tagError:
 
 */
- (void)tagError:(MGSError *)error
{
    error.machineName = [self.netClient hostName];
}
#pragma mark -
#pragma mark Validation

/*
 
 - validateOnCompletion
 
 */
- (BOOL)validateOnCompletion:(MGSError **)mgsError
{
	
	// validate negotiator
	if (self.requestMessage.negotiator) {
		if (!self.responseMessage.negotiator) {
			if (mgsError) {
				*mgsError = [MGSError clientCode:MGSErrorCodeBadRequestFormat reason:@"Missing negotiator detected. Empty negotiator added to request."];
				[self.responseMessage applyNegotiator:[[MGSNetNegotiator alloc] init]];
				*mgsError = nil; // fixed this error
			}
		}
	} else {
		if (self.responseMessage.negotiator) {
			if (mgsError) {
				*mgsError = [MGSError clientCode:MGSErrorCodeBadRequestFormat reason:@"Unexpected negotiator found. Negotiator removed from request."];
				[self.responseMessage removeNegotiator];
				*mgsError = nil; // fixed this error
			}
			return NO;
		}
	}
	
	return YES;
}

#pragma mark -
#pragma mark Negotiation

/*
 
 - negotiateRequest
 
 */
- (MGSNetRequest *)enqueueNegotiateRequest
{
	NSString *command = MGSNetMessageCommandNegotiate;

	/*
	 
	 If command based negotiation is enabled then each individual command
	 has to be responsible for processing its own negotiate requests.
	 
	 */
	if ([self commandBasedNegotiation]) {
		command = self.requestCommand;
	}
	
	// allocate negotiate request with same netClient and command
	MGSNetRequest *negotiateRequest = [MGSNetRequest requestWithClient:self.netClient command:command]; 
	
	negotiateRequest.delegate = self.delegate;
	negotiateRequest.owner = self.owner;
	negotiateRequest.sendUpdatesToOwner = NO;
	
	// link the requests
	self.prevRequest = negotiateRequest;
	negotiateRequest.nextRequest = self;
	
	return negotiateRequest;
}


#pragma mark -
#pragma mark Security

/*
 
 - secure
 
 */
- (BOOL)secure
{
	return [_netSocket willSecure];
}
#pragma mark -
#pragma mark Accessors

/*
 
 - requestCommand
 
 */
- (NSString *)requestCommand
{
	// return the request command.
	// this is a top level command such as :
	// Parse KosmicTask
	// Authenticate
	// Heartbeat
	// Update preferences
	return [[_requestMessage messageDict] objectForKey:MGSScriptKeyCommand];
}

/*
 
 - kosmicTaskCommand
 
 */
- (NSString *)kosmicTaskCommand
{
	// get the kosmicTask object 
	NSDictionary *dict = [[_requestMessage messageDict] objectForKey:MGSScriptKeyKosmicTask];
	
	// get the command
	return [dict objectForKey:MGSScriptKeyCommand];
}

#pragma mark -
#pragma mark MGSDisposableObject

/*
 
 - releaseDisposable
 
 */
- (void)releaseDisposable
{

#ifdef MGS_LOG_ME
    if (self.disposalCount == 1) {
        NSLog(@"%@ about to be disposed", self);
    }
#endif
 
#ifdef MGS_LOG_DISPOSE 
    if ([self isDisposedWithLogIfTrue]) {
        NSLog(@"%@ -%@ called on request: i%@", [self className], NSStringFromSelector(_cmd), _requestMessage.messageDict);
    }
#endif
    
    [super releaseDisposable];
    
}

/*
 
 - dispose
 
 */
- (void)dispose
{
#ifdef MGS_LOG_DISPOSE
	MLog(DEBUGLOG, @"MGSNetRequest disposed");
#endif
    
    if ([self isDisposedWithLogIfTrue]) {
        
#ifdef MGS_LOG_DISPOSE      
        NSLog(@"%@ -%@ called on request: i%@", [self className], NSStringFromSelector(_cmd), _requestMessage.messageDict);
#endif
        
        return;
    }
    
    // call dispose on messages
    [_requestMessage releaseDisposable];
    [_responseMessage releaseDisposable];
    
	// remove temporary paths
	for (NSString *path in temporaryPaths) {
        
        // check for existence
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            
            NSError *error = nil;
            if (![[NSFileManager defaultManager] removeItemAtPath:path error:&error]) {
                MLogInfo(@"Cannot delete request temp path : %@\nerror : %@", path, [error localizedDescription]);
            }
        }
	}
    
    [super dispose];
}

/*
 
 finalize
 
 */
- (void)finalize
{
    
#ifdef MGS_LOG_FINALIZE
	MLog(DEBUGLOG, @"MGSNetRequest finalized");
#endif
    
    if (!self.disposed) {
        NSLog(@"%@", self.requestMessage.messageDict);
        return;
    }
    
	[super finalize];
}


#pragma mark -
#pragma mark Temporary path management

/*
 
 - addTemporaryPath
 
 */
- (void)addScratchPath:(NSString *)path
{
	if ([path isKindOfClass:[NSString class]]) {
		[temporaryPaths addObject:path];
	}
}

//========================================
// returns YES if request authenticates
// against the host
//========================================
- (BOOL)authenticate
{
	BOOL success = NO;
	
	// get the authentication dictionary
	NSDictionary *authDict = [_requestMessage authenticationDictionary];
	if ([authDict isKindOfClass:[NSDictionary class]]) {
		
		// authenticate localhost
		if ([_netSocket isConnectedToLocalHost]) {
			success = [[MGSAuthentication sharedController] authenticateLocalHostWithDictionary:authDict];
		} else {
			success = [[MGSAuthentication sharedController] authenticateWithDictionary:authDict];
		}		
	}

	return success;
}

/*
 
 authenticate with auto response on failure
 
 */
- (BOOL)authenticateWithAutoResponseOnFailure:(BOOL)autoResponse
{
	NSString *error = nil;
	NSInteger errorCode = MGSErrorCodeSecureConnectionRequired;
	MGSError *mgsError = nil;
	
	/*
	 
	 negotiation is mandatory for authentication requests
	 
	 */
	MGSNetNegotiator *requestNegotiator = self.requestMessage.negotiator;
	if (requestNegotiator) {
		
		// Always secure authentication requests regardless of the
		// content of the negotiate dictionary
		MGSNetNegotiator *responseNegotiator = nil;
		
		// local host does not require security
		if ([_netSocket isConnectedToLocalHost] && ![requestNegotiator TLSSecurityRequested]) {
			responseNegotiator = [[MGSNetNegotiator alloc] init];	
		} else {
			responseNegotiator = [MGSNetNegotiator negotiatorWithTLSSecurity];	
		}
		[self.responseMessage applyNegotiator:responseNegotiator];
		
		if (autoResponse) {
			[_delegate sendResponseOnSocket:self wasValid:YES];
			return NO;
		}
		
	} else {
		
		// if the connection is not secure then we refuse
		// the authentication request unless it is from the localhost
		if (!self.secure && ![_netSocket isConnectedToLocalHost]) {
			error =  NSLocalizedString(@"Request denied. Authentication required.", @"Error returned by server");
			goto error_exit;
		}
	}
	
	// authenticate
	if ([self authenticate]) {
		return YES;
	}
	
	//========================================
	//
	// authentication has failed
	//
	// if auto response defined then send response
	//========================================
	if (autoResponse) {
		
		// choose authentication algorithm
		NSString *algorithm = (NSString *)MGSAuthenticationClearText;
		
		// form the authenticate challenge reply and add to dict.
		// if using cleartext there will be no challenge
		NSDictionary *challengeDict = [[MGSAuthentication sharedController] authenticationChallenge:algorithm];
		if (challengeDict) {
			[self.responseMessage setMessageObject:challengeDict forKey:MGSNetMessageKeyChallenge];
		}
		
		// add authentication error to reply
		mgsError = [MGSError serverCode:MGSErrorCodeAuthenticationFailure];
		[self.responseMessage setErrorDictionary:[mgsError dictionary] ];
		
		// tell delegate that authentication has failed.
		// the delegate can send the appropriate response to the client
		if (_delegate && [_delegate respondsToSelector:@selector(authenticationFailed:)]) {
			[_delegate authenticationFailed:self];
		}	
	}
	
	return NO;

error_exit:
	
	if (autoResponse) {
		mgsError = [MGSError serverCode:errorCode reason:error];
		[self.responseMessage setErrorDictionary:[mgsError dictionary]];
		[_delegate sendResponseOnSocket:self wasValid:NO];
	}
	
	return NO;
}

/*
 
 set error code
 
 */
- (void)setErrorCode:(NSInteger)code description:(NSString *)description
{
	self.error = [MGSError frameworkCode:code reason:description];
}

/*
 
 update progress
 
 */
- (void)updateProgress:(MGSRequestProgress *)progress
{
	unsigned long bytesDone = 0, bytesTotal = 0;
	
	switch (progress.value) {
		case MGSRequestProgressReady:
			break;
			
		case MGSRequestProgressSending:
			//
			// note that the requestSizeTransferred is equal to the total that has actually
			// been sent + the amount that the current socket operation reports as complete.
			// if this calculation is made when all writes have completed then there will
			// be a slight error as total will be equivalent to the message size + size of the last write buffer.
			// in this case -requestSizeTransferred limits itself to the requestSizeTotal.
			//
			[_netSocket progressOfWrite:&bytesDone totalBytes:&bytesTotal];
			progress.requestSizeTransferred = self.requestMessage.bytesTransferred + bytesDone;
			if (progress.requestSizeTotal != 0) {
				progress.percentageComplete = (100 * progress.requestSizeTransferred)/progress.requestSizeTotal;
			}
		break;
			
		case MGSRequestProgressWaitingForReply:
			break;
			
		case MGSRequestProgressReceivingReply:
			[_netSocket progressOfRead:&bytesDone totalBytes:&bytesTotal];
			progress.requestSizeTransferred = self.responseMessage.bytesTransferred + bytesDone;
			if (progress.requestSizeTotal != 0) {
				progress.percentageComplete = (100 * progress.requestSizeTransferred)/progress.requestSizeTotal;
			}
			break;
		
		case MGSRequestProgressSuspendedSending:
			break;
			
		case MGSRequestProgressSuspendedReceiving:
			break;
			
		case MGSRequestProgressReplyReceived:
			break;
			
		case MGSRequestProgressCompleteWithNoErrors:
			break;		
			
		case MGSRequestProgressCompleteWithErrors:
			break;		
			
		case MGSRequestProgressCannotConnect:
			break;		
			
		case MGSRequestProgressTerminatedByUser:
			break;		
			
		case MGSRequestProgressSuspended:
			break;

		default:
			NSAssert(NO, @"invalid request progress value");
	}
}

/*
 
 request UUID
 
 */
- (NSString *)UUID
{
	return [_requestMessage messageUUID];
}

#pragma mark Suspending
/*
 
 is read suspended
 
 */
- (BOOL)isReadSuspended
{
	return _netSocket.socket.isReadSuspended;
}
/*
 
 set read suspended
 
 */
- (void)setReadSuspended:(BOOL)newValue
{
	_netSocket.socket.readSuspended = newValue; 
}
/*
 
 set write suspended
 
 */
- (void)setWriteSuspended:(BOOL)newValue
{
	_netSocket.socket.writeSuspended = newValue; 
}
/*
 
 is write suspended
 
 */
- (BOOL)isWriteSuspended
{
	return _netSocket.socket.isWriteSuspended;
}

#pragma mark -
#pragma mark Connection handling
/*
 
 disconnect
 
 */
- (void)disconnect
{
	if ([self isSocketConnected]) {
		[_netSocket disconnect];
        
        // the socket should update the request status
        // but we need to make sure that this occurs now
        if (self.status != kMGSStatusDisconnected) {
            [self setSocketDisconnected];
        }
	} else {
		MLogInfo(@"Attempting to disconnect an already disconnected socket");
	}
}

/*
 
 - socketConnected
 
 */
- (BOOL)isSocketConnected
{
	return [_netSocket isConnected];
}
@end

@implementation MGSNetRequest(Private)

/*
 
 initialise
 
 */
-(void)initialise
{
    _requestType = kMGSRequestTypeWorker;
	_status = kMGSStatusNotConnected;
	
	self.requestMessage = [[MGSNetMessage alloc] init];		// request will be received from client
    [self.requestMessage releaseDisposable];
    
	self.responseMessage = [[MGSNetMessage alloc] init];	// reply will be sent to client
	[self.responseMessage releaseDisposable];
    
	_readTimeout = -1.0;	// don't timeout
	_writeTimeout = -1.0;	// don't timeout
	_requestID = requestSequenceID++;
	self.allowUserToAuthenticate = YES;
	_sendUpdatesToOwner = NO;
	temporaryPaths = [NSMutableArray new];
    _childRequests = [NSMutableArray new];
}


@end

