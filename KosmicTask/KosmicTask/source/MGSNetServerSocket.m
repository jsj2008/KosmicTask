//
//  MGSNetServerSocket.m
//  Mother
//
//  Created by Jonathan on 04/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSNetServerSocket.h"

#import "MGSMother.h"
#import "MGSNetServerSocket.h"
#import "MGSNetHeader.h"
#import "MGSNetRequest.h"
#import "MGSNetMessage.h"
#import "MGSServerRequestManager.h"
#import "MGSAsyncSocket.h"
#import "MGSSecurity.h"
#import "MGSPreferences.h"
#import "MGSNetNegotiator.h"

@interface MGSNetServerSocket(Private)
@end

//
// each instance of MGSNetServerSocket communicates with 
// numerous instances of MGSNetClientSocket
//
@implementation MGSNetServerSocket


/*
 This method sets up the accept socket, but does not actually start it.
 Once started, the accept socket accepts incoming connections and creates new
 instances of AsyncSocket to handle them.
 Echo Server keeps the accept socket in index 0 of the sockets array and adds
 incoming connections at indices 1 and up.
 */
-(id) init
{	
	return [self initWithAcceptSocket:nil];
}

/*
 
 init with accept socket
 
 */
- (id)initWithAcceptSocket:(MGSAsyncSocket *)socket
{
	if ([super initWithMode:NETSOCKET_SERVER]) {

		// use SSL security - presync ensures that value matches latest update from GUI
		_enableSSLSecurity = [[MGSPreferences standardUserDefaults] boolForKey:MGSEnableServerSSLSecurity withPreSync:YES];
		
		NSAssert([socket canSafelySetDelegate], @"cannot safely set new socket delegate");
		[socket setDelegate:self];
		 
		self.socket = socket;
	}
	return self;
}

/*
 
 accept on port
 
 */
- (BOOL)acceptOnPort:(UInt16)portNumber
{
	#pragma unused(portNumber)
	
	MLog(DEBUGLOG, @"Received unexpected -acceptOnPort message from socket");
	return NO;
}

/*
 This will be called whenever AsyncSocket is about to disconnect. In Echo Server,
 it does not do anything other than report what went wrong (this delegate method
 is the only place to get that information), but in a more serious app, this is
 a good place to do disaster-recovery by getting partially-read data. This is
 not, however, a good place to do cleanup. The socket must still exist when this
 method returns.
 */
-(void) onSocket:(MGSAsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
	#pragma unused(sock)
	
	if (err != nil)
		MLogInfo(@"Server socket will disconnect. Error domain %@, code %d (%@).",
			   [err domain], [err code], [err localizedDescription]);
	else {
		MLog(DEBUGLOG, @"Server socket will disconnect. No error.");
	}
}

/*
 
 Normally, this is the place to release the socket and perform the appropriate
 housekeeping and notification. 
 
 */
-(void) onSocketDidDisconnect:(MGSAsyncSocket *)sock
{
	#pragma unused(sock)
	
	MLog(DEBUGLOG, @"Server socket disconnected.");
	
	// mark request as disconnected
	[self.netRequest setSocketDisconnected];
	
	// tell delegate that socket disconnected
	if ([self delegate] && 
		[[self delegate] respondsToSelector:@selector(netSocketDisconnect:)]) {
		[[self delegate] netSocketDisconnect:self];
	}
	
	// conclude the request
	[[MGSServerRequestManager sharedController] concludeRequest:self.netRequest];
}

/*
 At this point, the new socket is ready to use. This is where you can screen the
 remote socket or find its DNS name (the host parameter is just an IP address).
 This is also where you should set up your initial read or write request, unless
 you have a particular reason for delaying it.
 */
