//
//  MGSClientRequestManager.m
//  Mother
//
//  Created by Jonathan on 30/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSClientRequestManager.h"
#import "MGSNetRequest.h"
#import "MGSNetClient.h"
#import "MGSClientTaskController.h"
#import "MGSNetMessage.h"
#import "MGSNetAttachments.h"
#import "MGSClientScriptManager.h"
#import "MGSScriptPlist.h"
#import "MGSTaskSpecifier.h"
#import "MGSScript.h"
#import "MGSNetRequestPayload.h"
#import "MGSError.h"
#import "MGSAuthentication.h"
#import "MGSAuthenticateWindowController.h"
#import "MGSNetNegotiator.h"
#import "MGSNetMessage+KosmicTask.h"

static MGSClientRequestManager *_sharedController = nil;

@interface MGSClientRequestManager(Private)
- (MGSNetRequest *)createRequestForClient:(MGSNetClient *)netClient withOwner:(id <MGSNetRequestOwner>)owner withCommand:(NSString *)command withScriptDict:(NSMutableDictionary *)dict;
- (MGSNetRequest *)createRequestForClient:(MGSNetClient *)netClient withOwner:(id <MGSNetRequestOwner>)owner withScriptDict:(NSMutableDictionary *)dict;
- (MGSNetRequest *)createRequestForClient:(MGSNetClient *)netClient scriptCommand:(NSString *)scriptCommand withOwner:(id <MGSNetRequestOwner>)owner;
- (MGSNetRequest *)createRequestForClient:(MGSNetClient *)netClient command:(NSString *)command withOwner:(id <MGSNetRequestOwner>)owner;
- (MGSNetRequest *)createRequestForClient:(MGSNetClient *)netClient withOwner:(id <MGSNetRequestOwner>)owner 
							  withCommand:(NSString *)command 
								 withDict:(NSMutableDictionary *)dict forKey:(NSString *)key;
- (void)parseReplyMessage:(MGSNetRequest *)request;
- (void)parseScriptRequestReply:(MGSNetRequest *)netRequest;
- (void)netRequestReplyOnClient:(MGSNetRequest *)netRequest;
@end

@implementation MGSClientRequestManager

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

/*
 
 init
 
 */

- (id)init
{
	if ((self = [super init])) {
	}
	
	return self;
}

/*
 
 request execute a task
 
 */
- (void)requestExecuteTask:(MGSTaskSpecifier *)task withOwner:(id <MGSNetRequestOwner>)owner
{
	MGSError *mgsError = nil;

	// create a dictionary requesting script execution
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
	
	// command is execute script
	[dict setObject:MGSScriptCommandExecuteScript forKey:MGSScriptKeyCommand];
	
	// add the _taskSpecifier's script dict which will include
	// values for parameters
	// add deep copy of script dict
	MGSScript *script = [[task script] mutableDeepCopy];
	
	// if script is scheduled for save then a complete representation
	// must be sent as it will not exist on disk.
	if (![script scheduleSave]) {
		if (![script conformToRepresentation:MGSScriptRepresentationExecute]) {
			mgsError = [MGSError clientCode:MGSErrorCodeInvalidScriptRepresentation];
		}
	}
	
	NSMutableDictionary *scripDict = [script dict];
	[dict setObject:scripDict forKey:MGSScriptKeyScript];

	// execute on the task's client
	MGSNetClient *netClient = [task netClient];
	MGSNetRequest *netRequest = [self createRequestForClient:netClient withOwner:owner withScriptDict:dict];
	
	// add attachments to the request message
	netRequest.requestMessage.attachments = [script attachmentsWithError:&mgsError];
	
	// check for errors
	if (mgsError) {
		
		netRequest.error = mgsError;
		[netRequest sendErrorToOwner];
					
		return;
	}
	
	//
	// add licence data to the request.
	// this will only be added to execute requests.
	//
	// server will cache the licence validation data
	// for this client so in theory it doesn't need to be sent
	// for every request.
	// 
	if (netClient.sendExecuteValidation) {
		//
		// add app licence data
		//
		[netRequest.requestMessage addAppData];
	}
	
	task.netRequest = netRequest;
	
	// we want the owner to receive status updates as the request proceeds.
	netRequest.sendUpdatesToOwner = YES;
	
	// send the request 
	[self sendRequestOnClient:netRequest];
}

