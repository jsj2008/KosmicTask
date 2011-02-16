//
//  MGSServerScriptRequest.h
//  Mother
//
//  Created by Jonathan Mitchell on 29/12/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSScriptTask.h"
#import "MGSServerRequestProcessor.h"

@class MGSNetRequest;
@class MGSServerScriptManager;
@class MGSServerTaskConfiguration;

@interface MGSServerScriptRequest : MGSServerRequestProcessor <MGSTaskDelegate> {
	MGSServerScriptManager *_publishedScriptManager;
	MGSServerScriptManager *_scriptManager;
	MGSServerTaskConfiguration *_taskConfiguration;
	
	NSMutableDictionary *_scriptTasks;
	BOOL _initialised;
	BOOL _processRequests;
	NSMutableArray *_activeSearches;
}

- (NSString *) userApplicationSupportPath;
- (BOOL)loadScriptManagers;
- (BOOL)concludeNetRequest:(MGSNetRequest *)netRequest;


@property (readonly) BOOL initialised;
@end
