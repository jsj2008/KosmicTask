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

#import "MGSServerScriptRequest.h"
#import "MGSServerPreferencesRequest.h"
#import "MGSNetSocket.h"
#import "MGSError.h"

@interface MGSServerRequestManager : MGSNetRequestManager {
	MGSServerScriptRequest *_scriptController;
	BOOL _initialised;
}

+ (id)sharedController;
- (MGSServerNetRequest *)requestWithConnectedSocket:(MGSNetSocket *)socket;
- (void)parseRequestMessage:(MGSServerNetRequest *)request;
- (void)disconnectAllRequests;
- (void)sendResponseOnSocket:(MGSServerNetRequest *)netRequest wasValid:(BOOL)valid;

@property (readonly) BOOL initialised;
@end