/*
 
 request compiled script source for task
 
 */
- (void)requestCompiledScriptSourceForTask:(MGSTaskSpecifier *)task withOwner:(id <MGSNetRequestOwner>)owner
{
	NSAssert(task, @"task is nil");
	
	// create a dictionary 
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
	
	// command is get script compiled source
	[dict setObject:MGSScriptCommandGetScriptUUIDCompiledSource forKey:MGSScriptKeyCommand];
	
	// add script UUID
	NSString *UUID = [[[task script] UUID] copy];
	NSArray *array = [NSArray arrayWithObject:UUID];
	[dict setObject:array forKey:MGSScriptKeyCommandParamaters];
	
	// execute on the task's client
	MGSNetClient *netClient = [task netClient];
	
	// create request
	task.netRequest = [self createRequestForClient:netClient withOwner:owner withScriptDict:dict];
	
	// send the request 
	[self sendRequestOnClient:task.netRequest];
}

/*
 
 request build task
 
 */
- (void)requestBuildTask:(MGSTaskSpecifier *)task withOwner:(id <MGSNetRequestOwner>)owner
{
	NSAssert(task, @"task is nil");

	MGSError *mgsError = nil;
	
	// create a dictionary requesting build
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
	[dict setObject:MGSScriptCommandBuildScript forKey:MGSScriptKeyCommand];
	
	// get a copy of the script object
	MGSScript *scriptCopy = [[task script] mutableDeepCopy];
	if (![scriptCopy conformToRepresentation:MGSScriptRepresentationBuild]) {
		mgsError = [MGSError clientCode:MGSErrorCodeInvalidScriptRepresentation];
	}
	
	// add deep copy of script dict
	NSMutableDictionary *scriptDict = [scriptCopy dict];
	[dict setObject:scriptDict forKey:MGSScriptKeyScript];
	
	// build on the task's client
	MGSNetClient *netClient = [task netClient];
	
	// create request
	MGSNetRequest *netRequest = [self createRequestForClient:netClient withOwner:owner withScriptDict:dict];

	// check for errors
	if (mgsError) {
		
		netRequest.error = mgsError;
		[netRequest sendErrorToOwner];
		
		return;
	}
	
	task.netRequest = netRequest;
	
	// send the request 
	[self sendRequestOnClient:task.netRequest];
}

/*
 
 request script dict for client
 
 */
- (void)requestScriptDictForNetClient:(MGSNetClient *)netClient isPublished:(BOOL)published withOwner:(id <MGSNetRequestOwner>)owner
{
	// retrieve either all scripts or published scripts
	NSString *command = (published ? MGSScriptCommandListPublished : MGSScriptCommandListAll);
	MGSNetRequest *netRequest = [self createRequestForClient:netClient scriptCommand:command withOwner:owner];

	// send the request 
	[self sendRequestOnClient:netRequest];
}

/*
 
 request heartbeat
 
 */
- (void)requestHeartbeatForNetClient:(MGSNetClient *)netClient withOwner:(id <MGSNetRequestOwner>)owner
{
	MGSNetRequest *netRequest = [self createRequestForClient:netClient command:MGSNetMessageCommandHeartbeat withOwner:owner];

	// send the request 
	[self sendRequestOnClient:netRequest];
}

/*
 
 request net client authentication
 
 */
