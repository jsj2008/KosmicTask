//
//  MGSServerRequestManager.m
//  Mother
//
//  Created by Jonathan on 04/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSServerScriptRequest.h"
#import "MGSServerRequestManager.h"
#import "MGSServerNetRequest.h"
#import "MGSNetMessage.h"
#import "MGSAsyncSocket.h"
#import "MGSScriptPlist.h"
#import "MGSError.h"
#import "MGSServerPreferencesRequest.h"
#import "MGSLanguagePluginController.h"
#import "mlog.h"
#import "MGSNetNegotiator.h"
#import "MGSPath.h"

static MGSServerRequestManager *_sharedController = nil;

// class extension
@interface MGSServerRequestManager ()
- (BOOL)concludeRequest:(MGSServerNetRequest *)netRequest;
- (void)sendErrorResponse:(MGSServerNetRequest *)netRequest error:(MGSError *)mgsError isScriptCommand:(BOOL)isScriptCommand;
- (BOOL)initialise;
-(void)sendAccessDeniedResponse:(MGSServerNetRequest *)netRequest;
@end

@implementation MGSServerRequestManager

@synthesize initialised = _initialised;

#pragma mark -
#pragma mark Class Methods

/*
 
 shared controller
 
 */
+ (id)sharedController
{
	if (!_sharedController) {
		_sharedController = [[self alloc] init];
	}
	return _sharedController;
}


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
	NSString *pluginsPath = [MGSPath bundlePluginPath];
	
	MLogDebug(@"server plugins path : %@", pluginsPath);
	
	// add additional search paths for Language plugin controller.
	// without this the controller won't find the plugins bundle
	[[MGSLanguagePluginController sharedController] addAdditionalSearchPaths:[NSArray arrayWithObject:pluginsPath]];
	[[MGSLanguagePluginController sharedController] loadAllPlugins];
	
	// initialise the script controller
	_scriptController = [[MGSServerScriptRequest alloc] init];
	if (!_scriptController.initialised) {
		return NO;
	}
		
	return YES;
}

/*
 
 disconnect all requests
 
 */
- (void)disconnectAllRequests
{
	for (MGSServerNetRequest *netRequest in [_netRequests copy]) {
		[netRequest disconnect];
	}
}

#pragma mark -
#pragma mark Instance Methods

/*
 
 request with connected socket
 
 */
- (MGSServerNetRequest *)requestWithConnectedSocket:(MGSNetSocket *)socket
{
	// create request with socket
	MGSServerNetRequest *request = [MGSServerNetRequest requestWithConnectedSocket:socket];
	[request setDelegate: self];
	
	// add to request array
	[self addRequest:request];
	
    // release disposable resources
    [request releaseDisposable];
    
	return request;
}

/*
 
 parse the request message
 
 */
