//
//  MGSClientRequestManager.h
//  Mother
//
//  Created by Jonathan on 30/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSNetRequestManager.h"

@class MGSClientNetRequest;
@class MGSNetClient;
@class MGSTaskSpecifier;
@protocol MGSNetRequestOwner;


@interface MGSClientRequestManager : MGSNetRequestManager  {

}

+ (id)sharedController;

// request the script dictionary for a net client
- (void)requestScriptDictForNetClient:(MGSNetClient *)netClient isPublished:(BOOL)published withOwner:(id <MGSNetRequestOwner>)owner;

// send a simple heartbeat message to a net client
- (MGSClientNetRequest *)requestHeartbeatForNetClient: (MGSNetClient *)netClient withOwner:(id <MGSNetRequestOwner>)owner;

// request authentication
- (MGSClientNetRequest *)requestAuthenticationForNetClient:(MGSNetClient *)netClient withOwner:(id <MGSNetRequestOwner>)owner;

// save changes for client to host
- (void)requestSaveConfigurationChangesForNetClient:(MGSNetClient *)netClient withOwner:(id <MGSNetRequestOwner>)owner republish:(BOOL)republish;

// save edits for client to host
- (void)requestSaveEditsForNetClient:(MGSNetClient *)netClient withOwner:(id <MGSNetRequestOwner>)owner republish:(BOOL)republish;

// save task to host
- (MGSClientNetRequest *)requestSaveTask:(MGSTaskSpecifier *)task withOwner:(id <MGSNetRequestOwner>)owner;

// execute an task
- (MGSClientNetRequest *)requestExecuteTask:(MGSTaskSpecifier *)task withOwner:(id <MGSNetRequestOwner>)owner;

// terminate an executing task
- (void)requestTerminateTask:(MGSTaskSpecifier *)task withOwner:(id <MGSNetRequestOwner>)owner;

// suspend an executing task
- (void)requestSuspendTask:(MGSTaskSpecifier *)task withOwner:(id <MGSNetRequestOwner>)owner;

// resume an executing task
- (void)requestResumeTask:(MGSTaskSpecifier *)task withOwner:(id <MGSNetRequestOwner>)owner;

// request compiled script for task
- (void)requestCompiledScriptSourceForTask:(MGSTaskSpecifier *)task withOwner:(id <MGSNetRequestOwner>)owner;

// request script compilation for task
- (void)requestBuildTask:(MGSTaskSpecifier *)task withOwner:(id <MGSNetRequestOwner>)owner;

// request script with UUID on net client
- (MGSClientNetRequest *)requestScriptWithUUID:(NSString *)UUID netClient:(MGSNetClient *)netClient withOwner:(id <MGSNetRequestOwner>)owner options:(NSDictionary *)options;

// request net client search
- (MGSClientNetRequest *)requestSearchNetClient:(MGSNetClient *)netClient searchDict:(NSDictionary *)searchDict withOwner:(id <MGSNetRequestOwner>)owner;

- (void)sendRequestOnClient:(MGSClientNetRequest *)request;
@end