- (MGSNetRequest *)requestAuthenticationForNetClient:(MGSNetClient *)netClient withOwner:(id <MGSNetRequestOwner>)owner
{
	MGSNetRequest *netRequest =  [self createRequestForClient:netClient command:MGSNetMessageCommandAuthenticate withOwner:owner];
	
	// send the request 
	[self sendRequestOnClient:netRequest];
	
	return netRequest;
}

/*
 
 request net client search
 
 */
- (MGSNetRequest *)requestSearchNetClient:(MGSNetClient *)netClient searchDict:(NSDictionary *)searchDict withOwner:(id <MGSNetRequestOwner>)owner
{
	// create a dictionary requesting script termination
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
	[dict setObject:MGSScriptCommandSearch forKey:MGSScriptKeyCommand];
	
	// copy our dict
	searchDict = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject: searchDict]];
	
	// set command dictionary
	[dict setObject:searchDict forKey:MGSScriptKeyCommandDictionary];
	
	// create request
	MGSNetRequest *netRequest = [self createRequestForClient:netClient withOwner:owner withScriptDict:dict];
	
	// send the request 
	[self sendRequestOnClient:netRequest];
	
	return netRequest;
}

/*
 
 request terminate an task
 
 */
- (void)requestTerminateTask:(MGSTaskSpecifier *)task withOwner:(id <MGSNetRequestOwner>)owner
{
	// create a dictionary requesting script termination
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
	[dict setObject:MGSScriptCommandTerminateMessageUUID forKey:MGSScriptKeyCommand];
	
	// create array of command parameters
	NSString *terminateUUID = [task.netRequest.requestMessage messageUUID];
	NSArray *array = [NSArray arrayWithObject:terminateUUID];
	[dict setObject:array forKey:MGSScriptKeyCommandParamaters];
	
	// execute on the task's client
	MGSNetClient *netClient = [task netClient];
	
	// create request
	MGSNetRequest *netRequest = [self createRequestForClient:netClient withOwner:owner withScriptDict:dict];
	
	// send the request 
	[self sendRequestOnClient:netRequest];
}

/*
 
 request suspend an task
 
 */
- (void)requestSuspendTask:(MGSTaskSpecifier *)task withOwner:(id <MGSNetRequestOwner>)owner
{
	// create a dictionary requesting script suspend
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
	[dict setObject:MGSScriptCommandSuspendMessageUUID forKey:MGSScriptKeyCommand];
	
	// create array of command parameters
	NSString *terminateUUID = [task.netRequest.requestMessage messageUUID];
	NSArray *array = [NSArray arrayWithObject:terminateUUID];
	[dict setObject:array forKey:MGSScriptKeyCommandParamaters];
	
	// execute on the task's client
	MGSNetClient *netClient = [task netClient];
	
	// create request.
	// note that we do not overrwite the task net request
	MGSNetRequest *netRequest = [self createRequestForClient:netClient withOwner:owner withScriptDict:dict];
	
	// send the request 
	[self sendRequestOnClient:netRequest];
}

/*
 
 request resume an task
 
 */
- (void)requestResumeTask:(MGSTaskSpecifier *)task withOwner:(id <MGSNetRequestOwner>)owner
{
	// create a dictionary requesting script resume
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
	[dict setObject:MGSScriptCommandResumeMessageUUID forKey:MGSScriptKeyCommand];
	
	// create array of command parameters
	NSString *terminateUUID = [task.netRequest.requestMessage messageUUID];
	NSArray *array = [NSArray arrayWithObject:terminateUUID];
	[dict setObject:array forKey:MGSScriptKeyCommandParamaters];
	
	// execute on the task's client
	MGSNetClient *netClient = [task netClient];
	
	// create request
	MGSNetRequest *netRequest = [self createRequestForClient:netClient withOwner:owner withScriptDict:dict];

	// send the request 
	[self sendRequestOnClient:netRequest];
}