- (void)parseRequestMessage:(MGSServerNetRequest *)netRequest
{	
	NSInteger errorCode = MGSErrorCodeParseRequestMessage;
	
	NSString *error = nil;
	BOOL isScriptCommand = NO;
	id object = nil;
	
	NSAssert(_scriptController, @"no script controller available");	
			
	/*
	 
	 get the mandatory command string
	 
	 */
	object = netRequest.requestMessage.command;
	if (![object isKindOfClass:[NSString class]]) {
		error = NSLocalizedString(@"Bad command class.", @"Error returned by server");
		goto send_error_reply;
	}
	NSString *command = object;
	
    
	//==========================================================
	// 
	// parse negotiator
	//
	//==========================================================
	if ([command isEqual:MGSNetMessageCommandNegotiate]) {
		
		// build response negotiator
		MGSNetNegotiator *requestNegotiator = netRequest.requestMessage.negotiator;
		MGSNetNegotiator *responseNegotiator = [requestNegotiator copy];
		[netRequest.responseMessage applyNegotiator:responseNegotiator];
		[netRequest.responseMessage setCommand:command];
        
        // if we return an error in the negotiator we forestall perhaps having to
        // setup and then teardown TLS
        if ([[netRequest netServerSocket] connectionApproved] == NO) {
            [self sendAccessDeniedResponse:netRequest];
        } else {
            [self sendResponseOnSocket:netRequest wasValid:YES];
        }
        
		return;
	}
    
    // validate if access is allowed.
    // when the socket first connects we screen the IP and flag
    // if the connection is approved.
    //
    // the socket has the option of dropping the connection there and then
    // or setting the connectionApproved flag accordingly.
    //
    if ([[netRequest netServerSocket] connectionApproved] == NO) {
		[netRequest.responseMessage setCommand:command];
        [self sendAccessDeniedResponse:netRequest];
        return;
    }

	//==========================================================
	//
	// parse request command
	//
	//==========================================================
	// heartbeat
    if ([command isEqual:MGSNetMessageCommandHeartbeat]) {
		
		/*
		 
		 Heartbeats are not required to be negotiated
		 
		 */
		
		// send heartbeat reply
		[netRequest.responseMessage setCommand:command];
		[self sendResponseOnSocket:netRequest wasValid:YES];
		
		return;
	}
	
	// parse script
	// get script from message and parse
	else if ([command isEqual:MGSNetMessageCommandParseKosmicTask]) {
		
		isScriptCommand = YES;
		[netRequest.responseMessage setCommand:command];
		
		// pass request message to script controller for execution.
		// do not access net request after this point as the script controller
		// will initiate the reply		
		// 
		// if parseNetRequest returns YES then we may assume that the
		// request is valid and that a reply has or will be generated.
		// No further action is therefore required.
		//
		// if parseNetRequest returns N0 then the request is invalid
		// or an error has occurred during processing.
		// In this case we send an error reply.
		if ([_scriptController parseNetRequest:netRequest] == YES) {
			return;
		}
		
		// fall through to error reply
	} 

	// authenticate
	else if ([command isEqual:MGSNetMessageCommandAuthenticate]) {
		
		// if the request does not authenticate it sends its own reply
		if (![netRequest authenticateWithAutoResponseOnFailure:YES]) {
			return;
		}
		
		// send authenticate reply
		[netRequest.responseMessage setCommand:command];
		[self sendResponseOnSocket:netRequest wasValid:YES];
		
		return;
	}
	
	// unrecognised command
	else {
		error = NSLocalizedString(@"Unrecognised command.", @"Error returned by server");
	}
	
send_error_reply:;
	
	MGSError *mgsError = [MGSError serverCode:errorCode reason:error];
	[self sendErrorResponse:netRequest error:mgsError isScriptCommand:isScriptCommand];
	return;
}

/*
 
 - sendAccessDeniedResponse:
 
 */
-(void)sendAccessDeniedResponse:(MGSServerNetRequest *)netRequest
{
    NSInteger errorCode = MGSErrorCodeServerAccessDenied;
    NSString *error = NSLocalizedString(@"Access denied.", @"Error returned by server");
    MGSError *mgsError = [MGSError serverCode:errorCode reason:error];
    [self sendErrorResponse:netRequest error:mgsError isScriptCommand:NO];
}

/*
 
 send error response
 
 */
- (void)sendErrorResponse:(MGSServerNetRequest *)netRequest error:(MGSError *)mgsError isScriptCommand:(BOOL)isScriptCommand
{
	// we need an error
    if (!mgsError) {
        mgsError = [MGSError serverCode:MGSErrorCodeServerUnknown];
    }

    MGSNetMessage *responseMessage = [netRequest responseMessage];

	// a script command error is inserted under the MGSScriptKeyKosmicTask
    // key
	if (isScriptCommand) {
		
		// validate that the request has a suitable reply
		// and error. if it does not insert a generic error message.
		NSMutableDictionary *messageDict = [responseMessage messageDict];
		NSMutableDictionary *replyDict = nil;
		
		id obj = [messageDict objectForKey:MGSScriptKeyKosmicTask];	
		if ([obj isKindOfClass: [NSDictionary class]]) {
			replyDict = obj;
		} else {
			// insert error into reply script dict
			replyDict = [NSMutableDictionary dictionaryWithCapacity:1];
			[responseMessage setMessageObject:replyDict forKey:MGSScriptKeyKosmicTask];		
		}
		
		// make sure that the error dict is defined
		if ([replyDict objectForKey:MGSScriptKeyNSErrorDict] == nil) {
			[replyDict setObject:[mgsError dictionary] forKey:MGSScriptKeyNSErrorDict];
		}
		
	} else {
        [responseMessage setError:mgsError];
    }
	
	// flag request as invalid in reply and send
	// when the client reads that the request was invalid it
	// does not parse the reply further
	[self sendResponseOnSocket:netRequest wasValid:NO];
	
}

