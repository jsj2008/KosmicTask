//
//  MGSServerRequestManager.h
//  Mother
//
//  Created by Jonathan on 04/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSNetRequestManager.h"

@class MGSNetRequest;
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
- (MGSNetRequest *)requestWithConnectedSocket:(MGSNetSocket *)socket;
- (void)parseRequestMessage:(MGSNetRequest *)request;
- (BOOL)initialise;
- (void)authenticationFailed:(MGSNetRequest *)netRequest;
- (void)sendErrorResponse:(MGSNetRequest *)netRequest error:(MGSError *)mgsError isScriptCommand:(BOOL)isScriptCommand;
- (BOOL)concludeRequest:(MGSNetRequest *)netRequest;
- (void)disconnectAllRequests;

@property (readonly) BOOL initialised;
@end
