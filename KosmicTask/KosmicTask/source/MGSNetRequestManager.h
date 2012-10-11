//
//  MGSNetRequestManager.h
//  Mother
//
//  Created by Jonathan on 04/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSNetRequest.h"

@class MGSNetRequest;

@interface MGSNetRequestManager : NSObject <MGSNetRequestDelegate> {
	NSMutableArray *_netRequests;
}
- (NSUInteger)requestCount;
- (BOOL)addRequest:(MGSNetRequest *)netRequest;
- (void)terminateRequest:(MGSNetRequest *)netRequest;

@property (readonly) NSMutableArray *netRequests;
@end
