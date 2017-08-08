//
//  MGSServerScriptRequest.m
//  Mother
//
//  Created by Jonathan Mitchell on 29/12/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSServerScriptRequest.h"
#import "MGSServerNetRequest.h"
#import "MGSNetMessage.h"
#import "MGSScriptPlist.h"
#import "MGSTaskPlist.h"
#import "MGSPath.h"
#import "MGSBundleToolPath.h"
#import "MGSServerScriptManager.h"
#import "MGSScript.h"
#import "MGSScriptCode.h"
#import "MGSError.h"
#import "MGSResultFormat.h"
#import "MGSPreferences.h"
#import "NSPropertyListSerialization_Mugginsoft.h"
#import "MGSNetAttachments.h"
#import "MGSNetAttachment.h"
#import "NSString_Mugginsoft.h"
#import "MGSServerRequestThreadHelper.h"
#import "MGSAppleScriptData.h"
#import "MGSServerRequestManager.h"
#import "MGSScriptManager.h"
#import "MGSMetaDataHandler.h"
#import "MGSSystem.h"
#import "MGSServerTaskConfiguration.h"
#import "MGSTrialRestrictions.h"
#import "MGSLM.h"
#import "MGSL.h"
#import "MGSAPLicenceCode.h"
#import "NSURL+NDCarbonUtilities.h"
#import <OSAKit/OSAKit.h>
#import "MGSLanguagePlugin.h"
#ifdef MGS_PARSE_RESULT_AS_FSCRIPT
#import <FScript/FScript.h>
#endif
#import "MGSTempStorage.h"
#import <YAMLKit/YAMLKit.h>
#import "MGSNetNegotiator.h"

#undef MGS_LOG_TASK_REQUEST_UUID_ACTIVITY

#define MGS_PARSE_RESULT_AS_YAML

NSString *MGSSearchKeyQuery = @"Query";
NSString *MGSSearchKeyRequest = @"Request";
NSString *MGSSearchKeyDictionary = @"Dictionary";

static NSString *MGSServerScriptException = @"MGSServerScriptException";

NSUInteger totalExecutionCount = 0;	// number of task execute requests received

static BOOL LicenceValidForRequest(MGSServerNetRequest *netRequest, MGSError **mgsError);

@interface MGSServerScriptRequest()
- (BOOL)sendValidRequestReply:(MGSServerNetRequest *)request withNegotiator:(MGSNetNegotiator *)negotiator;
@end

@interface MGSServerScriptRequest (Private)
- (BOOL)initialise;
- (BOOL)validateScriptFolders;
- (BOOL)processEditedScriptArray:(NSMutableDictionary *)scriptDict forRequest:(MGSServerNetRequest *)netRequest;

@end

@interface MGSServerScriptRequest (RequestUUID)
- (BOOL)terminateRequestUUIDs:(NSArray *)UUIDs forRequest:(MGSServerNetRequest *)netRequest;
- (BOOL)suspendRequestUUIDs:(NSArray *)UUIDs forRequest:(MGSServerNetRequest *)netRequest;
- (BOOL)suspendRequestUUID:(NSString *)UUID;
- (BOOL)resumeRequestUUIDs:(NSArray *)UUIDs forRequest:(MGSServerNetRequest *)netRequest;
- (BOOL)resumeRequestUUID:(NSString *)UUID;
- (BOOL)logRequestUUIDs:(NSArray *)UUIDs forRequest:(MGSServerNetRequest *)netRequest;
- (BOOL)logRequestUUID:(NSString *)UUID forRequest:(MGSServerNetRequest *)netRequest;
- (BOOL)terminateTaskAndRequestWithRequestUUID:(NSString *)UUID;
- (BOOL)terminateTaskOnlyWithRequestUUID:(NSString *)UUID;
- (BOOL)terminateTaskWithRequestUUID:(NSString *)UUID terminateRequest:(BOOL)terminateRequest;
@end

@interface MGSServerScriptRequest (Script)
- (BOOL)executeScript:(MGSScript *)script forRequest:(MGSServerNetRequest *)netRequest;
- (BOOL)getCompiledSourceForScriptUUID:(NSArray *)UUID forRequest:(MGSServerNetRequest *)netRequest;
- (BOOL)compileScript:(MGSScript *)scriptDict forRequest:(MGSServerNetRequest *)netRequest;
- (BOOL)getScriptUUID:(NSArray *)UUIDs forRequest:(MGSServerNetRequest *)netRequest options:(NSDictionary *)options;
- (MGSScript *)loadScriptWithUUID:(NSString *)UUID  error:(MGSError **)mgsError;
@end

@interface MGSServerScriptRequest (Search)
- (BOOL)search:(NSDictionary *)searchDict forRequest:(MGSServerNetRequest *)netRequest;
- (void)processSearchQueryResults:(NSMetadataQuery *)mdQuery forSearchDict:(NSDictionary *)searchDict forRequest:(MGSServerNetRequest *)netRequest;
- (void) searchQueryNotification:(NSNotification *)note;
@end

@interface MGSServerScriptRequest (Task)
- (BOOL)startTask:(NSDictionary *)taskDict options:(NSDictionary *)options error:(NSError **)error;
- (void) taskDidTerminate:(id)aTask;
@end

@implementation MGSServerScriptRequest 

@synthesize initialised = _initialised;

/*
 
 init
 
 */
- (MGSServerScriptRequest *)init
{
	if ((self = [super init])) {
		_processRequests = NO;	// cannot yet accept requests
		_initialised = [self initialise];
		_activeSearches = [NSMutableArray arrayWithCapacity:1];
	}
	return self;
}



//======================================================
// load or reload the script managers
//
//======================================================
- (BOOL)loadScriptManagers
{
	// server will not accept requests until
	// the handlers are loaded
	_processRequests = NO;

	// reloading?
	if (_scriptManager) {
		_scriptManager = nil;
		_publishedScriptManager = nil;
	}

	// _scriptHandler contains all scripts.
	// load all scripts with representation suitable for display.
	// ie: we don't want to include the script code.
	_scriptManager = [[MGSServerScriptManager alloc] init];
	
	// version 1.0 behaviour is to send display representation
	MGSScriptRepresentation representation = MGSScriptRepresentationDisplay;
	
	// version 1.1 behaviour is to send preview representation
	if (YES) {
		representation = MGSScriptRepresentationPreview;
	}
	
	if (![_scriptManager loadScriptsWithRepresentation:representation]) {
		MLog(RELEASELOG, @"could not load scripts with required representation");
		return NO;
	}
	
	// published script handler contains published scripts
	_publishedScriptManager = [_scriptManager publishedScriptManager];
	if (!_publishedScriptManager) {
		MLog(RELEASELOG, @"server published script handler is invalid");
		return NO;
	}
	
	// server will now accept requests
	_processRequests = YES;
		
	return YES;
}

/*
 
 - sendValidRequestReply:withNegotiator:
 
 */
- (BOOL)sendValidRequestReply:(MGSServerNetRequest *)request withNegotiator:(MGSNetNegotiator *)negotiator
{
	// if the negotiator requests security then that security
	// will be applied once this reply has been sent.
	// in other words, if the client requests security it will get it
	// unless it gets overidden here
	/*if (negotiator.securityType) {
	 
		// do we allow the client to request security
	}*/
	[request.responseMessage applyNegotiator:negotiator];
	
	[self sendValidRequestReply:request];
	return YES;
}

