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
	/*
	 
	 this function is called for all requests in a request chain so the negotiate
	 request may not occur in our collection.
	 
	 */
	if ([_netRequests containsObject:netRequest]) {
		[_netRequests removeObject:netRequest];
	}
	
	// we are done with this request
	[netRequest dispose];
	
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
	
	// do we want to track the negotiate request ?
	if (request.prevRequest && NO) {
		[self addRequest:request.prevRequest];
	}
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
