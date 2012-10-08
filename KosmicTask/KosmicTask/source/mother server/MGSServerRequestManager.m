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

@interface MGSServerRequestManager (Private)
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
	// parse request command
	//
	//==========================================================
	if ([command isEqual:MGSNetMessageCommandNegotiate]) {
		
		// build response negotiator
		MGSNetNegotiator *requestNegotiator = netRequest.requestMessage.negotiator;
		MGSNetNegotiator *responseNegotiator = [requestNegotiator copy];
		[netRequest.responseMessage applyNegotiator:responseNegotiator];
	
		// send reply
		[netRequest.responseMessage setCommand:command];
		[self sendResponseOnSocket:netRequest wasValid:YES];

		return;
		
	// heartbeat
	} else if ([command isEqual:MGSNetMessageCommandHeartbeat]) {
		
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
		// No further action is therfore required.
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
 
 send error response 
 
 */
- (void)sendErrorResponse:(MGSServerNetRequest *)netRequest error:(MGSError *)mgsError isScriptCommand:(BOOL)isScriptCommand
{
	
	// validate script error command reply
	if (isScriptCommand) {
		
		// validate that the request has a suitable reply
		// and error. if it does not insert a generic error message.
		MGSNetMessage *responseMessage = [netRequest responseMessage];
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
			if (!mgsError) {
				mgsError = [MGSError serverCode:MGSErrorCodeServerUnknown];
			}
			[replyDict setObject:[mgsError dictionary] forKey:MGSScriptKeyNSErrorDict];
		}
		
	}
	
	// flag request as invalid in reply and send
	// when the client reads that the request was invalid it
	// does not parse the reply further
	[self sendResponseOnSocket:netRequest wasValid:NO];
	
}

/*
 
 authentication failed for request
 
 */
- (void)authenticationFailed:(MGSServerNetRequest *)netRequest
{
	[self sendResponseOnSocket:netRequest wasValid:NO];
}

/*
 
 remove request
 
 */
- (void)removeRequest:(MGSServerNetRequest *)netRequest
{
	// remove the request
	[super removeRequest:netRequest];
    
}

/*
 
 conclude request 
 
 all requests receive this message wether they run to completion or not.
 
 */
- (BOOL)concludeRequest:(MGSServerNetRequest *)netRequest
{
	return [_scriptController concludeNetRequest:netRequest];
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
		
		[[request netSocket] disconnect];
		MLogInfo(@"%@", e);
	}
    
}

@end

@implementation MGSServerRequestManager (Private)


@end