//=============================================================
//
// request save changes for client with option to republish.
//
// this message is sent:
// 1. to inform server of scripts that are to be deleted
// 2. to inform server of scripts to be published/unpublished
//
// These changes are batched to reduce server refreshes.
//
//============================================================
- (void)requestSaveConfigurationChangesForNetClient:(MGSNetClient *)netClient withOwner:(id <MGSNetRequestOwner>)owner republish:(BOOL)republish
{
	#pragma unused(republish)
	
	// create a dictionary to hold edited script dictionary
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
	
	// command is save changes and publish
	[dict setObject:MGSScriptCommandSaveChangesAndPublish forKey:MGSScriptKeyCommand];
	
	// add the change script dictionary.
	// this will contains scripts scheduled for publishing or deletion
	id scriptDict= [[netClient.taskController scriptManager] changeDictionaryCopy];
	[dict setObject:scriptDict forKey:MGSScriptKeyScript];

	// accept configuration changes
	[netClient.taskController acceptConfigurationChanges];

	// create request
	MGSNetRequest *netRequest = [self createRequestForClient:netClient withOwner:owner withScriptDict:dict];
	
	// send the request 
	[self sendRequestOnClient:netRequest];
}

//=============================================================
//
// request save task
//
// this message is sent:
// 1. to inform server of new script
// 2. to inform server of edits to existing scripts
//
//============================================================
- (MGSNetRequest *)requestSaveTask:(MGSTaskSpecifier *)task withOwner:(id <MGSNetRequestOwner>)owner
{
	MGSNetClient *netClient = task.netClient;
	
	// create a dictionary to hold edited script dictionary
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
	
	// command is save edits
	[dict setObject:MGSScriptCommandSaveEdits forKey:MGSScriptKeyCommand];
	
	// add the edited script dictionary
	// this will contain a copy of the edited items
	id scriptDict= [[netClient.taskController scriptManager] editDictionaryForScript:[task script]];
	if (!scriptDict) {
		
		// if no edits to send then don't send request
		return nil;
	}
	
	[dict setObject:scriptDict forKey:MGSScriptKeyScript];
	
	// create request
	MGSNetRequest *netRequest = [self createRequestForClient:netClient withOwner:owner withScriptDict:dict];
	
	// send the request 
	[self sendRequestOnClient:netRequest];
	
	return netRequest;
}

//=============================================================
//
// request save edits for client with option to republish.
//
// this message is sent:
// 1. to inform server of new script
// 2. to inform server of edits to existing scripts
//
// These changes may be batched but generally we will want to
// save our edits as they occur to prevent data loss should
// a crash occur.
//
//============================================================
- (void)requestSaveEditsForNetClient:(MGSNetClient *)netClient withOwner:(id <MGSNetRequestOwner>)owner republish:(BOOL)republish
{
	#pragma unused(republish)
	
	// create a dictionary to hold edited script dictionary
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
	[dict setObject:MGSScriptCommandSaveEdits forKey:MGSScriptKeyCommand];
	
	// add the edited script dictionary
	// this will contain a copy of the edited items
	id scriptDict= [[netClient.taskController scriptManager] editDictionaryCopy];
	
	[[netClient.taskController scriptManager] acceptScheduleSave];
	[dict setObject:scriptDict forKey:MGSScriptKeyScript];
	
	// create request
	MGSNetRequest *netRequest = [self createRequestForClient:netClient withOwner:owner withScriptDict:dict];
	
	// send the request 
	[self sendRequestOnClient:netRequest];
}

/*
 
 request script for UUID
 
 */