//=======================================================
// parse net request for script activity
//
// if this function returns YES then then caller
// assumes that the request was valid and that reply
// will be imediately or subsequently generated.
//
// if this function returns NO then the caller
// assumes that the request was invalid and
// sends an error reply at once.
//=======================================================
- (BOOL)parseNetRequest:(MGSServerNetRequest *)netRequest
{
	NSInteger errorCode = MGSErrorCodeParseRequestScript;
	NSString *errorReason = nil;
	
	NSAssert([netRequest delegate], @"net request delegate is nil");
	
	MGSNetMessage *requestMessage = [netRequest requestMessage];
	MGSNetMessage *responseMessage = [netRequest responseMessage];

	NSMutableDictionary *requestDict = [requestMessage messageDict];
	NSMutableDictionary *motherDict = nil;
	
	@try {

        //
        // all script actions will be contained in the KosmicTask dictionary
        //
        id obj = [requestDict objectForKey:MGSScriptKeyKosmicTask];	
        if ([obj isKindOfClass: [NSDictionary class]]) {
            motherDict = obj;
        } else {
            errorReason = NSLocalizedString(@"No KosmicTask script key found.", @"Error returned by server");
            [NSException raise:MGSServerScriptException format:@"%@", errorReason];
        }
        
        //
        // get the script command
        //
        NSString *command = [motherDict objectForKey:MGSScriptKeyCommand];
        if (!command) {
            errorReason = NSLocalizedString(@"No command script key found.", @"Error returned by server");
            [NSException raise:MGSServerScriptException format:@"%@", errorReason];
        }
        
        //
        // log commands which do not contain a single script def
        //
        NSSet *scriptCommandSet = [NSSet setWithObjects:MGSScriptCommandExecuteScript, MGSScriptCommandBuildScript, nil];
        if (![scriptCommandSet containsObject:command]) {
            // TODO: add a preference for this
            if (NO) {

                MLogInfo(@"Received command: %@ from %@ in request %@", 
                         command, 
                         [requestMessage messageOriginCompactString], 
                         [requestMessage messageUUID]);
            }
        }

        //
        // check for negotiator
        //	
        MGSNetNegotiator *responseNegotiator = nil;
        if ([requestMessage isNegotiateMessage]) {
            MGSNetNegotiator *requestNegotiator = [requestMessage negotiator];
            responseNegotiator = [[MGSNetNegotiator alloc] init];
            
            // if the security is requested then acquiesce.
            if ([requestNegotiator TLSSecurityRequested]) {
                [responseNegotiator setSecurityType:MGSNetMessageNegotiateSecurityTLS];
            }
            
            // echo the command and MGSScriptKeyKosmicTask object
            responseMessage.command = requestMessage.command;
            [responseMessage setMessageObject:motherDict forKey:MGSScriptKeyKosmicTask];
        }
        
        // get command parameters - may be nil
        NSArray *commandParameters = [motherDict objectForKey:MGSScriptKeyCommandParamaters];
        
        // get command dict - may be nil
        NSDictionary *commandDictionary = [motherDict objectForKey:MGSScriptKeyCommandDictionary];
        
        // can requests currently be processed.
        // processing may be denied if the server is
        // currently updating its state or if the updating
        // of its state has failed
        if (!_processRequests) {
            errorReason = NSLocalizedString(@"Requests cannot be accepted at this time.", @"Error returned by server");
            [NSException raise:MGSServerScriptException format:@"%@", errorReason];
        }
            
        //*******************************************
        // get list of the available scripts
        //*******************************************
        if ([command isEqualToString:MGSScriptCommandListAll] || [command isEqualToString:MGSScriptCommandListPublished]) {
            
            if (!_scriptManager) {
                errorReason = NSLocalizedString(@"script handler is nil", @"Error returned by server");
                [NSException raise:MGSServerScriptException format:@"%@", errorReason];
            }
            
            NSMutableDictionary *dict;
            if ([command isEqualToString:MGSScriptCommandListAll]) {
                
                // authenticate to list all scripts
                if (![netRequest authenticateWithAutoResponseOnFailure:YES]) {
                    return YES;	// do not want error reply
                }			
                
                dict = [_scriptManager dictionary];
            } else {
                
                // reply to negotiate
                if ([requestMessage isNegotiateMessage]) {
                    return [self sendValidRequestReply:netRequest withNegotiator:responseNegotiator];
                }

                dict = [_publishedScriptManager dictionary];
            }
            
            // add scripts dict to reply, flag as valid and send
            [responseMessage setMessageObject:dict forKey:MGSScriptKeyKosmicTask];
                    
            // add application dictionary.
            // data in this is mutable so update for each request.
            // this data can inform non Bonjour clients of some/all of parameters of the mDNS TRXTRecord
            NSInteger usernameDisclosureMode = [[MGSPreferences standardUserDefaults] integerForKey:MGSUsernameDisclosureMode];
            NSDictionary *appDict = [NSDictionary dictionaryWithObjectsAndKeys: 
                                     (usernameDisclosureMode == DISCLOSE_USERNAME_TO_ALL ? NSUserName(): @""), MGSApplicationKeyUsername, 
                                     [NSNumber numberWithBool:YES], MGSApplicationKeyRealTimeLogging, 
                                     nil];
            [responseMessage setMessageObject:appDict forKey:MGSNetMessageKeyApplication];

            // send reply
            [self sendValidRequestReply:netRequest];
            
            return YES;
        }

        //*************************************************
        // terminate all message UUIDs in command parameters
        //*************************************************
        if ([command isEqualToString:MGSScriptCommandTerminateMessageUUID]) {
            
            /* TODO:
            
             Should authentication be applied here and in similar case below?
             
             It might make things difficult if trusted task
             persists in the GUI in Public access mode/
             
            */
            
            // reply to negotiate
            if ([requestMessage isNegotiateMessage]) {
                return [self sendValidRequestReply:netRequest withNegotiator:responseNegotiator];
            }
            
            return [self terminateRequestUUIDs:commandParameters forRequest:netRequest];
        } 

        //*************************************************
        // suspend all message UUIDs in command parameters
        //*************************************************
        if ([command isEqualToString:MGSScriptCommandSuspendMessageUUID]) {
            
            // reply to negotiate
            if ([requestMessage isNegotiateMessage]) {
                return [self sendValidRequestReply:netRequest withNegotiator:responseNegotiator];
            }
            
            return [self suspendRequestUUIDs:commandParameters forRequest:netRequest];
        } 

        //*************************************************
        // resume all message UUIDs in command parameters
        //*************************************************
        if ([command isEqualToString:MGSScriptCommandResumeMessageUUID]) {
            
            // reply to negotiate
            if ([requestMessage isNegotiateMessage]) {
                return [self sendValidRequestReply:netRequest withNegotiator:responseNegotiator];
            }
            
            return [self resumeRequestUUIDs:commandParameters forRequest:netRequest];
        } 

        //*************************************************
        // search using command dictionary
        //*************************************************
        if ([command isEqualToString:MGSScriptCommandSearch]) {
            
            // reply to negotiate
            if ([requestMessage isNegotiateMessage]) {
                return [self sendValidRequestReply:netRequest withNegotiator:responseNegotiator];
            }
            
            
            return [self search:commandDictionary forRequest:netRequest];
        } 
        
        //*************************************************
        // get script UUID in command parameters
        //*************************************************
        if ([command isEqualToString:MGSScriptCommandGetScriptUUID]) {
            
            // look for required representation
            MGSScriptRepresentation representation = MGSScriptRepresentationComplete;
            NSNumber *commandOption = [commandDictionary objectForKey:MGSScriptKeyRepresentation];
            if (commandOption) {
                representation = [commandOption integerValue];
            }
            
            // authenticate if required
            if ([MGSScript clientRepresentationRequiresAuthentication:representation]) {
                            
                if (![netRequest authenticateWithAutoResponseOnFailure:YES]) {
                    return YES;	// do not want error reply
                }	
                
            } else if ([requestMessage isNegotiateMessage]) {
                return [self sendValidRequestReply:netRequest withNegotiator:responseNegotiator];
            }
            
            // return the representation
            return [self getScriptUUID:commandParameters forRequest:netRequest options:commandDictionary];
        } 
        
        //*******************************************
        // get compiled script source
        //*******************************************
        if ([command isEqualToString:MGSScriptCommandGetScriptUUIDCompiledSource]) {
            
            // request must be authenticated.
            // if the request does not authenticate then an authentication failure
            // reply will automatically be sent
            if (![netRequest authenticateWithAutoResponseOnFailure:YES]) {
                return YES;	// do not want error reply
            }
            
            return [self getCompiledSourceForScriptUUID:commandParameters forRequest:netRequest];
        }
        
        //*******************************************
        // log output of message with given UUID
        //*******************************************
        if ([command isEqualToString:MGSScriptCommandLogMesgUUID]) {
            
            return [self logRequestUUIDs:commandParameters forRequest:netRequest];
        }
        
        //
        // remaining commands require a script dictionary
        //
        // get the request script dictionary object
        //
        NSMutableDictionary *requestScriptDict = [motherDict objectForKey:MGSScriptKeyScript];
        if (!requestScriptDict) {
            errorReason = NSLocalizedString(@"Request script dictionary not found", @"Error returned by server");
            [NSException raise:MGSServerScriptException format:@"%@", errorReason];
        }

        //**********************************************
        // process array of edited scripts
        //**********************************************
        if ([command isEqualToString:MGSScriptCommandSaveEdits]) 
        {
            // request must be authenticated.
            // if the request does not authenticate then an authetication failure
            // reply will automatically be sent
            if (![netRequest authenticateWithAutoResponseOnFailure:YES]) {
                return YES;	// do not want error reply
            }
            
            return [self processEditedScriptArray:requestScriptDict forRequest:netRequest];
        }
        
        //**********************************************
        // process array of changed scripts and republish
        //**********************************************
        if ([command isEqualToString:MGSScriptCommandSaveChangesAndPublish]) 
        {
            // request must be authenticated.
            // if the request does not authenticate then an authetication failure
            // reply will automatically be sent
            if (![netRequest authenticateWithAutoResponseOnFailure:YES]) {
                return YES;	// do not want error reply
            }
            
            return [self processEditedScriptArray:requestScriptDict forRequest:netRequest];
        }

        //
        // form request script object using the script dict.
        // this will generally not be a full representation of the script.
        // ie: it will not contain executable data
        //
        // Note that we should not implicity trust the incoming data if a representation
        // exists on the disk. We should always query the disk representation when available.
        MGSScript *requestScript = [MGSScript scriptWithDictionary:requestScriptDict];
        if (!requestScript) {
            errorReason = NSLocalizedString(@"invalid script object", @"Error returned by server");
            [NSException raise:MGSServerScriptException format:@"%@", errorReason];
        }
        
        // this is not the most thoughtful implementation.
        // we are trusting the incoming data rather than referring to any pre-existing
        // on disk representation
        // validate the script type
        if (NO) {
            
            if ([requestScript scriptType]) {
                if (![MGSScript validateScriptType:[requestScript scriptType]]) {
                    errorReason = NSLocalizedString(@"invalid script type", @"Error returned by server");
                    [NSException raise:MGSServerScriptException format:@"%@", errorReason];
                }
            }
            
            // validate the OS version.
            if (![requestScript validateOSVersion]) {
                errorReason = NSLocalizedString(@"script cannot be executed on this OS version", @"Error returned by server");
                [NSException raise:MGSServerScriptException format:@"%@", errorReason];
            }
        }
        
        //
        // log script command
        //
        // TODO: add a preference for this
        if (NO) {

            MLogInfo(@"Received command: %@ \"%@\" (%@) from %@ in request %@", 
                     command,
                     [requestScript name],
                     [requestScript UUID], 
                     [netRequest.requestMessage messageOriginCompactString],
                     [requestMessage messageUUID]);
        }
        
        //*******************************************
        // execute a given script
        //*******************************************
        if ([command isEqualToString:MGSScriptCommandExecuteScript]) {
            
            
            // if script is published then authentication is not required.
            // otherwise authentication is required.
            // we cannot rely on the request script to inform us truthfully of the scripts
            // publication status.
            NSString *UUID = [requestScript UUID];		
            BOOL executeRequiresAuthentication = ![_scriptManager scriptUUIDPublished:UUID];
            
            // authenticate if required
            if (executeRequiresAuthentication) {
                
                // request must be authenticated.
                // if the request does not authenticate then an authentication failure
                // reply will automatically be sent
                if (![netRequest authenticateWithAutoResponseOnFailure:YES]) {
                    return YES;	// do not want error reply
                }
            } else if ([requestMessage isNegotiateMessage]) {
                return [self sendValidRequestReply:netRequest withNegotiator:responseNegotiator];
            }
            
            return [self executeScript:requestScript forRequest:netRequest];
        } 

        //*******************************************
        // build script
        //*******************************************
        else if ([command isEqualToString:MGSScriptCommandBuildScript]) {
            
            // request must be authenticated.
            // if the request does not authenticate then an authetication failure
            // reply will automatically be sent
            if (![netRequest authenticateWithAutoResponseOnFailure:YES]) {
                return YES;	// do not want error reply
            }

            return [self compileScript:requestScript forRequest: netRequest];
        }
        
        // ERROR
        // unrecognised script command received
        errorReason = NSLocalizedString(@"unrecognised script key command received", @"Error returned by server");
        [NSException raise:MGSServerScriptException format:@"%@", errorReason];
            
    }
    @catch (NSException *exception) {
        NSMutableDictionary *replyDict = [NSMutableDictionary dictionaryWithCapacity:1];
        
        MGSError *mgsError = [MGSError serverCode:errorCode reason:errorReason];
        
        // insert error into reply script dict
        [replyDict setObject:[mgsError dictionary] forKey:MGSScriptKeyNSErrorDict];
        [[netRequest responseMessage] setMessageObject:replyDict forKey:MGSScriptKeyKosmicTask];

    }
   
	return NO;		// caller will issue reply
}

