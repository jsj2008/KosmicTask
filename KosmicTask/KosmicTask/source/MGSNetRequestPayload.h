//
//  MGSNetRequestPayload.h
//  Mother
//
//  Created by Jonathan on 25/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MGSError;
@class MGSNetRequest;

@interface MGSNetRequestPayload : NSObject {
	NSDictionary * __strong _dictionary;
	unsigned long int _requestID;
	MGSError *__strong _requestError;
}

+ (id)payloadForRequest:(MGSNetRequest *)request;

@property (strong) NSDictionary *dictionary;
@property unsigned long int requestID;
@property (strong) MGSError *requestError;

@end