- (MGSNetRequest *)requestScriptWithUUID:(NSString *)UUID netClient:(MGSNetClient *)netClient withOwner:(id <MGSNetRequestOwner>)owner options:(NSDictionary *)options
{
	// create a dictionary requesting script resume
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
	[dict setObject:MGSScriptCommandGetScriptUUID forKey:MGSScriptKeyCommand];
	
	// create array of command parameters
	NSArray *array = [NSArray arrayWithObject:UUID];
	[dict setObject:array forKey:MGSScriptKeyCommandParamaters];
	
	// add command options
	if (options) {
		[dict setObject:options forKey:MGSScriptKeyCommandDictionary];
	}
	
	// create request
	MGSNetRequest *netRequest = [self createRequestForClient:netClient withOwner:owner withScriptDict:dict];

	// send the request 
	[self sendRequestOnClient:netRequest];
	
	return netRequest;
}

@end

@implementation MGSClientRequestManager(Private)

/*
 
 create request on net client with command
 the message will not contain a script dictionary
 
 */
- (MGSNetRequest *)createRequestForClient:(MGSNetClient *)netClient command:(NSString *)command withOwner:(id <MGSNetRequestOwner>)owner
{
	return [self createRequestForClient:netClient withOwner:owner withCommand:command withDict:nil forKey:nil];
}

/*
 
 create request on net client with script command
 the message will contain a script dictionary containing a single command
 
 */
- (MGSNetRequest *)createRequestForClient:(MGSNetClient *)netClient scriptCommand:(NSString *)scriptCommand withOwner:(id <MGSNetRequestOwner>)owner
{
	// create a dictionary requesting script list
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
	[dict setObject:scriptCommand forKey:MGSScriptKeyCommand];
	
	return [self createRequestForClient:netClient withOwner:owner withScriptDict:dict];
}

/*
 
 create request on net client with script dictionary
 the message will contain the script dictionary
 
 */
- (MGSNetRequest *)createRequestForClient:(MGSNetClient *)netClient withOwner:(id <MGSNetRequestOwner>)owner withScriptDict:(NSMutableDictionary *)dict
{
	return [self createRequestForClient:netClient withOwner:owner withCommand:MGSNetMessageCommandParseKosmicTask withScriptDict:dict];
}


/*
 
 create request on net client with script dict 
 
 */
- (MGSNetRequest *)createRequestForClient:(MGSNetClient *)netClient withOwner:(id <MGSNetRequestOwner>)owner withCommand:(NSString *)command withScriptDict:(NSMutableDictionary *)dict
{	
	return [self createRequestForClient:netClient withOwner:owner withCommand:command withDict:dict forKey:MGSScriptKeyKosmicTask];
}

/*
 
 create request on net client with command and dictionary
 
 */
- (MGSNetRequest *)createRequestForClient:(MGSNetClient *)netClient withOwner:(id <MGSNetRequestOwner>)owner 
					withCommand:(NSString *)command 
					   withDict:(NSMutableDictionary *)dict forKey:(NSString *)key

{
	NSAssert(netClient, @"net client is nil");
	
	// create request on client with specified command type.
	// the request delegate will be set to self (this object).
	// the delegate object is responsible for the creation and co-ordination
	// of the request.
	MGSNetRequest *netRequest = [MGSNetRequest requestWithClient:netClient command:command]; 
	netRequest.delegate = self;	// this object is the delegate

	// the owner object may be informed of the progress of the
	// request but does not cordinate it like the delegate
	[netRequest setOwner:owner]; 
	
	// tell owner that net request will send
	if (owner && [owner respondsToSelector:@selector(netRequestWillSend:)]) {
		NSDictionary *ownerDict = [owner netRequestWillSend:netRequest];
		if (ownerDict) {
			
			// if dictionary defines a read timeout value then use it
			NSNumber *number = [ownerDict objectForKey:@"ReadTimeout"];
			if (number && [number isKindOfClass:[NSNumber class]]) {
				double timeout = [number doubleValue];
				
				// a timeout of 0 is used to indicate that the default
				// timout is to be used
				if (timeout > 0) {
					netRequest.readTimeout = timeout;
				}
			}

			// if dictionary defines a write timeout value then use it
			number = [ownerDict objectForKey:@"WriteTimeout"];
			if (number && [number isKindOfClass:[NSNumber class]]) {
				double timeout = [number doubleValue];
				
				// a timeout of 0 is used to indicate that the default
				// timout is to be used
				if (timeout > 0) {
					netRequest.writeTimeout = timeout;
				}
			}
			
		}
	}
	
	// add a dictionary to the request if defined
	if (dict) {
		[netRequest.requestMessage setMessageObject:dict forKey:key];
	} 
		
	//
	// if the client authentication dict exists add it to the request.
	// note that the dict will be sent for all requests even if not
	// strictly required for some commands
	//
	// don't authenticate unless reqd
    //
	NSDictionary *authDict = [netRequest.netClient authenticationDictionaryForRunMode];
    if (!authDict) {
        
        /* if we are authenticating against the local host then
            use the auto generated authentication dictionary at all times.
         */
        if (netRequest.netClient.isLocalHost && [command isEqualToString:MGSNetMessageCommandAuthenticate]) {
            authDict = [netRequest.netClient authenticationDictionary];
        }
    }
	if (authDict) {
		[[netRequest requestMessage] setAuthenticationDictionary:authDict];
	}
		
	return netRequest;
}