/*
 
 - terminateRequest:
 
 */
- (BOOL)terminateRequest:(MGSServerNetRequest *)netRequest
{
    
#ifdef MGS_LOG_TASK_REQUEST_UUID_ACTIVITY    
    NSLog(@"Terminate Request: %@", [netRequest.requestMessage messageDict]);
#endif
    
	// terminate task associated with request if any still active.
    // also terminate the net request.
	return [self terminateTaskAndRequestWithRequestUUID:[netRequest UUID]];
}

/*
 
 - terminateRequestTask:
 
 */
- (BOOL)terminateRequestTask:(MGSServerNetRequest *)netRequest
{
    
#ifdef MGS_LOG_TASK_REQUEST_UUID_ACTIVITY    
    NSLog(@"Terminate task: %@", [netRequest.requestMessage messageDict]);
#endif
    
	// terminate task associated with request if any still active.
    // the net request itself is not terminated.
	return [self terminateTaskOnlyWithRequestUUID:[netRequest UUID]];
}

/*
 
 path to user application support scripts
 
 */
- (NSString *)userApplicationSupportPath
{
	return [MGSPath userApplicationSupportPath];
}


@end



//
// Private category
//
@implementation MGSServerScriptRequest (Private)

/*
 
 initialise
 
 */
- (BOOL)initialise
{

	_scriptTasks = [[NSMutableDictionary alloc] initWithCapacity:20];
	
	// validate script folders
	if (![self validateScriptFolders]) {
		return NO;
	}
	
	// create the user application path if absent
	if (![MGSPath userApplicationSupportPathExists]) {
		if ([MGSPath verifyUserApplicationSupportPath] == nil) {
			return NO;
		}
	}
	
	// complete task configuration
	_taskConfiguration = [[MGSServerTaskConfiguration alloc] init];
	
	// load script handlers 
	if (![self loadScriptManagers]) {
		return NO;
	}
	
	return YES;
}


/*
 
validate the script folder
 
 */
- (BOOL)validateScriptFolders
{   
	BOOL valid = YES;
	
	// verify user document path exists
	if (![MGSPath userDocumentPathExists]) {
		
		// create user documents folder if missing
		NSString *folder = [MGSPath verifyUserDocumentPath];
		if (folder == nil) {
			return NO;
		}
	}
		
	return valid;
}