-(void) onSocket:(MGSAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
#pragma unused(host)
#pragma unused(port)
	
	MLogDebug(@"Socket did connect: local : %@ port: %u - remote : %@ port: %u ", 
			  sock.localHost, sock.localPort, sock.connectedHost, sock.connectedPort);
	
	// create new request
	self.netRequest = [[MGSServerRequestManager sharedController] requestWithConnectedSocket:self];
	
	// set timeouts

#pragma mark warning need to consider these timeouts further
	self.netRequest.readTimeout = 120;
	self.netRequest.writeTimeout = 120; 

	// queue a read 
	[self queueReadMessage];
}


/*
 This method is called whenever a packet is read. In Echo Server, a packet is
 simply a line of text, and it is transmitted to the connected Echo clients.
 Once you have dealt with the incoming packet, you should set up another read or
 write request, or -- unless there are other requests queued up -- AsyncSocket
 will sit idle.
 */
-(void) onSocket:(MGSAsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag
{
	@try {	
		
		[super onSocket:sock didReadData:data withTag:tag];

		switch (self.netRequest.status) {
				
				// messsage received
			case kMGSStatusMessageReceived:
				
				MLog(DEBUGLOG, @"Server received request: %@", [self.netRequest.requestMessage messageDict]);

				// parse the request and generate reply
				[[MGSServerRequestManager sharedController] parseRequestMessage:self.netRequest];
				break;
				
			default:
				break;
				
		}
	}
	@catch (NSException *e) {
		
		[MGSError clientCode:MGSErrorCodeServerException reason:[e description]];
		
		if ([self isConnected]) {
			[self disconnect];
		}
	}	
}

/*
 
 on read bad data
 
 */
- (void)onReadBadDataWithErrors:(NSString *)error
{
	[super onReadBadDataWithErrors:error];
	[MGSError serverCode:MGSErrorCodeMessageBadData reason:error];
}

/*
 
 queue read message
 
 */
- (void)queueReadMessage
{
	/* 
	 
	 check required negotiation.
	 
	 we do this before calling super, which queues a read, to ensure that
	 a race condition does not exist between the incoming data and the 
	 security request
	 
	 */
	if ([self.netRequest.responseMessage isNegotiateMessage]) {	
		[self acceptRequestNegotiator];	
	}

	[super queueReadMessage];
}

/*
 
 socket did write data
 
 */
-(void) onSocket:(MGSAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	@try{
		// super will queue read message and change status to kMGSStatusReadingMessageHeaderPrefix
		[super onSocket:sock didWriteDataWithTag:tag];
		
		switch (self.netRequest.status) {
				
			// if awaiting header then write has completed
			case kMGSStatusReadingMessageHeaderPrefix:
				
				/*
				 
				 generate request list
				 
				 */
				/*
				MGSNetRequest *nextRequest = [MGSNetRequest requestWithConnectedSocket:self.netRequest.netSocket];
				nextRequest.prevRequest = self.netRequest;
				self.netRequest.nextRequest = nextRequest;
				self.netRequest = nextRequest;
				*/
				
				// reset the request messages as me way receive more requests on this connection
				[self.netRequest resetMessages];				
				return;
		
			default:
				break;
		}
	}
	@catch (NSException *e) {
		
		[MGSError clientCode:MGSErrorCodeServerException reason:[e description]];
		
		if ([self isConnected]) {
			[self disconnect];
		}
	}	
}

/*
 
 on socket will connect
 
 */
-(BOOL)onSocketWillConnect:(MGSAsyncSocket *)sock
{
	#pragma unused(sock)
	
	return YES;
	
	/* SSL is now negotiated
	 
	if (_enableSSLSecurity) {
		return [self startSecurity];
	} else {
		MLog(DEBUGLOG, @"SERVER SSL: disabled");
		return YES;
	}
	
	 */
}

#pragma mark -
#pragma mark Security
/*
 
 - startSecurity
 
 */
- (BOOL)startSecurity
{
	MLog(DEBUGLOG, @"SERVER SSL: requested");
	
	static NSDictionary *sslProperties = nil;
	
	if (!sslProperties) {
		
		// get SSL identity
		CFArrayRef ca = [MGSSecurity sslCertificatesArray];
		if (!ca) {
			MLogInfo(@"SERVER SSL: could not retrieve required identity");
			return NO;
		}
		

		/*
		 
		 Note:
		 
		 The SSL server connection request fails with   code -9845 the operation couldn't be completed when using 
		 [MGSSecurity setUseDefaultIdentity:YES]
		 
		*/
		sslProperties = [NSDictionary dictionaryWithObjectsAndKeys:
							   (NSString *)kCFStreamSocketSecurityLevelNegotiatedSSL, kCFStreamSSLLevel,
							   kCFBooleanTrue, kCFStreamSSLAllowsExpiredCertificates,
							   kCFBooleanTrue, kCFStreamSSLAllowsExpiredRoots,
							   kCFBooleanTrue, kCFStreamSSLAllowsAnyRoot,
							   kCFBooleanFalse, kCFStreamSSLValidatesCertificateChain,
							   kCFNull, kCFStreamSSLPeerName,
							   ca, kCFStreamSSLCertificates,
							   kCFBooleanTrue, kCFStreamSSLIsServer,
							   nil];
	}
	
	[self startTLS:sslProperties];

	return YES;
	
}
/*
 
 send response
 
 */
- (void)sendResponse
{
	if ([self.netRequest.responseMessage isNegotiateMessage]) {
	
		// security may be mandatory for all tasks
		if (_enableSSLSecurity && ![self isConnectedToLocalHost]) {
			MGSNetNegotiator *negotiator = [self.netRequest.responseMessage negotiator];
			
			if (!negotiator.TLSSecurityRequested) {
				[negotiator setSecurityType:MGSNetMessageNegotiateSecurityTLS];
				[self.netRequest.responseMessage applyNegotiator:negotiator];
			}
		}
	}
	
	[self queueSendMessage]; // raises on error

	//
	// log send request
	// 
	NSString *origin = [self.netRequest.requestMessage messageOriginString];
	MLogDebug(@"Server sending response to: %@\n message: %@", origin, [self.netRequest.responseMessage messageDict]);
	
}

/*
 
 - sendResponseChunk:
 
 */
- (void)sendResponseChunk:(NSData *)data
{
    NSAssert(self.socket, @"socket is nil");
	NSAssert(self.netRequest, @"net request is nil");
	
    // chunked data must have been flagged in the header
    MGSNetMessage *netMessage = [self messageToBeWritten];
    if (![netMessage.header.attachmentTransferEncoding isEqualToString:MGSNetHeaderAttachmentTransferEncodingChunked]) {
        [NSException raise:MGSNetSocketException format:@"Request status does not permit sending chunked data."];
    }
    
    // a chunk is only valid when sending attachments 
	//if (self.netRequest.status != kMGSStatusSendingMessageAttachments) {
	//	[NSException raise:MGSNetSocketException format:@"Request status does not permit sending chunked data."];
	//}
	   
    // build the chunk.
    NSMutableData *chunk = [NSMutableData dataWithCapacity:[data length] + 30];
    NSString *dataLength = [NSString stringWithFormat:@"%X%@", [data length], MGSNetHeaderTerminator];
    [chunk appendData:[dataLength dataUsingEncoding:NSUTF8StringEncoding]];
    [chunk appendData:data];
    [chunk appendData:[MGSNetHeaderTerminator dataUsingEncoding:NSUTF8StringEncoding]];
    
    long tag = kMGSSocketWriteAttachmentChunk;
    
    // zero length chunk signals the end of the data stream
    if ([data length] == 0) {
        tag = kMGSSocketWriteAttachmentLastChunk;
    }
    
	// send the chunk
	[self.socket writeData:chunk withTimeout:self.netRequest.writeTimeout tag:tag];
}
@end

@implementation MGSNetServerSocket(Private)


@end

