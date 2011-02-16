//
//  MGSScriptTask.m
//  Mother
//
//  Created by Jonathan Mitchell on 29/12/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import "MGSScriptTask.h"
#import "MGSNetRequest.h"
#import "MLog.h"

@implementation MGSScriptTask 

@synthesize netRequest = _netRequest;

/*
 
 init
 
 */
- (MGSScriptTask *)init
{
	return [self initWithNetRequest:nil];
}

/*
 
 init with net request
 
 */
- (MGSScriptTask *)initWithNetRequest:(MGSNetRequest *)netRequest
{
	if ((self = [super init])) {
		NSAssert(netRequest, @"net request is nil");
		_netRequest = netRequest;
	}
	return self;
}

/*
 
 finalize
 
 */
- (void) finalize
{
	MLog(DEBUGLOG, @"finalized");
	[super finalize];
}

@end