//=======================================================
// Process edits to an array scripts.
// This is called when the client exits config mode and
// enters run mode again.
// 1. Scripts marked for save will be saved.
//    this will generally be as the result of a publish/unpublish request
//    made in the browser.
//    Scripts opened in the editor be saved when the editor closes
// 2. scripts marked for delete will be deleted.
// 3. scripts marked for publication will be published/unpublished
// 3. the server script dictionary is reloaded
//
// return YES on success - reply sent
// return NO on failure - caller sends error reply
//=======================================================
- (BOOL)processEditedScriptArray:(NSMutableDictionary *)scriptDict forRequest:(MGSServerNetRequest *)netRequest
{
	NSString *errorReason = nil;
	MGSError *mgsError = nil;
	NSMutableDictionary *replyDict = [NSMutableDictionary dictionaryWithCapacity:2];
	
	// requests will not be accepted until the save is complete
	// and the scripts have been republished.
	// this may be unnecessary in a single threaded server model
	// but will be required if any part of the save ultimately becomes asynchronous.
	_processRequests = NO;
	BOOL allowRequestProcessingFollowingError = YES;
	
	// wrap the dictionary in the script handler
	MGSServerScriptManager *scriptManager = [[MGSServerScriptManager alloc] init];
	[scriptManager setDictionary:scriptDict];
	
	// scan script array
	NSInteger i, scriptCount;
	scriptCount  = [scriptManager count];
	for (i = scriptCount - 1; i >= 0; i--) {
		MGSScript *script = [scriptManager itemAtIndex:i];
		
		// save to default path for script
		//NSString *scriptPath = [script UUIDWithPath:[MGSServerScriptHandler userDocumentPath]];
		NSString *scriptPath = [script UUIDWithPath:[script defaultPath]];
		
		//
		// delete script
		//
		if ([script scheduleDelete]) {
			
#pragma mark warning continue to process and accumulate errors
			
			MLog(DEBUGLOG, @"Deleting script %@ at path: %@", [script UUID], scriptPath);
			// cannot delete bundled scripts
			if (![script canEdit]) {
				
				MLog(RELEASELOG, @"Invalid attempt to delete bundled script at path: %@", scriptPath);
				
			//} else if (![[NSFileManager defaultManager] removeItemAtPath:scriptPath error:&errObj]) {
				
			// delete file to the trash
			} else {
				NSInteger fileTag = 0;
				NSString *source = [scriptPath stringByDeletingLastPathComponent];
				NSArray *files = [NSArray arrayWithObject:[scriptPath lastPathComponent]];
				if (![[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation source:source destination:@"" files:files tag:&fileTag]) {
					errorReason = [NSString stringWithFormat: NSLocalizedString(@"Cannot delete script file with UUID: %@", @"Script file delete error"), [script UUID]];
					goto errorExit;
				}
			}
		}
		
		else {
			
			MGSScript *fileScript = nil;
			BOOL saveFileScript = NO;
			
			//
			// save script
			//
			if ([script scheduleSave]) {	
				
				// cannot save bundled scripts
				if (![script canEdit]) {
					
					MLog(RELEASELOG, @"Invalid attempt to save bundled script at path: %@", scriptPath);
					
				} else {
					MLog(DEBUGLOG, @"Saving script %@ to path: %@", [script UUID], scriptPath);

					fileScript = script;
					
					saveFileScript = YES;
				}
			}
			
			//
			// publish/unpublish script
			//
			else if ([script schedulePublished]) {			

				if ([script published]) {
					MLog(DEBUGLOG, @"Publishing script %@ at path: %@", [script UUID], scriptPath);
				} else {
					MLog(DEBUGLOG, @"Unpublishing script %@ at path: %@", [script UUID], scriptPath);
				}
				
				// bundled scripts have their publication state saved separately
				//if ([script isBundled]) {
				// all scripts have publication state saved in application task plist
				if (1) {	
					
					errorReason = nil;
					if (![_scriptManager saveScriptPropertyPublished:script error:&errorReason]) {
						goto errorExit;
					}
										
				} else {
					// get script from file
					fileScript = [MGSScript scriptWithContentsOfFile:scriptPath error:&mgsError];
					if (!fileScript) {
						goto errorExit;
					}
					
					// set file script published property and save
					[fileScript setPublished: [script published]];
					
					saveFileScript = YES;
				}
			}

			// save the filescript
			if (saveFileScript) {
				NSString *savePath = [fileScript defaultPath];
				[fileScript saveToPath:savePath error:&mgsError];
				if (mgsError) goto errorExit;
			}
			
		}
		
		if (mgsError) goto errorExit;
	}
	
	// reload the script handlers
	if (![self loadScriptManagers]) {
		errorReason = @"Cannot load script handlers following save.";
		allowRequestProcessingFollowingError = NO;
		goto errorExit;		
	}
		
	// add data to reply dict, flag as valid and send
	[replyDict setObject:[NSNumber numberWithBool:YES] forKey:MGSScriptKeyBoolResult];
	[[netRequest responseMessage] setMessageObject:replyDict forKey:MGSScriptKeyKosmicTask];
	[self sendValidRequestReply:netRequest];	

	_processRequests = allowRequestProcessingFollowingError;

	return YES;
	
errorExit:;
	if (!mgsError) {
		mgsError = [MGSError serverCode:MGSErrorCodeSaveScript reason:errorReason];
	}
	
	// insert error into reply script dict
	[replyDict setObject:[mgsError dictionary] forKey:MGSScriptKeyNSErrorDict];
	[[netRequest responseMessage] setMessageObject:replyDict forKey:MGSScriptKeyKosmicTask];
	
	// the save failed but may allow processing of requests again
	_processRequests = allowRequestProcessingFollowingError;
	
	return NO;	// caller will issue reply
}
@end

@implementation MGSServerScriptRequest (RequestUUID)

/*
 
 terminate request UUIDs
 
 */
- (BOOL)terminateRequestUUIDs:(NSArray *)UUIDs forRequest:(MGSServerNetRequest *)netRequest
{
	// terminate each UUID
	for (NSString *UUID in UUIDs) {
		[self terminateTaskAndRequestWithRequestUUID: UUID];
	}
	
	// add scripts dict to reply, flag as valid and send
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
	[[netRequest responseMessage] setMessageObject:dict forKey:MGSScriptKeyKosmicTask];
	
	// send reply
	[self sendValidRequestReply:netRequest];
	
	return YES;	
}
/*
 
 suspend request UUIDs
 
 */
- (BOOL)suspendRequestUUIDs:(NSArray *)UUIDs forRequest:(MGSServerNetRequest *)netRequest
{
	
	for (NSString *UUID in UUIDs) {
		[self suspendRequestUUID:UUID];
	}
	
	// add dict to reply, flag as valid and send
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
	[[netRequest responseMessage] setMessageObject:dict forKey:MGSScriptKeyKosmicTask];
	
	// send reply
	[self sendValidRequestReply:netRequest];
	
	return YES;	
}
/*
 
 suspend request UUID
 
 */
- (BOOL)suspendRequestUUID:(NSString *)UUID
{
	MLog(DEBUGLOG, @"suspend request UUID = %@", UUID);
	
	// terminate task with matching UUID
	MGSScriptTask *scriptTask = [_scriptTasks objectForKey:UUID];
	if (scriptTask) {
		[scriptTask suspend];
		MLog(DEBUGLOG, @"**** task suspended: %@ ****", UUID);
		return YES;
	} 
	
	MLog(DEBUGLOG, @"**** task NOT suspended: %@ ****", UUID);
	return NO;	
}
/*
 
 resume request UUIDs
 
 */
- (BOOL)resumeRequestUUIDs:(NSArray *)UUIDs forRequest:(MGSServerNetRequest *)netRequest
{
	
	for (NSString *UUID in UUIDs) {
		[self resumeRequestUUID:UUID];
	}
	
	// add dict to reply, flag as valid and send
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
	[[netRequest responseMessage] setMessageObject:dict forKey:MGSScriptKeyKosmicTask];
	
	// send reply
	[self sendValidRequestReply:netRequest];
	
	return YES;	
}
/*
 
 log request UUIDs
 
 */
- (BOOL)logRequestUUIDs:(NSArray *)UUIDs forRequest:(MGSServerNetRequest *)netRequest
{
    // in reality we will only ever log one UUID on the current request
	for (NSString *UUID in UUIDs) {
		[self logRequestUUID:UUID forRequest:netRequest];
	}
	
	// logging output will be sent in real time as required	
	return YES;	
}
/*
 
 log request UUID
 
 */
- (BOOL)logRequestUUID:(NSString *)UUID forRequest:(MGSServerNetRequest *)netRequest
{
    // get task with given UUID
    MGSScriptTask *scriptTask = [_scriptTasks objectForKey:UUID];
    if (!scriptTask) {
        return NO;
    }
    
    // inform the script task that we want to use the
    // given request for routing log messages
    scriptTask.logRequest = netRequest;
    
    // add dict to reply, flag as valid and send
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
	[[netRequest responseMessage] setMessageObject:dict forKey:MGSScriptKeyKosmicTask];
	
	// send reply
	[self sendValidRequestReply:netRequest];

    return YES;
}

/*
 
 - terminateTaskAndRequestWithRequestUUID:
 
 */
- (BOOL)terminateTaskAndRequestWithRequestUUID:(NSString *)UUID
{
    return [self terminateTaskWithRequestUUID:UUID terminateRequest:YES];
}

/*
 
 - terminateTaskOnlyWithRequestUUID:
 
 */
- (BOOL)terminateTaskOnlyWithRequestUUID:(NSString *)UUID
{
    return [self terminateTaskWithRequestUUID:UUID terminateRequest:NO];
}
/*
 
 - terminateTaskWithRequestUUID:terminateRequest:
 
 */
- (BOOL)terminateTaskWithRequestUUID:(NSString *)UUID terminateRequest:(BOOL)terminateRequest
{
    if (!UUID) {
        return NO;
    }
    
#ifdef MGS_LOG_TASK_REQUEST_UUID_ACTIVITY
    NSLog(@"Requesting task terminate for request UUID: %@", UUID);
#endif
    
	// terminate task with matching UUID
	MGSScriptTask *scriptTask = [_scriptTasks objectForKey:UUID];
	if (scriptTask) {
		
        // remove task
        [_scriptTasks removeObjectForKey:UUID];
        
		// termminate the originating request
        if (terminateRequest) {
            [[MGSServerRequestManager sharedController] terminateRequest:scriptTask.netRequest];
		}
        
        // terminate the task
		[scriptTask terminate];
		
		MLog(DEBUGLOG, @"**** task terminated: %@ ****", UUID);
        
#ifdef MGS_LOG_TASK_REQUEST_UUID_ACTIVITY
        NSLog(@"Task terminated for request UUID: %@", UUID);
#endif
		return YES;
	}
    
#ifdef MGS_LOG_TASK_REQUEST_UUID_ACTIVITY
    NSLog(@"No task found for request UUID: %@", UUID);
#endif
	return NO;
}


/*
 
 resume request UUID
 
 */
- (BOOL)resumeRequestUUID:(NSString *)UUID
{
	MLog(DEBUGLOG, @"resume request UUID = %@", UUID);
	
	// terminate task with matching UUID
	MGSScriptTask *scriptTask = [_scriptTasks objectForKey:UUID];
	if (scriptTask) {
		[scriptTask resume];
		MLog(DEBUGLOG, @"**** task resumed: %@ ****", UUID);
		return YES;
	} 
	
	MLog(DEBUGLOG, @"**** task NOT resumed: %@ ****", UUID);
	return NO;	
}

@end

@implementation MGSServerScriptRequest (Search)

/*
 
 search
 
 */
- (BOOL)search:(NSDictionary *)searchDict forRequest:(MGSServerNetRequest *)netRequest
{
	// standard dec
	NSString *errorReason = nil;
	MGSError *mgsError = nil;
	NSMutableDictionary *replyDict = [NSMutableDictionary dictionaryWithCapacity:2];
	// end standard decs
	
    @try {
       	// get our search string
        NSString *queryString = [searchDict objectForKey:MGSScriptKeySearchQuery];
        if (!queryString) {
            errorReason = NSLocalizedString(@"No search query string found", @"Returned by server when no valid search query found");
            [NSException raise:MGSServerScriptException format:@"%@", errorReason];
        }
        
        queryString = [queryString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (!queryString || [queryString isEqualToString:@""]) {
            errorReason = NSLocalizedString(@"Empty query string found", @"Returned by server when no valid search query found");
            [NSException raise:MGSServerScriptException format:@"%@", errorReason];
        }
        
        MLog(DEBUGLOG, @"search query string: %@", queryString);
        
        // see Technical Note TN2192 for details
        NSMetadataQuery *mdQuery = [[NSMetadataQuery alloc] init];
        
        // sort results by title
        [mdQuery setSortDescriptors:
         [NSArray arrayWithObjects: [[NSSortDescriptor alloc] initWithKey:(id)kMDItemTitle ascending:NO], 
          nil
          ]
         ];
        
        
        //set our search scope
        NSString *searchScope =[searchDict objectForKey:MGSScriptKeySearchScope];
        NSString *predicateFormat = nil;
        BOOL addWildcards = NO;
        if ([searchScope isEqualToString:MGSScriptSearchScopeScript]) {
            predicateFormat = @"com_mugginsoft_kosmictask_script LIKE[wcd] %@";
            
            // no idea why the wildcards are reqd - but search fails to find anything without them
            addWildcards = YES;
        } else {
            // search will default to content
            predicateFormat = @"kMDItemTextContent LIKE[wcd] %@";
        }
        
        // build up a compound predicate.
        // we could formulate this as a string but the object approach is cleaner.
        // see the NSPredicate programming guide for a comparison of Spotlight and NSPredicate query string syntax differences

        NSMutableArray *subpredicates = [NSMutableArray array];
        NSPredicate *subPred = [NSPredicate predicateWithFormat:@"kMDItemContentType == %@", @"com.mugginsoft.kosmictask.document"];
        [subpredicates addObject:subPred];
        
        NSArray *terms = [queryString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        for(__strong NSString *term in terms) {
            if([term length] == 0) { continue; }
            
            // no idea why the wildcards are reqd - but search fails to find anything without them
            if (addWildcards) {
                term = [NSString stringWithFormat:@"*%@*", term];
            }
            subPred = [NSPredicate predicateWithFormat:predicateFormat, term];
            [subpredicates addObject:subPred];
        }
        
        NSPredicate * predicate = [NSCompoundPredicate andPredicateWithSubpredicates:subpredicates];
        //NSLog(@"%@ %@", queryString, [predicate predicateFormat]);
        
        [mdQuery setPredicate:predicate];

        /*
         
         search user and application document paths
         
         old comment
         
         even though we have valid data in our metadata store we cannot access it by passing in the path to the application package.
         mdfind and spotlight seem to refuse to search an application package.
         the only way to get it to work is to search the application parent folder.
         */	
        NSString *userDocumentPath = [MGSPath userDocumentPath];
        NSString *applicationDocumentPath = nil;
        NSArray *searchScopes = nil;
        if (YES) {
            applicationDocumentPath = [MGSScriptManager applicationDocumentPath];
        } else {
            applicationDocumentPath = [MGSBundleToolPath appPackageParentPath];
        }
        MLog(DEBUGLOG, @"search path scope: %@, %@", userDocumentPath, applicationDocumentPath);
        searchScopes = [NSArray arrayWithObjects:userDocumentPath, applicationDocumentPath, nil];
        [mdQuery setSearchScopes:searchScopes];
            
        // register for query did finish notification
        [[NSNotificationCenter defaultCenter]
         addObserver: self
         selector:@selector(searchQueryNotification:)
         name: nil
         object:mdQuery];
        
        // start our query
        if (![mdQuery startQuery]) {
            errorReason = NSLocalizedString(@"Spotlight query failed to start", @"Returned by server when Spotlight query search fails to start");
            [NSException raise:MGSServerScriptException format:@"%@", errorReason];
        }
        
        // keep track of our search objects.
        // we could recover searchDict from netRequest but as we have it retain a ref
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys: mdQuery, MGSSearchKeyQuery, 
                                    netRequest, MGSSearchKeyRequest, 
                                    searchDict, MGSSearchKeyDictionary,
                                    nil];
        [_activeSearches addObject:dictionary];
        
        // if query starts okay then return YES.
        // reply will be sent when query terminates
        
        return YES;	
	
    }
    @catch (NSException *exception) {
        if (!mgsError) {
            mgsError = [MGSError serverCode:MGSErrorCodeSearchError reason:errorReason];
        }
        
        // insert error into reply script dict
        [replyDict setObject:[mgsError dictionary] forKey:MGSScriptKeyNSErrorDict];
        [[netRequest responseMessage] setMessageObject:replyDict forKey:MGSScriptKeyKosmicTask];
        
        return NO;	// caller will issue reply
    }
}

/*
 
 search query notification
 
 */
- (void) searchQueryNotification:(NSNotification *)note
{
    // the NSMetadataQuery will send back a note when updates are happening.
	NSMetadataQuery *mdQuery = [note object];
	
    // by looking at the [note name], we can tell what is happening
    if ([[note name] isEqualToString:NSMetadataQueryDidStartGatheringNotification])
    {
        // the query has just started
        MLog(DEBUGLOG, @"search: started gathering");
    }
    else if ([[note name] isEqualToString:NSMetadataQueryDidFinishGatheringNotification])
    {
        // at this point, the query will be done. You may recieve an update later on.
		MLog(DEBUGLOG, @"search: finished gathering");
		
		// no longer require notifcations for this object
        [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:mdQuery];
		
		// use query object to get our net request
		MGSServerNetRequest *netRequest = nil;
		NSDictionary *activeSearch = nil;
		NSDictionary *searchDict = nil;
		for (activeSearch in _activeSearches) {
			if ([activeSearch objectForKey:MGSSearchKeyQuery] == mdQuery) {
				netRequest = [activeSearch objectForKey:MGSSearchKeyRequest];
				searchDict = [activeSearch objectForKey:MGSSearchKeyDictionary];
				break;
			}
		}
		
		// if no request then we cannot send a reply!
		if (!netRequest) {
			MLog(DEBUGLOG, @"no query request object found");
			return;
		}
		
		// remove activeSearch from our active search array
		[_activeSearches removeObject:activeSearch];
		
		// process our query results for our request
		[self processSearchQueryResults:mdQuery forSearchDict:searchDict forRequest:netRequest];		
    }
    else if ([[note name] isEqualToString:NSMetadataQueryGatheringProgressNotification])
    {
        // the query is still gathering results...
		MLog(DEBUGLOG, @"search: progressing...");
    }
    else if ([[note name] isEqualToString:NSMetadataQueryDidUpdateNotification])
    {
        // an update will happen when Spotlight notices that a file as added,
        // removed, or modified that affected the search results.
		MLog(DEBUGLOG, @"search: an update happened.");
    }
}

/*
 
 process query results for request
 
 */
- (void)processSearchQueryResults:(NSMetadataQuery *)mdQuery forSearchDict:(NSDictionary *)searchDict forRequest:(MGSServerNetRequest *)netRequest
{
	// standard dec
	NSString *error = nil;
	//MGSError *mgsError = nil;
	NSMutableDictionary *replyDict = [NSMutableDictionary dictionaryWithCapacity:2];
	// end standard decs
	
	NSMutableArray *results = [NSMutableArray arrayWithCapacity:2];
	NSUInteger validResults = 0;
	
	@try {
		
		// form array of script dicts
		NSMutableArray *scripts = [NSMutableArray arrayWithCapacity:1];
		
		MLog(DEBUGLOG, @"search found %i items", [[mdQuery results] count]);
		
		NSString *userDocumentPath = [MGSPath userDocumentPath];
		NSString *applicationDocumentPath = [MGSScriptManager applicationDocumentPath];
		MLog(DEBUGLOG, @"userDocPath = %@, applicationDocPath = %@", userDocumentPath, applicationDocumentPath);
		
		// iterate through results
		for (NSUInteger i = 0; i < [[mdQuery results] count];  i++) {
			
			// get the result meta data item
			NSMetadataItem* item = [[mdQuery results] objectAtIndex: i];
			
			// get filepath and filename
			NSString *filepath = [item valueForAttribute:(NSString *)kMDItemPath];	
			NSString *filename = [filepath lastPathComponent];
			
			// validate filepath
			// ensure that we are only getting results for the user document and bundle path.
			// reqd due to the way that spotlight refuses to index application package paths directly, 
			// but will index if given app package enclosing folder,
			NSRange userRange = [filepath rangeOfString:userDocumentPath options:NSCaseInsensitiveSearch];
			NSRange bundleRange = [filepath rangeOfString:applicationDocumentPath options:NSCaseInsensitiveSearch];
			BOOL isUserDoc = userRange.location != NSNotFound ? YES : NO;
			BOOL isBundleDoc = bundleRange.location != NSNotFound ? YES : NO;
			
			// if not a user or a bundle doc then we don't want it
			if (!isUserDoc && !isBundleDoc) {
				MLog(RELEASELOG, @"search processor script at invalid path: %@", filepath);
			}
			
			// validate filename
			else if ((filename != nil) && ([filename length] > 0))
			{
				// discard extension
				filename = [filename stringByDeletingPathExtension];
				
				// validate as a UUID
				if ([filename mgs_isUUID]) {
					MLog(DEBUGLOG, @"search file match found: %@", filepath);
					
					// load script
					MGSError *mgsError = nil;
					//MGSScript *script = [self loadScriptWithUUID:filename error:&mgsError];
					MGSScript *script = [MGSScript scriptWithContentsOfFile:filepath error:&mgsError];
					if (script) {
						
						// flag bundle status as this is not retained within the script file
						[script setBundled:isBundleDoc];
						
						// get our search representation
						NSMutableDictionary *scriptDict = [script searchRepresentationDictionary];				
						if (scriptDict) {
							
							// add mutable script dict to our scripts array.
							// exceptions result if dict is not mutable
							[scripts addObject:scriptDict];
						}
						
					} else {
						MLog(RELEASELOG, @"search processor could not load script: %@", filepath);
					}
				} else {
					MLog(RELEASELOG, @"search file match invalid - non UUID filename: %@", filepath);
				}
			}
		}
		
		validResults = [scripts count];
		
		// authenticated user?
		BOOL authenticatedUser = [netRequest authenticate];
		if (!authenticatedUser) {
			
			// if the user is not authenticated then we only want to return published items 
			MGSServerScriptManager *scriptManager = [[MGSServerScriptManager alloc] init];
			[scriptManager setArray:scripts];	// assignment - not a copy
			//
			// the published state is not saved within the script but within the task dict.
			// hence we must consult the task dict to update our published state before
			// stripping out our unpublished items
			//
			[scriptManager setApplicationTaskDictionaryProperties]; 
			[scriptManager removeUnpublishedItems];
			scripts = [scriptManager array];	// not necessary - but makes things clear
		}
		
		// form results array
		for (NSDictionary *scriptDict in scripts) {
			NSMutableDictionary *searchResultDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:scriptDict, @"script", nil];
			[results addObject:searchResultDict];
		}
	} @catch(NSException *e) {
		error = [NSString stringWithFormat:@"An exception occurred processing search results: %@", [e reason]];
	}
	
	// return our search result
	// dict to hold our results
	NSMutableDictionary *resultDict = [NSMutableDictionary dictionaryWithCapacity:2];
	[resultDict setObject:results forKey:MGSScriptKeySearchResult];
	
	// return search ID
	NSNumber *searchID = [searchDict objectForKey:MGSScriptKeySearchID];
	if (!searchID) {
		MLog(RELEASELOG, @"search id not found");
		searchID = 0;
	}
	[resultDict setObject:searchID forKey:MGSScriptKeySearchID];
	
	// return number of results found even if not accessible
	[resultDict setObject:[NSNumber numberWithUnsignedInteger:validResults] forKey:MGSScriptKeyMatchCount];
	
	// add result dict to reply dict, flag as valid and send
	[replyDict setObject:resultDict forKey:MGSScriptKeyResult];
	
	// return error
	if (error) {
		
		MGSError *mgsError = [MGSError serverCode:MGSErrorCodeSearchError reason:error];
		
		// insert error into reply script dict
		[replyDict setObject:[mgsError dictionary] forKey:MGSScriptKeyNSErrorDict];
	}
	
	// send reponse
	[[netRequest responseMessage] setMessageObject:replyDict forKey:MGSScriptKeyKosmicTask];
	[self sendValidRequestReply:netRequest];	
}

@end

@implementation MGSServerScriptRequest (Script)
/*
 
 - getScriptUUID:forRequest:options:
 
 */
- (BOOL)getScriptUUID:(NSArray *)UUIDs forRequest:(MGSServerNetRequest *)netRequest options:(NSDictionary *)options
{
	// standard dec
	NSString *error = nil;
	MGSError *mgsError = nil;
	NSMutableDictionary *replyDict = [NSMutableDictionary dictionaryWithCapacity:2];
	// end standard decs
	
    @try {

        if (!UUIDs || [UUIDs count] == 0) {
            error = NSLocalizedString(@"No script UUID value", @"Returned by server when script UUID value not found");
            [NSException raise:MGSServerScriptException format:@"%@", error];
        }
        
        // sanity check
        // at present retrieves only first UUID	
        if ([UUIDs count] > 1) {
            MLog(RELEASELOG, @"More than one UUID passed. Only the first will be processed.");
        }
        
        // get UUID
        NSString *UUID = [UUIDs objectAtIndex:0];
        
        // load script with UUID
        MGSScript *fileScript = [self loadScriptWithUUID:UUID error:&mgsError];
        if (!fileScript) {
            [NSException raise:MGSServerScriptException format:@"%@", error];
        }
        
        // conform to a representation if required
        NSNumber *commandOption = [options objectForKey:MGSScriptKeyRepresentation];
        if (commandOption && [commandOption respondsToSelector:@selector(integerValue)]) {
            MGSScriptRepresentation representation = [commandOption integerValue];
            
            if (![fileScript conformToRepresentation:representation]) {
                mgsError = [MGSError serverCode:MGSErrorCodeInvalidScriptRepresentation];
                [NSException raise:MGSServerScriptException format:@"%@", error];
            }
        }
        
        // add script dict to reply dict, flag as valid and send
        [replyDict setObject:[fileScript dict] forKey:MGSScriptKeyScript];
        [[netRequest responseMessage] setMessageObject:replyDict forKey:MGSScriptKeyKosmicTask];
        [self sendValidRequestReply:netRequest];	
        
	return YES;
    }
    @catch (NSException *exception) {
        if (!mgsError) {
            mgsError = [MGSError serverCode:MGSErrorCodeGetScript reason:error];
        }
        
        // insert error into reply script dict
        [replyDict setObject:[mgsError dictionary] forKey:MGSScriptKeyNSErrorDict];
        [[netRequest responseMessage] setMessageObject:replyDict forKey:MGSScriptKeyKosmicTask];
        
        return NO;	// caller will issue reply
    }


}	

/*
 
 load script with UUID
 
 */
- (MGSScript *)loadScriptWithUUID:(NSString *)UUID  error:(MGSError **)mgsError
{
	// validate our UUID
	if (![UUID mgs_isUUID]) {
		MLog(RELEASELOG, @"Cannot load script. Script UUID is invalid.");
		return nil;
	}
	
	// form path to UUID in bundle
	NSString *scriptPath = [MGSScript fileUUID:UUID withPath:[MGSServerScriptManager applicationDocumentPath]];
	BOOL bundled = YES;
	
	// if bundle path does not exist then try user path
	if (![[NSFileManager defaultManager] fileExistsAtPath:scriptPath]) {
		scriptPath = [MGSScript fileUUID:UUID withPath:[MGSServerScriptManager userDocumentPath]];
		bundled = NO;
	}
	
	// try and load script from path
	MGSScript *script = [MGSScript scriptWithContentsOfFile:scriptPath error:mgsError];
	if (!script) {
		return nil;
	}
	
	// the script's bundled status is not saved within the script so set manually
	[script setBundled:bundled];
	
	return script;
}

//=======================================================
// execute a script
// return YES on success - reply will be sent when script task terminates
// return NO on failure - caller sends reply
//=======================================================
- (BOOL)executeScript:(MGSScript *)script forRequest:(MGSServerNetRequest *)netRequest
{
	// standard dec
	NSString *error = nil;
	MGSError *mgsError = nil;
	NSMutableDictionary *replyDict = [NSMutableDictionary dictionaryWithCapacity:2];
	NSInteger errorCode = MGSErrorCodeScriptExecute;
	// end standard decs
	
	NSAssert(script, @"script is nil");
	NSAssert(netRequest, @"net request is nil");	
	
	NSString *scriptPath;
	NSString *scriptTempPath = nil;
	
    @try {

        //
        // validate that this request can be executed
        //
        if (!LicenceValidForRequest(netRequest, &mgsError)) {
            [NSException raise:MGSServerScriptException format:@"%@", error];
        }
        
        //
        // if script scheduled for save then save it to a temporary location
        // prior to execution
        //
        // on 10.5.4 the NSTemporaryDirectory returns the likes of
        // /var/folders/O1/O1VcZT3YG1Ws5YoOeqU1IE+++TM/-Tmp-/
        //
        if ([script scheduleSave]) {
            
            NSString *tempDirectory = [[MGSTempStorage sharedController] storageDirectoryWithOptions:nil];
            [netRequest addScratchPath:tempDirectory];
            
            MLog(DEBUGLOG, @"Script scheduled for save: temp script copy in %@", tempDirectory);
            [script saveToPath:tempDirectory error:&mgsError];
            
            if (mgsError) {
                error = NSLocalizedString(@"Cannot create script copy in temp directory", @"Returned by server when script cannot be saved to temp directory");
                [NSException raise:MGSServerScriptException format:@"%@", error];
            }
            
            // script path
            scriptTempPath = [script UUIDWithPath:tempDirectory];
            scriptPath = scriptTempPath;
        } else {
            
            // script path
            scriptPath = [script UUIDWithPath:[script defaultPath]];
        }
        
        // validate script path
        if (!scriptPath || ![[NSFileManager defaultManager] fileExistsAtPath:scriptPath]) {
            error = NSLocalizedString(@"Task file cannot be found", @"Returned by server when task file not found");
            [NSException raise:MGSServerScriptException format:@"%@", error];
        }
        
        // form options
        NSMutableDictionary *options = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 scriptPath, MGSLangPluginExecutePath, 
                                 netRequest, MGSLangPluginNetRequest,
                                 nil];
        if (scriptTempPath) {
            [options setObject:scriptTempPath forKey:MGSLangPluginTempPath];
        }
        
        // get the task execution dictionary 
        NSDictionary *taskDict = [script executeTaskDictWithOptions:options error:&mgsError];	
        if (!taskDict) {
            [NSException raise:MGSServerScriptException format:@"%@", error];
        }
        
        // start the task
        NSError *err = nil;
        if (![self startTask:taskDict options:options error:&err]) {
            error = [err localizedDescription];
            [NSException raise:MGSServerScriptException format:@"%@", error];
        }
        
        return YES;
    }
    @catch (NSException *exception) {
        if (!mgsError) {
            mgsError = [MGSError serverCode:errorCode reason:error];
        }
        
        // insert error into reply script dict
        [replyDict setObject:[mgsError dictionary] forKey:MGSScriptKeyNSErrorDict];
        [[netRequest responseMessage] setMessageObject:replyDict forKey:MGSScriptKeyKosmicTask];
        
        return NO;
    }
}