#pragma mark -
#pragma mark Request reply handling

/*
 
 parse net request reply for script activity
 
 */
- (void)parseScriptRequestReply:(MGSNetRequest *)netRequest
{
	NSAssert(netRequest, @"net request is nil");
	
	NSInteger errorCode = MGSErrorCodeParseRequestScript;
	NSString *error = nil;
	NSString *requestCommand = @"no command found";
	NSMutableDictionary *responseScriptDict = nil;
	MGSError *scriptError = nil;

	MGSNetMessage *requestMessage = [netRequest requestMessage];
	MGSNetMessage *responseMessage = [netRequest responseMessage];
	
	// all script tasks will be contained in the kosmicTask dictionary

	// if no top level error then check for script level error
	if (!netRequest.error) {
	
		// parse the request script command
		if (!error) {
			requestCommand = [requestMessage messageObjectForKey:MGSScriptKeyCommand];
			if (!requestCommand) {
				error = NSLocalizedString(@"script command not found", @"parse request error");
			}
		}
		
		// get reply script dict
		if (!error) {
			id obj = [responseMessage messageObjectForKey:MGSScriptKeyKosmicTask];
			if ([obj classForCoder] == [NSMutableDictionary class]) {	// not recommended !
				responseScriptDict = obj;
				
				// look for script level error
				NSDictionary *errorDict = [responseScriptDict objectForKey:MGSScriptKeyNSErrorDict];
				if (errorDict) {
					scriptError = [MGSError errorWithDictionary:errorDict];
				}
				
			} else {
				error = NSLocalizedString(@"script dictionary not found", @"parse request error");
			}
		}
		
		// process errors
		if (error) {
			// define error
			scriptError = [MGSError clientCode:errorCode reason:error log:YES];	// logging will occur when error extracted from dic
			
			// create dict if missing
			if (nil == responseScriptDict) {
				responseScriptDict = [NSMutableDictionary dictionaryWithCapacity:1];
				[responseMessage setMessageObject:responseScriptDict forKey:MGSScriptKeyKosmicTask];
			}
			
			// add error to dict
			[responseScriptDict setObject:[scriptError dictionary] forKey:MGSScriptKeyNSErrorDict];
			
			// error sent as part of the payload so allow continue
		}
	}
	
	// Process a negotiate response.
	// 
	// If there are no errors then we can return.
	// Otherwise we must proceed and inform the owner so that
	// the UI can be updated accordingly
	//
	// a negotiate request message will be found here if command based negotiation is enabled

	if (responseMessage.negotiator && !scriptError && !netRequest.error) {
		return;		
	}
	
	// need an owner to receive the payload.
	// some requests, such as pause and resume require no payload
	// and thus it is valid for the owner to be nil
	if (![netRequest owner]) {
		return;
	}
	
	// generate previews for the attachments
	// this will occur asynchronously
	[responseMessage.attachments generateAttachmentPreviews];
	
	// create the payload
	MGSNetRequestPayload *payload = [[MGSNetRequestPayload alloc] init];
	payload.requestID = netRequest.requestID;
	payload.dictionary = responseScriptDict;
	
	
	// flag error in payload
	if (netRequest.error) {
		payload.requestError = netRequest.error;	// message level error
	}
	else if (scriptError) {
		payload.requestError = scriptError;	// script level error
		netRequest.error = scriptError;
	} else {
		payload.requestError = nil;
	}

	//
	// on script execute
	//
	if (requestCommand && NSOrderedSame == [requestCommand caseInsensitiveCompare:MGSScriptCommandExecuteScript]) {
		
		// execute success
		BOOL executeSuccess = payload.requestError == nil ? YES : NO;
		
		// if execute succeeded we can disable sending further licence
		// data with execute requests.
		// #warning it might be better to disable this
		if (YES) {
			netRequest.netClient.sendExecuteValidation = !executeSuccess;
		}
	}
	
	// send response to owner
	if ([[netRequest owner] respondsToSelector:@selector(netRequestResponse:payload:)]) {
		[[netRequest owner] netRequestResponse:netRequest payload:payload];
	}
	
	return;
}

