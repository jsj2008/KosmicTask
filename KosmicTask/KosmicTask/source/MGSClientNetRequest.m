//
//  MGSClientNetRequest.m
//  KosmicTask
//
//  Created by Jonathan on 08/10/2012.
//
//

#import "MGSClientNetRequest.h"
#import "MGSMother.h"
#import "MGSNetMessage.h"
#import "MGSNetHeader.h"
#import "MGSClientNetRequest.h"
#import "MGSNetClient.h"
#import "MGSAsyncSocket.h"
#import "MGSNetSocket.h"
#import "MGSError.h"
#import "MGSAuthentication.h"
#import "MGSRequestProgress.h"
#import "MGSPreferences.h"
#import "MGSScriptPlist.h"
#import "MGSNetNegotiator.h"
#import "MGSNetClient.h"

// class extension
@interface MGSClientNetRequest()
@end

@implementation MGSClientNetRequest

@synthesize netClient = _netClient;
@synthesize prevRequest = _prevRequest;
@synthesize nextRequest = _nextRequest;
@synthesize owner = _owner;
@synthesize sendUpdatesToOwner = _sendUpdatesToOwner;
@synthesize ownerObject = _ownerObject;
@synthesize ownerString = _ownerString;
@synthesize allowUserToAuthenticate = _allowUserToAuthenticate;
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
	MGSClientNetRequest *netRequest = [self requestWithClient:netClient];
	NSAssert(netRequest, @"net request is nil");
	
	// set the command
	// 1. MGSNetMessageCommandParseScript - the message contains a script dict to be parsed
	// 2. MGSNetMessageCommandHeartbeat - the message contains no dict - just a simple command
	//
	[netRequest.requestMessage setCommand:command];
	
	return netRequest;
}

/*
 
 initialise
 
 */
-(void)initialise
{
    [super initialise];
    _childRequests = [NSMutableArray new];
    _sendUpdatesToOwner = NO;
    _allowUserToAuthenticate = YES;
}

/*
 
 CLIENT SIDE - initialise with net client
 this request will reside on the client
 
 */
-(MGSClientNetRequest *)initWithNetClient:(MGSNetClient *)netClient
{
	if ((self = [super init])) {
		
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
	_requestMessage.header.requestTimeout = self.writeTimeout;
	_requestMessage.header.responseTimeout = self.readTimeout;
	
	// send request message
	[_netClient connectAndSendRequest:self];
    
    // configure timeouts
    
    // start the request timer.
    // this enables us to timeout the entire request if required
    [self startRequestTimer];

    // start timer to look for 0 writes on connection
    [self startWriteConnectionTimer];
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
        
        // interfaces as cached in the netclient macy change (wireless may be siwyched off).
        // so it is safer to yse the hostName and like the os choose the interface and the IP version
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

/*
 
 setStatus:
 
 this method is called from multiple threads
 
 */
- (void)setStatus:(eMGSRequestStatus)value
{
    
	@synchronized (self) {
		[super setStatus:value];
        
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
 
 - inheritConnection:
 
 */
- (void)inheritConnection:(MGSNetRequest *)request
{
	_netSocket = request.netSocket;
	_netSocket.netRequest = self;
}

#pragma mark -
#pragma mark Timeout handling

/*
 
 - writeConnectionDidTimeout:
 
 */
- (void)writeConnectionDidTimeout:(NSTimer *)timer
{
    [super writeConnectionDidTimeout:timer];
    
    unsigned long bytesDone = 0, bytesTotal = 0;
    
    // if nothing has been sent on the socket then we timeout
    // the request
    [_netSocket progressOfWrite:&bytesDone totalBytes:&bytesTotal];
    bytesDone += self.requestMessage.bytesTransferred + bytesDone;

    if (bytesDone == 0) {
        [self disconnect];
        [self setErrorCode:MGSErrorCodeRequestWriteConnectionTimeout description:NSLocalizedString(@"Request write connection timed out.", @"Request write connection timeout")];
        [self sendErrorToOwner];
    }
}

/*
 
 - requestDidTimeout:
 
 */
- (void)requestDidTimeout:(NSTimer *)timer
{
    [super requestDidTimeout:timer];
}

#pragma mark -
#pragma mark NSCopying


/*
 
 - copyWithZone:
 
 Creates a copy of a request suitable for sending.
 Once sent requests are disposed of and cannot be reused.
 
 */
- (id)copyWithZone:(NSZone *)zone
{
#pragma unused(zone)
    
    MGSClientNetRequest *copy = nil;
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
#pragma mark Error handling

/*
 
 tagError:
 
 */
- (void)tagError:(MGSError *)error
{
    error.machineName = [self.netClient hostName];
}
/*
 
 send error to owner
 
 */
- (void)sendErrorToOwner
{
    // logging requests do not need to communicate with their owner
    if (self.requestType == kMGSRequestTypeWorker) {
        [[self class] sendRequestError:self to:self.owner];
    }
}


/*
 
 send request error to owner
 
 */
+ (void)sendRequestError:(MGSClientNetRequest *)request to:(id)owner
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

#pragma mark -
#pragma mark Negotiation

/*
 
 - negotiateRequest
 
 */
- (MGSClientNetRequest *)enqueueNegotiateRequest
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
	MGSClientNetRequest *negotiateRequest = [MGSClientNetRequest requestWithClient:self.netClient command:command];
	
	negotiateRequest.delegate = self.delegate;
	negotiateRequest.owner = self.owner;
	negotiateRequest.sendUpdatesToOwner = NO;
	
	// link the requests
	self.prevRequest = negotiateRequest;
	negotiateRequest.nextRequest = self;
	
	return negotiateRequest;
}
#pragma mark -
#pragma mark Request child handling

/*
 - sendChildRequests
 
 */
- (void)sendChildRequests
{
    for (MGSClientNetRequest *auxiliaryRequest in self.childRequests) {
        [[self delegate] sendRequestOnClient:auxiliaryRequest];
    }
}
#pragma mark -
#pragma mark Request queue handling

/*
 
 - firstRequest
 
 */
- (MGSClientNetRequest *)firstRequest
{
	MGSClientNetRequest *request = self;
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
- (MGSClientNetRequest *)queuedNegotiateRequest
{
	MGSClientNetRequest *request = self;
	
	// look for negotiator
	do {
		if (request.requestMessage.isNegotiateMessage) {
			return self;
		}
	} while ((request = request.prevRequest));
	
	return nil;
	
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
 
 - nextQueuedRequestToSend
 
 */
- (MGSClientNetRequest *)nextQueuedRequestToSend
{
	MGSClientNetRequest *sendRequest = self;
	
	// look for a previous unsent request
	if (!sendRequest.sent) {
		MGSClientNetRequest *prevRequest = nil;
		
		while ((prevRequest = sendRequest.prevRequest)) {
			if (prevRequest.sent) {
				break;
			}
			sendRequest = prevRequest;
		}
	} else {
		MGSClientNetRequest *nextRequest = nil;
		
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
	MGSClientNetRequest *request = self;
	
	// look for next unsent request
	do {
		if (request.owner) {
			return request.owner;
		}
	} while ((request = request.nextRequest));
	
	return nil;
}


@end