//=======================================================
// get compiled script source for UUIDs
// return YES on success - reply sent
// return NO on failure - caller sends reply
//=======================================================
- (BOOL)getCompiledSourceForScriptUUID:(NSArray *)UUIDs forRequest:(MGSServerNetRequest *)netRequest
{
	NSString *error = nil;
	NSMutableDictionary *replyDict = [NSMutableDictionary dictionaryWithCapacity:2];
	NSInteger errorCode = MGSErrorCodeGetCompiledScriptSource;
	MGSError *mgsError = nil;
	NSString *UUID = @"No UUID";
	
    @try {

        if (!UUIDs || [UUIDs count] == 0) {
            error = NSLocalizedString(@"No script UUID value", @"Returned by server when script UUID value not found");
            [NSException raise:MGSServerScriptException format:@"%@", error];
        }
        
        // sanity check
        // at present retrieves only first UUID	
        if ([UUIDs count] > 1) {
            MLog(RELEASELOG, @"More than one UUID passed. Only the first will be processed.");
        }
        UUID = [UUIDs objectAtIndex:0];
        
        // form script path. look in application then in user docs
        NSString *scriptPath = [MGSScript fileUUID:UUID withPath:[MGSServerScriptManager applicationDocumentPath]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:scriptPath]) {
            scriptPath = [MGSScript fileUUID:UUID withPath:[MGSServerScriptManager userDocumentPath]];
        }
        
        //
        // we only need one key from the file so ther performance here can be greatly increased
        // simply loading the dict and extracting the required key.
        // creating a script object involves loading all the properties etc.
        //
        MGSScript *script = [MGSScript scriptWithContentsOfFile:scriptPath error:&mgsError];
        if (!script) {
            [NSException raise:MGSServerScriptException format:@"%@", error];
        }
        
        // get script source RTF
        NSData *rtfData = [[script scriptCode] rtfSource];
        if (!rtfData) {
            [NSException raise:MGSServerScriptException format:@"%@", error];
        }
        
        // return source.
        // if language normally returns RTF from a build then do the same here
        if ([[script languagePlugin] buildResultFlags] & kMGSScriptSourceRTF) {
        
            [replyDict setObject:rtfData forKey:MGSScriptKeyCompiledScriptSourceRTF];
        
        } else {
        
            NSAttributedString *attributedSource = [[NSAttributedString alloc] initWithRTF:rtfData documentAttributes:nil];
            NSString *source = [attributedSource string];
            [replyDict setObject:source forKey:MGSScriptKeyScriptSource];
        
        }
        
        [[netRequest responseMessage] setMessageObject:replyDict forKey:MGSScriptKeyKosmicTask];
        [self sendValidRequestReply:netRequest];	
        
        return YES;
	
    }
    @catch (NSException *exception) {
        if (!mgsError) {
            error = [NSString stringWithFormat:@"%@ UUID = %@", error, UUID];
            mgsError = [MGSError serverCode:errorCode reason:error];
        }
        
        // insert error into reply script dict
        [replyDict setObject:[mgsError dictionary] forKey:MGSScriptKeyNSErrorDict];
        [[netRequest responseMessage] setMessageObject:replyDict forKey:MGSScriptKeyKosmicTask];
        
        return NO;	// caller will issue reply
    }
}


