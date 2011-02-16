//
//  MGSNetRequestManager.m
//  Mother
//
//  Created by Jonathan on 04/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSMother.h"
#import "MGSNetRequestManager.h"
#import "MGSNetRequest.h"
#import "MGSNetMessage.h"
#import "MGSNetClient.h"
#import "MGSMemoryManagement.h"

@implementation MGSNetRequestManager

@synthesize netRequests = _netRequests;

/*
 
 init
 
 */
- (id)init
{
	if ((self = [super init])) {
		_netRequests = [[NSMutableArray alloc] init];
	}
	return self;
}

/*
 
 remove request
 
 */
- (void)removeRequest:(MGSNetRequest *)netRequest
{

	if (![_netRequests containsObject:netRequest]) {
		return;
	}
	
	// we are done with this request
	[netRequest dispose];
	
	// remove the request
	[_netRequests removeObject:netRequest];
	MLog(DEBUGLOG, @"removeRequest: request handler count is now %i", [_netRequests count]);
}

/*
 
 count
 
 */
-(NSUInteger)requestCount
{
	return [_netRequests count];
}
/*
 
 add request
 
 */
- (void)addRequest:(MGSNetRequest *)netRequest
{
	[_netRequests addObject:netRequest];
	MLog(DEBUGLOG, @"addRequest: request handler count is now %i", [_netRequests count]);
}

/*
 
 send request on client
 
 */
- (void)sendRequestOnClient:(MGSNetRequest *)request
{
	[self addRequest:request];
	[request sendRequestOnClient];
}

/*
 
 send response on socket
 
 */
- (void)sendResponseOnSocket:(MGSNetRequest *)request wasValid:(BOOL)valid
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
