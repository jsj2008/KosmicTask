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
- (void)invalidateRWTimers;
- (void)requestDidTimeout:(NSTimer *)timer;
@property (readwrite) NSUInteger flags;
@property (readwrite) MGSNetMessage *responseMessage;
@end

@interface MGSNetRequest(Private)
@end

@implementation MGSNetRequest

@synthesize childRequests = _childRequests;
@synthesize parentRequest = _parentRequest;
@synthesize requestMessage = _requestMessage;
@synthesize responseMessage = _responseMessage;
@synthesize status = _status;	// required to be atomic
@synthesize delegate = _delegate;
@synthesize error = _error; // required to be atomic
@synthesize readTimeout = _readTimeout; // required to be atomic
@synthesize writeTimeout = _writeTimeout; // required to be atomic
@synthesize timeout = _timeout;
@synthesize requestID = _requestID;
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



#pragma mark Instance methods

/*
 
 - init
 
 */
- (id)init
{
    self = [super init];
    if (self) {
        [self initialise];
    }
    
    return self;
}
/*
 
 - initialise
 
 */
-(void)initialise
{
    _requestType = kMGSRequestTypeWorker;
	_status = kMGSStatusNotConnected;
	
	self.requestMessage = [[MGSNetMessage alloc] init];		// request will be received from client
    [self.requestMessage releaseDisposable];
    
	self.responseMessage = [[MGSNetMessage alloc] init];	// reply will be sent to client
	[self.responseMessage releaseDisposable];
    
	self.timeout = -1;	// don't timeout
    
	_requestID = requestSequenceID++;
	temporaryPaths = [NSMutableArray new];
}

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
 
 socket disconnected
 
 this method is called from multiple threads
 
 */
- (void)setSocketDisconnected
{
	self.status = kMGSStatusDisconnected;
    
    [self invalidateRWTimers];
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
	}
}

/*
 
 -chunkStringReceived
 
 */
- (void)chunkStringReceived:(NSString *)chunk {
#pragma unused(chunk)
    // override
}

/*
 
 - copyWithZone:
 
 */
- (id)copyWithZone:(NSZone *)zone
{
#pragma unused(zone)
    return nil; // override
}

#pragma mark -
#pragma mark Timeout handling

/*
 
 - writeConnectionDidTimeout:
 
 */
- (void)writeConnectionDidTimeout:(NSTimer *)timer
{
#pragma unused(timer)
    
    [self invalidateRWTimers];
}

/*
 
 - startRequestTimer
 
 */
- (void)startRequestTimer
{
    if (self.timeout > 0) {
        _requestTimer = [NSTimer scheduledTimerWithTimeInterval:self.timeout target:self selector:@selector(requestDidTimeout:) userInfo:nil repeats:NO];
        
        MLogDebug(@"Request timer started: %d secs", self.timeout);
    }
}

/*
 
 - startWriteConnectionTimer
 
 */
- (void)startWriteConnectionTimer
{
    // the socket write timeouts operate on the buffer.
    // so if the buffer pulls in data then it seems to have been sent and the socket timeout does not occur.
    // however we do seem to be able to detect if any data has being reported as sent.
    // if it looks as if no data is sent during the writeConnection period then we can disconnect.
    
    NSInteger writeConnectionTimeout = [[NSUserDefaults standardUserDefaults] integerForKey:MGSRequestWriteConnectionTimeout];
    
    // start the write connection timer
    if (writeConnectionTimeout > 0) {
        _writeConnectionTimer = [NSTimer scheduledTimerWithTimeInterval:writeConnectionTimeout target:self selector:@selector(writeConnectionDidTimeout:) userInfo:nil repeats:NO];
    }
    

}
/*
 
 - requestDidTimeout:
 
 */
- (void)requestDidTimeout:(NSTimer *)timer
{
#pragma unused(timer)
    
    [self invalidateRWTimers];
    
    MLogDebug(@"Request timer expired after %d secs", self.timeout);

    if (self.delegate && [self.delegate respondsToSelector:@selector(requestTimerExpired:)]) {
        [self.delegate requestTimerExpired:self];
    }
}

/*
 
 - setTimeoutForRead:write:
 
 */
- (void)setTimeoutForRead:(NSInteger)rt write:(NSInteger)wt
{
    // force read and write timeouts to max value
    self.timeout = (rt > wt ? rt : wt);
}

/*
 
 - setTimeout:
 
 */
- (void)setTimeout:(NSInteger)value
{
    // -1 indicates no timeout
    if (value <= 0) value = -1;
    
    _timeout = value;
    
    // read and write timeouts are equal
    _readTimeout = value;
    _writeTimeout = value;
}
/*
 
 - invalidateRWTimers
 
 */
- (void)invalidateRWTimers
{
    [_writeConnectionTimer invalidate];
    [_requestTimer invalidate];
    
    _writeConnectionTimer = nil;
    _requestTimer = nil;
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
    
    [self invalidateRWTimers];
    
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



/*
 
 set error code
 
 */
- (void)setErrorCode:(NSInteger)code description:(NSString *)description
{
	self.error = [MGSError frameworkCode:code reason:description];
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
    // a socket only reports itself -isSocketConnected as connected if the CFStream
    // object that it encapsulates has an open status.
    // if no data has been sent on the stream.
    // however the socket has still be constructed.
    //
	if ([self isSocketConnected] || self.status != kMGSStatusDisconnected) {
		[_netSocket disconnect];
        
        // the socket should update the request status
        // but we need to make sure that this occurs now
        if (self.status != kMGSStatusDisconnected) {
            [self setSocketDisconnected];
        }
	} else {
        MLogDebug(@"Attempting to disconnect already disconnected socket.");
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



@end