//=======================================================
// compile a script
// return YES on success - reply sent
// return NO on failure - caller sends reply
//=======================================================
- (BOOL)compileScript:(MGSScript *)script forRequest:(MGSServerNetRequest *)netRequest
{
	// GC deemed incompatible with AppleScript under Leopard.
	// use task to run all AppleScript tasks
	
	// standard dec
	NSString *error = nil;
	MGSError *mgsError = nil;
	NSMutableDictionary *replyDict = [NSMutableDictionary dictionaryWithCapacity:2];
	NSInteger errorCode = MGSErrorCodeScriptBuild;
	// end standard decs
	
	NSAssert(script, @"script is nil");
	NSAssert(netRequest, @"net request is nil");	

    @try {

        // form options
        NSMutableDictionary *options = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        netRequest, MGSLangPluginNetRequest,
                                        nil];
        
        // get the task execution dictionary 
        NSDictionary *taskDict = [script buildTaskDictWithOptions:options error:&mgsError];	
        if (!taskDict) {
            [NSException raise:MGSServerScriptException format:@"%@", error];
        }
            
        // start the task
        NSError *err = nil;
        if (![self startTask:taskDict options:options error:&err]) {
            error = [err localizedDescription];
            [NSException raise:MGSServerScriptException format:@"%@", error];
        }
        
        return YES;

    }
    @catch (NSException *exception) {
        if (!mgsError) {
            mgsError = [MGSError serverCode:errorCode reason:error];
        }
        
        // insert error into reply script dict
        [replyDict setObject:[mgsError dictionary] forKey:MGSScriptKeyNSErrorDict];
        [[netRequest responseMessage] setMessageObject:replyDict forKey:MGSScriptKeyKosmicTask];
        
        return NO;
    }

}
@end

@implementation MGSServerScriptRequest (Task)

/*
 
 start task
 
 */
- (BOOL)startTask:(NSDictionary *)taskDict options:(NSDictionary *)options error:(NSError **)error
{
	// serialise the dict so that it can be sent to the task's stdin
	NSData *taskData = [NSKeyedArchiver archivedDataWithRootObject:taskDict];
	NSAssert(taskData, @"script task dictionary nil");
	
	MGSServerNetRequest *netRequest = [options objectForKey:MGSLangPluginNetRequest];
	NSAssert(netRequest, @"net request is nil");
	
	// create script task
	MGSScriptTask *scriptTask = [[MGSScriptTask alloc] initWithNetRequest:netRequest];
	[scriptTask setDelegate: self];
	
	// set temp path
	NSString *scriptTempPath = [options objectForKey:MGSLangPluginTempPath];
	if (scriptTempPath) {
		[scriptTask addTempFilePath:scriptTempPath];
	}
	
	// get task process path
	NSString *processPath = [taskDict objectForKey:MGSScriptRunnerProcessPath];
	
	// start the task.
	// will send -taskDidTerminate: when complete
	if (![scriptTask start:processPath data:taskData withError:error]) {
		return NO;
	}
	
	// add to script tasks array
	[_scriptTasks setObject:scriptTask forKey:[netRequest.requestMessage messageUUID]];
	
#ifdef MGS_LOG_TASK_REQUEST_UUID_ACTIVITY
    NSLog(@"Executing task for request UUID: %@", [netRequest.requestMessage messageUUID]);
#endif
    
	return YES;
}

/*
 
 task did terminate
 
 */