/*
 
 conclude request 
 
 all requests receive this message wether they run to completion or not.
 
 */
- (BOOL)concludeRequest:(MGSServerNetRequest *)netRequest
{
    // terminate any task associated with the task.
    // the request itself will be terminated only if a task
    // is currently associated with the request
	[_scriptController terminateRequest:netRequest];
    
    // terminate
    if (netRequest.status != kMGSStatusTerminated) {
        [self terminateRequest:netRequest];
    }
    
    return YES;
}

/*
 
 send response on socket
 
 */
- (void)sendResponseOnSocket:(MGSServerNetRequest *)request wasValid:(BOOL)valid
{
	@try {
		// flag request validity
		[[request responseMessage] addRequestWasValid:valid];
		
		// send on socket
		[request sendResponseOnSocket];
        
	} @catch (NSException *e) {
		
		[self concludeRequest:request];
		MLogInfo(@"Exception sending response: %@", e);
	}
    
}

#pragma mark -
#pragma mark MGSNetRequestDelegate

/*
 
 - requestDidComplete
 
 */
 
- (void)requestDidComplete:(MGSServerNetRequest *)netRequest
{
  [self concludeRequest:netRequest];
}

/*
 
 authentication failed for request
 
 */
- (void)requestAuthenticationFailed:(MGSServerNetRequest *)netRequest
{
	[self sendResponseOnSocket:netRequest wasValid:NO];
}

/*
 
 - requestTimerExpired
 
 */
- (void)requestTimerExpired:(MGSServerNetRequest *)netRequest
{
    MLogDebug(@"Time out : Terminating request: %@", [netRequest UUID]);
    
    BOOL sendTimeoutResponse = NO;
    
    // can we send a response at this time?
    // NOTE: we can send data on the socket at any time
    // but we don't want to disrupt our request/response sequencing.
    // if we are sending an error reponse though it may be okay as long
    // as the writing end has a read queued.
    //
    // Obviously we cannot send an error response if we are
    // in the midst of sending a standard response.
    if (netRequest.status == kMGSStatusMessageReceived) {
        
        // send a timeout response for certain commands.
        NSString *command = netRequest.requestMessage.command;
        if ([command isEqual:MGSNetMessageCommandParseKosmicTask]) {
            sendTimeoutResponse = YES;
        }        
    }
    
    // when timing out task requests it is better
    // to send a timeout response to the client (if possible) rather than just
    // disconnecting.
    // note that this requires NOT concluding the request immediately
    // but extending the timeout to allow the response to be sent.
    if ((netRequest.timeoutCount == 1) && sendTimeoutResponse) {

        netRequest.timeout = 10;
        [netRequest startRequestTimer];

        MGSError *mgsError = [MGSError serverCode:MGSErrorCodeServerRequestTimeout reason:@"Request has been terminated by the task server."];
        [netRequest.responseMessage setErrorDictionary:[mgsError dictionary]];
        [self sendResponseOnSocket:netRequest wasValid:YES];
    } else {
    
        if (netRequest.timeoutCount > 1) {
#ifdef MGS_LOG_TIMEOUT
            MLogDebug(@"Request timed out. Attempted to send an error response but this timed out too.");
#endif
        }
        
        // conclude our request.
        // this will terminate any tasks associated with the request
        // and may remove the request from the request queue
        [self concludeRequest:netRequest];
    }
    
}
@end