/*
 
 parse the reply message
 
 */
- (void)parseReplyMessage:(MGSNetRequest *)netRequest
{
	NSString *error = nil;
	NSInteger errorCode = MGSErrorCodeParseRequestMessage;
	MGSError *mgsError = nil;

	// get request owner
	id owner = [netRequest owner];
	BOOL sendReply = (owner && [owner respondsToSelector:@selector(netRequestResponse:payload:)]);
	
	MGSNetMessage *requestMessage = [netRequest requestMessage];	
	MGSNetMessage *replyMessage = [netRequest responseMessage];	

	// create the payload for the request
	MGSNetRequestPayload *payload = [MGSNetRequestPayload payloadForRequest:netRequest];

	// obtain the request command.
	// the reply must be validated against the nature of the request command
	NSString *requestCommand = [requestMessage command];
	if (![requestCommand isKindOfClass:[NSString class]]) {
		error = NSLocalizedString(@"Request command not found", "request message parse error");
		goto invalid_message;
	}
	
	//=================================================================
	//
	// process reply message errors
	//
	//=================================================================
	mgsError = replyMessage.error;
	if (mgsError) {
		
        [netRequest tagError:mgsError];
        
		//=================================================================
		// Has authentication failure occured?
		// 
		// In this case we retrieve the challenge dictionary from the reply,
		// formulate our response and resend the request
		//
		//==================================================================	
		if ([mgsError code] == MGSErrorCodeAuthenticationFailure) {

			// if we are authenticating then prompt 
			if ([requestCommand isEqualToString:MGSNetMessageCommandAuthenticate]) {

				// request net client not authenticated
				[netRequest.netClient setAuthenticationDictionary:nil];
								
				// look for the challenge dict.
				// if none found then clear text authentication will be used
				NSDictionary *challengeDict = [replyMessage messageObjectForKey:MGSNetMessageKeyChallenge];
				
				// ask authenticate window controller to accept request.
				// the controller will prompt the user for authentication details.
				// note that the authentication controller may not be able to accept the request
				// if it is active with another request.
				MGSAuthenticateWindowController *authenticateController = [MGSAuthenticateWindowController sharedController];
				if ([authenticateController authenticateRequest:netRequest challenge:challengeDict]) {
					return;
				}
			}
			
		}
		
		netRequest.error = mgsError;
		
	}
	
	//==================================
	// are there errors in the request
	//==================================
	if (netRequest.error) {		
		
		// ERROR in request

		// The request contains a top level error.
		// This means there is something structural wrong with the message or a network/socket error has occurred.
		// However, the request owners still need a reply.
		//
	
        [netRequest tagError:netRequest.error];
	}
		
	//=================================================================
	//  Has authentication success occurred?
	//
	// If the request contains an authentication dict and no error
	// occured then the dict must be valid for the client
	//=================================================================
	NSDictionary *authDict = nil;
	if (!netRequest.error) {
		authDict = [requestMessage authenticationDictionary];
		if (authDict) {
			[netRequest.netClient setAuthenticationDictionary:authDict];
		}
	}
	
	//===================================================
	//
	// Process the application dict if present
	//
	// Normally only present when first retrieve the 
	// script dict.
	//===================================================
	NSDictionary *appDict = [replyMessage messageObjectForKey:MGSNetMessageKeyApplication];
	if (appDict){
		
		// only need to update for non bonjour host
		if (NO == [netRequest.netClient hostViaBonjour]) {
			NSString *username = [appDict objectForKey:MGSApplicationKeyUsername];
			if (username) {
				[netRequest.netClient setHostUserName:username];
				
				// local clients obtain info via the mDNS TXTRecord mechanism.
				// remote clients use the application data.
				[netRequest.netClient TXTRecordUpdate];
			}
		}
	}
			
	//====================================================
	// 
	// Process the request command
	//
	//====================================================
	// a negotiate request
	if ([requestCommand isEqualToString:MGSNetMessageCommandNegotiate]) {

		/*
		 
		 if a network or socket error occurs it can manifest itself here.
		 
		 set the error on the next request (which will have initiated the
		 sending of the negotiate request) and call theis method again
		 
		 */
		if (netRequest.error && netRequest.nextRequest) {
			netRequest.nextRequest.error = netRequest.error;
			[self parseReplyMessage:netRequest.nextRequest];
		}
		
		return;
	}
	
	// a heartbeat request
	if ([requestCommand isEqualToString:MGSNetMessageCommandHeartbeat]) {
		
		if ([requestMessage isNegotiateMessage]) {
			return;
		}
		
		// tell the owner that the heartbeat reply was received
		if (sendReply) {
			[owner netRequestResponse:netRequest payload:payload];
		}		
		
	}
	
	// an authentication request
	else if ([requestCommand isEqualToString:MGSNetMessageCommandAuthenticate]) {
	
		// a negotiate request message will be found here if command based negotiation is enabled
		if ([requestMessage isNegotiateMessage]) {
			return;
		}
		
		// add payload dictionary
		payload.dictionary = [requestMessage authenticationDictionary];
		
		// tell the owner that the authenticate reply was received
		if (sendReply) {
			[owner netRequestResponse:netRequest payload:payload];
		}
	}
	
	// a script to be parsed
	else if ([requestCommand isEqual:MGSNetMessageCommandParseKosmicTask]) {
		
		[self parseScriptRequestReply:netRequest];

	// ERROR
	} else {
		error = NSLocalizedString(@"Unrecognised request command: %@", "reply message parse error");
		error = [NSString stringWithFormat: error, requestCommand];
		goto invalid_message;
	}
		
	return;

invalid_message:
	
	if (!mgsError) {
		mgsError = [MGSError clientCode:errorCode reason:error];	// log error
        [netRequest tagError:mgsError];
	}
	
	payload.requestError = mgsError;

	// send response to owner
	if (sendReply) {
		[owner netRequestResponse:netRequest payload:payload];
	}
	
	return;
}

//================================================
// net request reply received 
// all queued requests ultimately send this message
// on success, error or timeout
//================================================
-(void) netRequestReplyOnClient:(MGSNetRequest *)netRequest {
	NSAssert(netRequest, @"net request is nil");
	
	// parse the reply
	[self parseReplyMessage:netRequest];
	
	// remove the request
	[self removeRequest:netRequest];

}

@end