- (void) taskDidTerminate:(id)aTask
{
	// int waitx = 1; while (waitx);
	
	MGSScriptTask *scriptTask = aTask;
	MGSServerNetRequest *netRequest = [scriptTask netRequest];
	NSString *workingDirectory = nil;
	NSDictionary *errorDict = nil;
	
	// remove task
	[_scriptTasks removeObjectForKey:netRequest.UUID];
	
	NSAssert(netRequest, @"net request is nil");
	
	id taskOutput = nil;
	NSMutableDictionary *replyDict = [NSMutableDictionary new];
	NSString *error = nil;
	MGSError *mgsError = nil;
	NSInteger errorCode = MGSErrorCodeScriptExecute;
    NSString *taskStdError = nil;
    
    @try {
        // get error data representing stderr

        @try {
            NSData *taskStdErrorData = [scriptTask taskErrorData];
            taskStdError = [[NSString alloc] initWithData:taskStdErrorData encoding:NSUTF8StringEncoding];
        } @catch (NSException *e) {
            MLog(RELEASELOG, @"Exception unarchiving task error data: %@", e);
        }

        // exception occurring on occasion
        /*
         General Exception Conditions
         
         While unarchiving, NSUnarchiver performs a variety of consistency checks on the incoming data stream. 
         NSUnarchiver raises an NSInconsistentArchiveException for a variety of reasons. Possible data errors 
         leading to this exception are: unknown type descriptors in the data file; an array type descriptor is 
         incorrectly terminated (missing ]); excess characters in a type descriptor; a null class found where a 
         concrete class was expected class not loaded.
         */
        @try {
            NSMutableData *taskOutputData = [scriptTask taskOutputData];
            NSString *plistError = nil;
            NSPropertyListFormat format;		
            taskOutput = [NSPropertyListSerialization propertyListFromData:taskOutputData mutabilityOption:NSPropertyListMutableContainersAndLeaves format:&format errorDescription:&plistError];
            if (plistError) {
                error = NSLocalizedString(@"Could not unarchive task output: ", @"script task error");
                error = [error stringByAppendingString:plistError];
                taskOutput = nil;
                [NSException raise:MGSServerScriptException format:@"%@", error];
            }
        } @catch (NSException *e) {
            MLog(RELEASELOG, @"Exception unarchiving task output data: %@", e);
            error = NSLocalizedString(@"Exception unarchiving task output", @"script task error");
            taskOutput = nil;
            [NSException raise:MGSServerScriptException format:@"%@", error];
        }
        
        // we are expecting a dictionary
        if (![taskOutput isKindOfClass:[NSDictionary class]]) {
            MLog(DEBUGLOG, @"taskOutput class is %@", [taskOutput className]);
            error = NSLocalizedString(@"Invalid data returned by script task", @"script task error");
            [NSException raise:MGSServerScriptException format:@"%@", error];
        }
        
        // get task reply dict
        replyDict = [NSMutableDictionary dictionaryWithDictionary:taskOutput];

        // external tasks (those that run out of process with the task runner) will 
        // execute within a working directory
        workingDirectory = [replyDict objectForKey:MGSScriptWorkingDirectory];

        // check for errors
        errorDict = [replyDict objectForKey:MGSScriptError];
        if (errorDict)
        {
            error = [errorDict objectForKey:MGSScriptError];
            errorCode = [[errorDict objectForKey:MGSScriptErrorCode] integerValue];
            NSDictionary *errorInfo = [errorDict objectForKey:MGSScriptErrorInfo];
            
            if (!errorInfo) {
                mgsError = [MGSError domain:MGSErrorDomainMotherScriptTask code:errorCode reason:error log:YES];
            } else {
                mgsError = [MGSError domain:MGSErrorDomainMotherScriptTask code:errorCode userInfo:errorInfo log:YES];
            }
            
            [NSException raise:MGSServerScriptException format:@"%@", error];
        }
        
        // get the script result object.
        // the task returns a result dict in which the resultObject is defined
        id resultObject = [[replyDict objectForKey:MGSScriptKeyResult] objectForKey:MGSScriptKeyResultObject];
        
        //
        // look for a string result that looks like an FScript plist representation.
        // this will enable us to simulate the return of true plist from bridges.
        // 
        // dictionary #{'key 1' -> 'item 1', 'key 2' ->'item 2'} 
        // array {'item 1', 'item 2'}
        // if we find a likely candidate we make a block out of it and get its value
        //
        // if F-Script doesn't match try YAML
        //
        if ([resultObject isKindOfClass:[NSString class]]) {

            NSString *resultString = [resultObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];		

    #ifdef MGS_PARSE_RESULT_AS_FSCRIPT
            // a YAML representation is MUCH easier to construct
            
            // look for a F-Script candidate
            if (([resultString hasPrefix:@"#{"] || [resultString hasPrefix:@"{"]) && 
                [resultString hasSuffix:@"}"]) {

                MLogDebug(@"F-Script candidate result string = %@", resultString);

                // create block and execute 
                // see http://www.fscript.org/documentation/EmbeddingFScriptIntoCocoa/index.htm
                @try {
                    NSString *resultBlock = [NSString stringWithFormat:@"[ %@ ]", resultString];
                    FSBlock *block = [resultBlock asBlock];
                    id blockResult = [block value];	// evaluate the block
                
                    //
                    // blockResult MUST be serializable.
                    // if it isn't then coerce it into a plist
                    //
                    if (![NSPropertyListSerialization propertyList:blockResult isValidForFormat:NSPropertyListXMLFormat_v1_0]) {
                        blockResult = [NSPropertyListSerialization coercePropertyList:blockResult];
                    }
                    
                    // we have a new result object
                    resultObject = blockResult;
                    
                    // update the reply dictionary
                    [[replyDict objectForKey:MGSScriptKeyResult] setObject:resultObject forKey:MGSScriptKeyResultObject];
                    
                } @catch (NSException* e) {	
                    // we had a candidate but F-Script failed to
                    // get the value of it as a block.
                    // so we retain the original string rep.
                    
                    // just log it
                    MLogInfo(@"Could not get value of candidate result % @ \n error : %@", resultString, [e reason]);
                }
            }

    #endif

    #ifdef MGS_PARSE_RESULT_AS_YAML
            
            // look for a YAML candidate.
            // this must start with YAML document marker ---.
            // if we don't apply this restriction the exact form of the returned result
            // is a bit unpredictable especially if the result is of the form < a> : <b >.
            // this will most likely get returned as a dictionary rather than string.
            if (resultString) {
                
                NSScanner *scanner = [NSScanner scannerWithString:resultString];
                [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
                BOOL yamlDoc = [scanner scanString:@"---" intoString:NULL];
                
                if (yamlDoc) {

                    MLogDebug(@"YAML candidate result string = %@", resultString);

                    // YAMLKit
                    @try {
                        BOOL useYamlResult = NO;
                        
                        id yamlResult = [YAMLKit loadFromString:resultString];	// evaluate the block
                        if ([yamlResult isKindOfClass:[NSString class]]) {
                            if ([(NSString *)yamlResult length] > 0) {
                                useYamlResult = YES;
                            }
                        } else if ([yamlResult isKindOfClass:[NSDictionary class]]) {
                            if ([(NSDictionary *)yamlResult count] > 0) {
                                useYamlResult = YES;
                            }
                        } else if ([yamlResult isKindOfClass:[NSArray class]]) {
                            if ([(NSArray *)yamlResult count] > 0) {
                                useYamlResult = YES;
                            }
                        } 
                        
                        if (useYamlResult) {
                            //
                            // yamlResult MUST be serializable.
                            // if it isn't then coerce it into a plist
                            //
                            if (![NSPropertyListSerialization propertyList:yamlResult isValidForFormat:NSPropertyListXMLFormat_v1_0]) {
                                yamlResult = [NSPropertyListSerialization coercePropertyList:yamlResult];
                            }
                            
                            // we have a new result object
                            resultObject = yamlResult;
                            
                            // update the reply dictionary
                            [[replyDict objectForKey:MGSScriptKeyResult] setObject:resultObject forKey:MGSScriptKeyResultObject];
                        }
                        
                    } @catch (NSException* e) {	
                        // we had a candidate but yamlResult failed to
                        // get the value of it as aN NSObject.
                        // so we retain the original string rep.
                        
                        // just log it
                        MLogInfo(@"Could not get value of candidate result % @ \n error : %@", resultString, [e reason]);
                    }
                }
            }
        }
        
    #endif
        
        //
        // look for a dictionary result
        //
        if ([resultObject isKindOfClass:[NSDictionary class]]) {
            
            NSMutableDictionary *resultObjectDict = resultObject;
            
            //
            // look for the kosmicFile object.
            //
            // this will contain path/paths to files to be returned to the client
            // at present we only look at top level of result dictionary
            //
            // TODO: iterate through dict children and look for matching sub keys
            //
            id kosmicFileObject = nil;
            NSString *kosmicFileObjectKey = nil;
            NSString *kosmicFileKeyName = nil;
            NSArray *kosmicFileKeyNames = [MGSResultFormat fileDataKeys];
            
            for (kosmicFileKeyName in kosmicFileKeyNames) {
                for (NSString *key in [resultObjectDict allKeys]) {
                    if ([[key lowercaseString] isEqualToString:kosmicFileKeyName]) {
                        kosmicFileObject = [resultObjectDict objectForKey:key];
                        kosmicFileObjectKey = key;
                        goto for_done;
                    }
                }
            }
            
        for_done:;
            
            NSArray *kosmicFileArray = nil;
            
            //
            // process the kosmicFile object
            //
            if (kosmicFileObject) {

                // array of files
                if ([kosmicFileObject isKindOfClass:[NSArray class]]) {
                    kosmicFileArray = kosmicFileObject;
                    
                // single file
                } else if ([kosmicFileObject isKindOfClass:[NSString class]]) {
                    kosmicFileArray = [NSArray arrayWithObject:kosmicFileObject];
                } else {
                    // cannot do anything with this result
                    kosmicFileObject = nil;
                    kosmicFileKeyName = nil;
                }
                
            }
            
            NSMutableDictionary *newMotherDict = [NSMutableDictionary dictionaryWithCapacity:1];
                    
            //
            // process the array of files to be returned to client
            //
            if (kosmicFileArray) {
                
                NSString *filePath = nil; 
                MGSNetAttachments *netAttachments = [MGSNetAttachments new];
                NSUInteger i = 0;
                
                for (id item in kosmicFileArray) {
                    id newDictObject = nil;
                    ++i;
                    NSString *newKey = [NSString stringWithFormat:NSLocalizedString(@"item %u", @"Item number in record as return to user"), i];

                    //
                    // get file path
                    //
                    if ((filePath = [item isKindOfClass:[NSString class]] ? item : nil)) {
                        
                        // normalise our path
                        filePath = [filePath stringByExpandingTildeInPath];
                        filePath = [filePath stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        //
                        // filePath may be POSIX or HFS as HFS is commonplace within AppleScript.
                        //
                        // It would be better to deal with this issue closer to the source 
                        // and avoid passing HFS paths at all
                        //
                        // I could try and coerce everything like so
                        // NSString *hfsPath = [[aed coerceToDescriptorType:typeFileURL] stringValue];
                        // But a script can receive and return a POSIX path as a string in which
                        // case there is no file type object to coerce.
                        //
                        // Coercion might work if on exit the kosmicfile record is detected and
                        // every item in just it is coerced into a known type.
                        //
                        
                        // POOR
                        // forming a POSIX style NSURL with a HFS filepath results
                        // in an NSURL instance with a corrupt path
                        //
                        /*
                        NSURL *posixURL = [NSURL nd_URLWithFileSystemPathPOSIXStyle:filePath];
                        if (![[posixURL path] isEqualToString:filePath]) {
                        NSURL *hfsURL = [NSURL nd_URLWithFileSystemPathHFSStyle:filePath];
                        filePath =[hfsURL nd_fileSystemPathPOSIXStyle];
                        }
                        */
                        
                        /* 
                         
                         if found convert a file url to path url
                         http://en.wikipedia.org/wiki/File_URI_scheme
                         
                         */
                        NSString *lcFilePath = [filePath lowercaseString];
                        if ([lcFilePath hasPrefix:@"file://localhost/"]) {
                            filePath = [filePath substringFromIndex: [@"file://localhost" length]];
                        } else if ([lcFilePath hasPrefix:@"file:///"]) {
                            filePath = [filePath substringFromIndex: [@"file://" length]];
                        }
                        

                        //
                        // assume path is HFS if it contains a colon.
                        // colon is not a valid file name character at the carbon layer.
                        // it is at the Unix layer, apparently.
                        //
                        // http://en.wikipedia.org/wiki/Filename
                        //
                        NSRange hfsPathSepRange = [filePath rangeOfString:@":"];
                        if  (hfsPathSepRange.location != NSNotFound) {
                            
                            NSURL *hfsURL = [NSURL nd_URLWithFileSystemPathHFSStyle:filePath];
                            NSString *proposedFilePath =[hfsURL nd_fileSystemPathPOSIXStyle];
                            
                            // if the proposed file path is valid then use it, otherwise discard
                            if ([[NSFileManager defaultManager] fileExistsAtPath:proposedFilePath]) {
                                filePath = proposedFilePath;
                            }
                            
                        } 
                        
                        //
                        // if we have a working directory then check for a relative path
                        //
                        else if (workingDirectory) {
                            
                            // if path is not absolute then make it relative to the working directory
                            if (![filePath isAbsolutePath]) {
                                filePath = [workingDirectory stringByAppendingPathComponent:filePath];
                            }
                        }
                                
                        //
                        // add attachment
                        //
                        // file path must be POSIX here
                        //
                        MGSNetAttachment *attachment = [netAttachments addAttachmentToExistingReadableFile:filePath];
                        
                        // if filepath was not valid then raise error
                        if (attachment) {
                            newDictObject = [NSString stringWithFormat:@"%@", [attachment lastPathComponent]];
                            newKey = [attachment validatedTitle];
                        } else {
                            MLog(RELEASELOG, @"Task returned invalid file in record: %@", filePath);
                            NSString *missingFile = [MGSNetAttachment lastPathComponent:filePath];
                            if (!missingFile) {
                                missingFile = @"(none)";
                            }
                            error = [NSString stringWithFormat:@"The task result includes an invalid or missing file path: %@", missingFile];
                            [NSException raise:MGSServerScriptException format:@"%@", error];
                            newDictObject = item;
                        }
                        
                    } else {
                        MLog(RELEASELOG, @"Task returned object of invalid type in record: %@", [item className]);
                        error = @"The task result includes an invalid file type";
                        [NSException raise:MGSServerScriptException format:@"%@", error];
                        newDictObject = item;
                    }
                    
                    if (newDictObject) {
                        [newMotherDict setObject:newDictObject forKey:newKey];
                    }
                }
                
                if ([netAttachments count] > 0) {
                    netRequest.responseMessage.attachments = netAttachments;
                }
            }
            
            // remove the kosmicFileObjectKey from the result dict
            // and replace with new dict.
            // we remove the keyed object explicitly as the key character
            // case may be different (we allow for variable key case)
            if (kosmicFileObject && kosmicFileKeyName && kosmicFileArray) {
                [resultObjectDict removeObjectForKey:kosmicFileObjectKey];
                [resultObjectDict setObject:newMotherDict forKey:kosmicFileKeyName];
            }
        }
        // fall through to exit
	}
    @catch (NSException *e) {
        // no-op
    }
	@finally {

        /* 
         
         schedule remove working task directory for out of process tasks
         
         removing the working directory in the task it self causes runloop based tasks
         such as RubyCocoa to raise a bus error

         out of process tasks may also create temporary files in their working directory that
         act as attachments and cannot be deleted until the attachments have been sent.
         
         so we add the working directory to the netrequest's list of scratch paths.
         
         */
        if (workingDirectory) {	
            [netRequest addScratchPath:workingDirectory];
        }

        // the inprocess task may also create temp files in its current directory path.
        // should there just be one working directory for both in and out of process tasks?
        // at present and out of process task creates two working directories.
        // one for the in process caller - which probably doesn't get used -
        // and another for the out of process task.
        [netRequest addScratchPath:scriptTask.workingDirectoryPath];

        /*
         
         schedule scratch paths for deletion
         
         this schedules scratch paths created by the task for deletion.
         this may well be unneccessary as the task should create its temp files
         in its working directory.
         
         */
        NSArray *scratchPaths = [replyDict objectForKey:MGSScriptScratchPaths];
        if (scratchPaths && [scratchPaths count] > 0) {
            for (NSString *scratchPath in scratchPaths) {
                [netRequest addScratchPath:scratchPath];
            }
        }

        // build error object if required
        if (error && !mgsError) {
            mgsError = [MGSError serverCode:MGSErrorCodeScriptExecute reason:error];
        }
        
        // return error
        if (mgsError) {
            //replyDict = [NSMutableDictionary dictionaryWithCapacity:1];
            [replyDict removeObjectForKey:MGSScriptError];
            [replyDict setObject:[mgsError dictionary] forKey:MGSScriptKeyNSErrorDict];
        }
        
        // return stderr
        if (taskStdError && [taskStdError length] > 0) {
            [replyDict setObject:taskStdError forKey:MGSScriptKeyStdError];
        }
        
        // add data to reply dict, flag as valid and send
        [[netRequest responseMessage] setMessageObject:replyDict forKey:MGSScriptKeyKosmicTask];
        
        [self sendValidRequestReply:netRequest];
    }
}
@end

/* 

 can execute request
 
 */
static BOOL LicenceValidForRequest(MGSServerNetRequest *netRequest, MGSError **mgsError)
{
	static NSMutableDictionary *licencedConnections = nil;

	NSString *errorReason = nil;
	NSInteger errorCode = MGSErrorCodeLicenceRestrictionImposed;

    @try {
        //
        // initialise our licenced connections
        //
        if (!licencedConnections) {
            licencedConnections = [NSMutableDictionary dictionaryWithCapacity:10];
        }
            
        //
        //
        // impose trial licence restriction
        //
        //
        BOOL isTrial = (MGSAPLicenceIsRestrictiveTrial() && TRIAL_RESTRICTS_FUNCTIONALITY);
        if (isTrial && ++totalExecutionCount > MGS_TRIAL_MAX_SERVER_TASK_EXECUTIONS) {
            errorCode = MGSErrorCodeTrialRestrictionImposed;
            errorReason =  NSLocalizedString(@"Sorry, cannot execute task. Trial version task execute limit exceeded.", @"Trial execute limit exceeded");
            [NSException raise:MGSServerScriptException format:@"%@", errorReason];
        }
        
        //
        //
        // impose licence seat restrictions
        //
        // 1. each execute request has to include one or more valid licences.
        // 2. the server maintains a connection dictionary keyed by the licence data.
        // 3. the server maintains a set of origins for each licence.
        // 4. a new origin will be accepted if doing so will not exceed the licences seat count
        //
        BOOL canProcessRequest = NO;
        NSArray *licenceDataArray = [[netRequest requestMessage] appData];
        NSDictionary *requestOrigin = [[netRequest requestMessage] messageOrigin];
        NSUInteger totalSeatCount = 0;
        
        //
        // we must have an origin
        //
        if (!requestOrigin) {
            MLogInfo(@"request origin missing");
            return NO;
        }
        
        //
        // if licence data present then validate it
        //
        if (licenceDataArray) {
            
            // search request licence data
            for (id plist in licenceDataArray) {
                
                // load licence and validate
                MGSL *licence = [[MGSL alloc] initWithPlist:plist];
                if (![licence valid]) {
                    MLogInfo(@"Invalid licence data received from origin: %@", requestOrigin);
                    continue;
                }

                // build total seat count
                totalSeatCount += [licence seatCount];

                // licence data is the key
                NSMutableDictionary *connectionDict = [licencedConnections objectForKey:plist];
                
                // if licence has not been previously used then add to licenced connections
                if (!connectionDict) {
                    connectionDict = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
                                      [NSMutableSet setWithObject:requestOrigin], @"origins",
                                      [NSMutableSet setWithObject:plist], @"data",
                                      nil];
                    
                    [licencedConnections setObject:connectionDict forKey:plist];
                    canProcessRequest = YES;

        #ifdef MGS_DEBUG_LICENCE
                    MLogDebug(@"Licence accepted from origin: %@", requestOrigin);
        #endif		
                    break;
                }
                
                // connection has already been made with this licence.
                // check for existing origin.
                // if origin has previously been licenced then accept.
                NSMutableSet *origins = [connectionDict objectForKey:@"origins"];
                if ([origins containsObject:requestOrigin]) {
                    
        #ifdef MGS_DEBUG_LICENCE
                    MLogDebug(@"Licensed execution from origin: %@", requestOrigin);
        #endif			
                    canProcessRequest = YES;
                    break;			
                }
                
                // check that origin can be accepted without exceeding seat count
                NSUInteger originCount = [origins count];
                if (++originCount <= [licence seatCount]) {
                    [origins addObject:requestOrigin];
                    canProcessRequest = YES;
                    break;
                }
                
                // all seats used for current licence.
                // check for more available licences.
            }
        }
        
        //
        // no licence data supplied
        // validate that origin is licenced 
        //
        else {
            //
            // iterate over all licenced connections and search for origin
            //
            for (NSMutableDictionary *connectionDict in [licencedConnections allValues]) {
                NSMutableSet *origins = [connectionDict objectForKey:@"origins"];
                if ([origins containsObject:requestOrigin]) {
                    
    #ifdef MGS_DEBUG_LICENCE
                    MLogDebug(@"Licensed execution from origin: %@", requestOrigin);
    #endif			
                    canProcessRequest = YES;
                    break;			
                }
            }
        }
        
        // return if valid
        if (canProcessRequest) {
            return YES;
        }
        

    #ifdef MGS_DEBUG_LICENCE
        MLogDebug(@"Unlicensed execution request from origin: %@", requestOrigin);
    #endif		
        errorCode = MGSErrorCodeLicenceRestrictionImposed;
        NSString *fmt =  NSLocalizedString(@"Licensed connection count (%i) exceeded. Please install another licence file (%i found).", @"Licensed connection count exceeded");
        errorReason = [NSString stringWithFormat:fmt, totalSeatCount, [licenceDataArray count]];
	
        [NSException raise:MGSServerScriptException format:@"%@", errorReason];
        
    }
    @catch (NSException *e) {
	
        *mgsError = [MGSError serverCode:errorCode reason:errorReason];
    }
	
	return NO;
}
