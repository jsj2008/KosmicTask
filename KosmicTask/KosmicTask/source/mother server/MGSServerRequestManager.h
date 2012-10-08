//
//  MGSServerRequestManager.h
//  Mother
//
//  Created by Jonathan on 04/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSNetRequestManager.h"
#import "MGSServerNetRequest.h"

@class MGSAsyncSocket;
@class MGSServerScriptRequest;
@class MGSServerPreferencesRequest;
@class MGSNetSocket;
@class MGSError;

@interface MGSServerRequestManager : MGSNetRequestManager {
	MGSServerScriptRequest *_scriptController;
	BOOL _initialised;
}

+ (id)sharedController;
- (MGSServerNetRequest *)requestWithConnectedSocket:(MGSNetSocket *)socket;
- (void)parseRequestMessage:(MGSServerNetRequest *)request;
- (BOOL)initialise;
- (void)authenticationFailed:(MGSServerNetRequest *)netRequest;
- (void)sendErrorResponse:(MGSServerNetRequest *)netRequest error:(MGSError *)mgsError isScriptCommand:(BOOL)isScriptCommand;
- (BOOL)concludeRequest:(MGSServerNetRequest *)netRequest;
- (void)disconnectAllRequests;
- (void)sendResponseOnSocket:(MGSServerNetRequest *)netRequest wasValid:(BOOL)valid;

@property (readonly) BOOL initialised;
@end
