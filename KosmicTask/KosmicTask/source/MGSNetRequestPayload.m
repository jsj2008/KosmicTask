//
//  MGSNetRequestPayload.m
//  Mother
//
//  Created by Jonathan on 25/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSNetRequestPayload.h"
#import "MGSNetRequest.h"

@implementation MGSNetRequestPayload


@synthesize dictionary = _dictionary;
@synthesize requestID = _requestID;
@synthesize requestError = _requestError;

- (id)init
{
	if ([super init]) {
		self.dictionary = nil;
		self.requestID = -1;
		self.requestError = nil;
	}
	return self;
}
+ (id)payloadForRequest:(MGSNetRequest *)request
{
	id payload = [[self alloc] init];
	[payload setRequestID:request.requestID];
	return payload;
}
	
@end
