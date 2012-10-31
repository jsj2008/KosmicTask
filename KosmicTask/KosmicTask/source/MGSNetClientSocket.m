//
//  MGSNetClientSocket.m
//  Mother
//
//  Created by Jonathan on 01/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
//  Uses AsyncSocket for network communication 
//  Note that NSStream might be able to accomplish the same thing
//  Also see NSSocketPort docs.
//  also see http://www.cocoadev.com/index.pl?NSSocketPort
//  see http://www.cocoadev.com/index.pl?NSStream
//
#import "MGSMother.h"
#import "MGSNetClientSocket.h"
#import "MGSClientNetRequest.h"
#import "MGSPreferences.h"
#import "MGSNetMessage.h"
#import "MGSNetHeader.h"
#import "MGSAsyncSocket.h"
#import "MGSNetClient.h"
#import "MGSNetAttachment.h"
#import "MGSNetAttachments.h"
#import "MGSAuthentication.h"
#import "MGSKeyChain.h"
#import "MGSScriptPlist.h"
#import "MGSNetNegotiator.h"
#import <Foundation/NSThread.h>

@interface MGSNetClientSocket(Socket)
- (void)onSocket:(MGSAsyncSocket *)sock willDisconnectWithError:(NSError *)err;
- (void)onSocketDidDisconnect:(MGSAsyncSocket *)sock;
- (void)onSocket:(MGSAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port;
- (void)onSocket:(MGSAsyncSocket *)sock didReadData:(NSData*)data withTag:(long)t;
@end

@interface MGSNetClientSocket(Private)
- (void)delegateReplyWithErrors:(MGSError *)errors;
@end

@implementation MGSNetClientSocket


/*
 
 init
 
 */
- (id)init
{
	if ((self = [super initWithMode:NETSOCKET_CLIENT])) {
		useSSL = YES;
	}
	
	return self;
}

/*
 
 connect to host on specified port
 note that data can be queued to be sent before the connection completes
 
 */
- (BOOL)connectToHost:(NSString*)host onPort:(UInt16)port forRequest:(MGSClientNetRequest *)netRequest
{
    
	NSAssert(netRequest, @"net request is nil");
	self.netRequest = netRequest;

	clientServiceName = netRequest.netClient.serviceName;
	useSSL = [netRequest.netClient useSSL];
	
	@try
	{
		NSError *err = nil;
		
		self.socket = [[MGSAsyncSocket alloc] initWithDelegate:self];
		
		// Advanced options - enable the socket to contine operations even during modal dialogs, and menu browsing
		if (NO) {
			[self.socket setRunLoopModes:[NSArray arrayWithObjects:NSRunLoopCommonModes, NSModalPanelRunLoopMode, NSEventTrackingRunLoopMode, nil]];
		}
        
		// connect to host with timeout.
        // without the timeout we never get any response from the socket if the connection fails.
        // this call corresponds to the connect() call.
		if ([self.socket connectToHost:host onPort:port withTimeout:10 error:&err])
		{
			// actual connect may take time to occur
			// reads and writes can be queued before the connect completes
			netRequest.status = kMGSStatusConnecting;
			
			MLog(DEBUGLOG, @"Client connecting to host: %@ port: %u. (URL: %@)", host, port, netRequest.netClient.hostName);
			return YES;
		}
		else
		{
			netRequest.status = kMGSStatusCannotConnect;
			MLog(RELEASELOG, @"Client couldn't connect to host: %@ port: %u (%@).", host, port, err);
			
			// another error will be generated by the request handler when the connect fails
			[MGSError clientCode:MGSErrorCodeSocketConnectError userInfo:[err userInfo]];	
		}
	}
	@catch (NSException *exception)
	{
		netRequest.status = kMGSStatusExceptionOnConnecting;
		MLog(RELEASELOG, @"%@", [exception reason]);
	}
	
	return NO;
}

/*
 
 send request
 
 */
- (void)sendRequest
{
	MGSNetMessage *message = self.netRequest.requestMessage;
	NSDictionary *newAuthDict = nil;
	NSDictionary *authDict = nil;
	
	// negotiate request cannot be authenticated
	if (![message isNegotiateMessage]) {
		
		//
		// complete authentication data.
		//
		// to avoid the app having to cache the password in memory the default auth dictionary 
		// does not include the password, only the username.
		// the password is retrieved from the keychain and added to the existing auth dict.
		//
		authDict = [message authenticationDictionary];
		if (authDict) {
			
			// get authentication password from the keychain and create new auth dict.
            // regardless of wether the keychain is stored permantently in the keychain or not
            // we retrieve the password from the session service/
			newAuthDict = [[MGSAuthentication sharedController] 
										authDictionaryforSessionService:clientServiceName
										  withDictionary:authDict];
			if (newAuthDict) {
				[message setAuthenticationDictionary:newAuthDict];
			} else {
				[NSException raise:MGSNetSocketSecurityException format:@"Cannot retrieve authentication dictionary from keychain"];
			}
		}
	}
	
	// queue message.
	// this will encode the request message dict into an NSData instance
	[self queueSendMessage]; // raises on error

	// replace the auth dict.
	// don't want the password to remain in the request message
	if (newAuthDict && authDict) {
		[message setAuthenticationDictionary:authDict];
	}
	
	//
	// log send request
	// 
	MLogDebug(@"Client sending request to: %@\n message: %@", clientServiceName, [self.netRequest.requestMessage messageDict]);
}


/* 
 
 on read bad data with errors
 
 */
- (void)onReadBadDataWithErrors:(NSString *)errors
{
	[super onReadBadDataWithErrors:errors];
	
	MGSError *mgsError = [MGSError clientCode:MGSErrorCodeMessageBadData reason:errors];
	
	// message delegate
	[self delegateReplyWithErrors:mgsError];
}

@end

@implementation MGSNetClientSocket(Private)

/*
 
 delegate reply with errors
 
 */
- (void)delegateReplyWithErrors:(MGSError *)errors
{
	if (self.netRequest.delegate &&
		[self.netRequest.delegate respondsToSelector:@selector(requestDidComplete:)]) {
		
		if (errors) {
			self.netRequest.error = errors;
		}
		
		[(NSObject *)(self.netRequest.delegate) performSelectorOnMainThread:@selector(requestDidComplete:)
												   withObject:self.netRequest 
												waitUntilDone:YES];	// wait until done as we may swap the request out for this socket
	}
	
}



@end


@implementation MGSNetClientSocket(Socket)
#pragma mark -
#pragma mark AsyncSocket Delegate Methods


/*
 
 on socket will disconnect
 
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
	
	if (err != nil) {
		NSInteger errorCode;
		
		//NSString *error = [NSString stringWithFormat:@"socket disconnect with error domain %@, code %d (%@).",
		//				   [err domain], [err code], [err localizedDescription]];
		
		switch ([err code]) {
			case AsyncSocketCanceledError:					// onSocketWillConnect: returned NO.
				errorCode = MGSErrorCodeSocketCanceledError;
				break;
				
			case AsyncSocketReadTimeoutError:
				errorCode = MGSErrorCodeSocketReadTimeoutError;
				break;
				
			case AsyncSocketWriteTimeoutError:
				errorCode = MGSErrorCodeSocketWriteTimeoutError;
				break;
			
			case AsyncSocketCFSocketError:
			default:
				errorCode = MGSErrorCodeSocketError;
				break;
				
		}
		
		MGSError *mgsError = [MGSError domain:MGSErrorDomainMotherNetwork code:errorCode];
		
		[self delegateReplyWithErrors:mgsError];
		//MLog(DEBUGLOG, @"%@", error);
	} else {
		//MLog(DEBUGLOG, @"Client socket will disconnect. No error.");
		
		// The final desired status of our request is kMGSStatusReplyPayloadReceived.
		// If we disconnect before this state has been reached then our request has failed.
		if (self.netRequest.status != kMGSStatusMessageReceived) {
			MGSError *mgsError = [MGSError domain:MGSErrorDomainMotherNetwork code:MGSErrorCodeSocketDisconnectError];
			[self delegateReplyWithErrors:mgsError];			
		}
	}
}


/*
 
 On socket did disconnect
 
 Normally, this is the place to release the socket and perform the appropriate
 housekeeping and notification. 
 
 */
-(void) onSocketDidDisconnect:(MGSAsyncSocket *)sock
{
	#pragma unused(sock)
	
	MLog(DEBUGLOG, @"Client socket disconnected.");
	
	// mark request as disconnected
	[self.netRequest socketDidDisconnect];
	
	if ([self delegate] && 
		[[self delegate] respondsToSelector:@selector(netSocketDisconnect:)]) {
		
        // we want to wait for completion here so that disconnect
        // processing is allowed to complete.
        // see: http://projects.mugginsoft.net/view.php?id=1131
		[(id)[self delegate] performSelectorOnMainThread:@selector(netSocketDisconnect:) 
										  withObject:self
									   waitUntilDone:YES];
	}
}

/*
 
 socket did write data
 
 */
-(void) onSocket:(MGSAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	@try {

		[super onSocket:sock didWriteDataWithTag:tag];

		switch (self.netRequest.status) {
				
			// if awaiting header then write has completed
			case kMGSStatusReadingMessageHeaderPrefix:;
                
                //
                // log request sent with script command
                //
				// TODO: add a preference for this
				if (NO) {
                    NSDictionary *appDict = [[self.netRequest.requestMessage messageDict] objectForKey:MGSScriptKeyKosmicTask];	
                    NSString *command = [appDict objectForKey:MGSScriptKeyCommand];
                    if (!command) {
                        command = @"*";
                    }
				
					MLogInfo(@"Sent command: %@ to %@ in request %@", 
						 command, 
						 clientServiceName, 
						 [self.netRequest UUID]);
				}
				
                /*
                 
                 If we have a auxiliary requests then send them now.
                 We wait for the main request to be sent to ensure that the
                 auxiliary requests can refer to the parent request message UUID if required.
                 We need to make sure that the server has received the parent UUID before
                 another request references it.
                 
                 We only want to do this once!
                 
                 */
                if (self.netRequest.lastStatus != kMGSStatusReadingMessageHeaderPrefix) {
                    [(MGSClientNetRequest *)self.netRequest sendChildRequests];
                } 
				return;
				
			default:
				break;
		}

	}
	@catch (NSException *e) {
		
		[MGSError clientCode:MGSErrorCodeClientException reason:[e description]];
		
		if ([self isConnected]) {
			[self disconnect];
		}
	}
}
/*
 
 socket will connect
 
 */
-(BOOL)onSocketWillConnect:(MGSAsyncSocket *)sock
{
	#pragma unused(sock)
	
	return YES;
	
	// use SSL.
	// if the server uses SSL so will the local client.
	/* SSL is now negotiated.
	if (YES == useSSL) {
		return [self startSecurity];
	} else {
		MLog(DEBUGLOG, @"CLIENT: ssl disabled");
		return YES;
	}
	 */
}

#pragma mark -
#pragma mark Negotiator

/*
 
 - readRequestNegotiator
 
 */
- (BOOL)acceptRequestNegotiator
{
	if ([self.netRequest.requestMessage isNegotiateMessage]) {
		MGSNetNegotiator *requestNegotiator = [self.netRequest.requestMessage negotiator];
		MGSNetNegotiator *responseNegotiator = [self.netRequest.responseMessage negotiator];
		
		// if TLS security was requested and not granted then the connection is invalid
		if ([requestNegotiator TLSSecurityRequested] && ![responseNegotiator TLSSecurityRequested]) {
			[MGSError domain:MGSErrorDomainMotherNetwork code:MGSErrorCodeRequestedSecurityNotGranted];
			return NO;
		}
	}
	
	return [super acceptRequestNegotiator];
}

#pragma mark -
#pragma mark Security
/*
 
 - startSecurity
 
 */
- (BOOL)startSecurity
{
	MLog(DEBUGLOG, @"CLIENT: ssl requested");
	
	//==================================
	// set up client side SSL
	// code from David Riggle at BusyMac
	//==================================
	NSDictionary *sslProperties = [NSDictionary dictionaryWithObjectsAndKeys:
								   (NSString *)kCFStreamSocketSecurityLevelTLSv1, kCFStreamSSLLevel,
								   kCFBooleanTrue, kCFStreamSSLAllowsExpiredCertificates,
								   kCFBooleanTrue, kCFStreamSSLAllowsExpiredRoots,
								   kCFBooleanTrue, kCFStreamSSLAllowsAnyRoot,
								   kCFBooleanFalse, kCFStreamSSLValidatesCertificateChain,
								   kCFNull, kCFStreamSSLPeerName,
								   kCFBooleanFalse, kCFStreamSSLIsServer,
								   nil];	
	
#define USE_AS_START_TLS
	
#ifdef USE_AS_START_TLS
	[self startTLS:sslProperties];
	
	return YES;
#else
	if (!CFReadStreamSetProperty([sock getCFReadStream], kCFStreamPropertySSLSettings, sslProperties)) goto errorExit;
	if (!CFWriteStreamSetProperty([sock getCFWriteStream], kCFStreamPropertySSLSettings, sslProperties)) goto errorExit;
	
	return YES;
	
errorExit:;
	[MGSError clientCode:MGSErrorCodeSocketSSLPropertyError];
	return NO;
#endif
	
}

/*
 
 socket did connect to host
 
 */
-(void) onSocket:(MGSAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
	#pragma unused(sock)
	#pragma unused(host)
	#pragma unused(port)
	
	// be careful here.
	// this message may not actually be received until after
	// other operations have been queued that may affect the status
	if (self.netRequest.status == kMGSStatusConnecting) {
		self.netRequest.status = kMGSStatusConnected;
	}
}

/*
 
 on socket did read data
 
 */
-(void) onSocket:(MGSAsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag
{
	MGSError *mgsError = nil;

	@try {
		
		[super onSocket:sock didReadData:data withTag:tag];

		switch (self.netRequest.status) {
				
			// messsage received
			case kMGSStatusMessageReceived:

				// log the client response from remote hosts only?
				if (1) {
					MLog(DEBUGLOG, @"Client received response: %@", [self.netRequest.responseMessage messageDict]);
				} else {
					MLog(DEBUGLOG, @"Client received response: %llu bytes", self.netRequest.responseMessage.totalBytes);
				}
				
                MGSClientNetRequest *request = (MGSClientNetRequest *)self.netRequest;

				// DISCONNECT if request does not validate
				BOOL disconnect = ![request validateOnCompletion:&mgsError];
                
                if (disconnect) {
                    MLogInfo(@"ABNORMAL disconnect. The next request is missing.");
                }
                
				// DISCONNECT if no more requests in queue
 				if (request.nextRequest == nil) {
					disconnect = YES;
#ifdef MGS_DEBUG
                    if (disconnect) {
                        MLogDebug(@"NORMAL disconnect. No next request found.");
                    }
#endif
				}
				
				// DISCONNECT if there is an error in the negotiator response 
				if (request.responseMessage.negotiator &&
					request.responseMessage.errorDictionary) {
					disconnect = YES;
                    
#ifdef MGS_DEBUG
                    if (disconnect) {
                        MLogDebug(@"NEGOTIATOR ERROR disconnect. Error returned in negotiator.");
                    }
#endif
                    
				}
				
                // if disconnect not queued
				if (!disconnect) {
                    
                    // process the negotiator
                    if (request.responseMessage.negotiator) {
                        if (![self acceptRequestNegotiator]) {
                            disconnect = YES;
#ifdef MGS_DEBUG
                            MLogDebug(@"NEGOTIATOR ACCEPT disconnect. Negotiator was not accepted.");
#endif
                        }
                    }
				}
				
                //
				// DISCONNECT
                //
                // Normally socket disconnection occurs here.
                //
				if (disconnect) {
					[self disconnect];	
				}
				
				// message delegate
				[self delegateReplyWithErrors:mgsError];
				
				// DISCONNECT if error in request. this error may only become
				// apparent after the delegate has processed the request.
				if ([self isConnected] && request.error) {
					[self disconnect];	

#ifdef MGS_DEBUG
                        MLogDebug(@"REQUEST ERROR disconnect. Error returned in reponse.");
#endif
				
                }
				
				// if still connected send the next queued request
				if ([self isConnected]) {
					
					// get the next request to send
					MGSClientNetRequest *nextRequest = [request nextQueuedRequestToSend];
					NSAssert(nextRequest == self.netRequest, @"unexpected request");
					
					// send the next request on the same socket connection 
					if (nextRequest) {
						[self sendRequest];	// raises on error
					} else {
                        
                        // We shouldn't expect to disconnect here
                        MLogInfo(@"ABNORMAL disconnect. The next request is missing.");
						[self disconnect];
					}
				}
				
				
				break; 
				
			default:
				break;
				
		}	
	}
	@catch (NSException *e) {
		
		if ([self isConnected]) {
			[self disconnect];
		}

		// message delegate
		mgsError = [MGSError clientCode:MGSErrorCodeClientException reason:[e description]];
		[self delegateReplyWithErrors:mgsError];

	}
}

@end
