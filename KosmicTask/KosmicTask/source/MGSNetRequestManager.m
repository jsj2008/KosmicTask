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

// class extension
@interface MGSNetRequestManager()
- (void)removeRequest:(MGSNetRequest *)netRequest;
@end

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

		MLog(DEBUGLOG, @"removeRequest: request handler count is now %i", [_netRequests count]);
        
#ifdef MGS_LOG_REQUEST_QUEUE
        NSLog(@"removeRequest: request handler count is now %i", [_netRequests count]);
#endif
    }
    
    
#ifdef MGS_LOG_DISPOSE
    NSLog(@"%@:%@ calling %@ -releaseDisposable", self, netRequest, NSStringFromSelector(_cmd));
#endif
    
	// release disposable resources.
    [netRequest releaseDisposable];
	
#ifdef MGS_LOG_DISPOSE
    if (netRequest.requestType == kMGSRequestTypeLogging) {
        NSLog(@"Logging request disposal count = %i", netRequest.disposalCount);
    }
#endif
    
}


/*
 
 - requestCount
 
 */
-(NSUInteger)requestCount
{
	return [_netRequests count];
}
/*
 
 - addRequest:
 
 */
- (BOOL)addRequest:(MGSNetRequest *)netRequest
{
    if ([_netRequests containsObject:netRequest]) {
        MLogDebug(@"Request is already in queue");
        return NO;
    }
    
	[_netRequests addObject:netRequest];
	MLog(DEBUGLOG, @"addRequest: request handler count is now %i", [_netRequests count]);
    
    // retain disposable resources
	[netRequest retainDisposable];
    
    return YES;
}

/*
 
 - terminateRequest:
 
 */
- (BOOL)terminateRequest:(MGSNetRequest *)netRequest
{
    // disconnect the request
    if (netRequest.isSocketConnected) {
        [netRequest disconnect];
    }
    
    // remove request from queue
    [self removeRequest:netRequest];
    
    // terminate child requests
    for (MGSNetRequest *childRequest in netRequest.childRequests) {
        [self terminateRequest:childRequest];
    }
    
    netRequest.status = kMGSStatusTerminated;
    
    return YES;
}

@end
