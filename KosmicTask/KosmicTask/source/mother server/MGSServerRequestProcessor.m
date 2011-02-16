//
//  MGSServerRequestProcessor.m
//  Mother
//
//  Created by Jonathan on 29/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSServerRequestProcessor.h"
#import "MGSNetRequest.h"
#import "MGSNetRequestManager.h"

@implementation MGSServerRequestProcessor


/*
 
 parse net request
 
 override required
 
 */
- (BOOL)parseNetRequest:(MGSNetRequest *)netRequest
{
	#pragma unused(netRequest)
	
	return NO;
}

/*
 
 send a request reply for valid request
 
 */
- (void)sendValidRequestReply:(MGSNetRequest *)netRequest
{	
	id delegate = [netRequest delegate];
	
	NSAssert(delegate, @"delegate is nil"); 
	
	// tell net request delegate to send reply
	if (delegate && [delegate respondsToSelector:@selector(sendResponseOnSocket:wasValid:)]) {
		[delegate sendResponseOnSocket:netRequest wasValid:YES];
	}
}


@end
