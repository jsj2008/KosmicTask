//
//  MGSServerRequestProcessor.h
//  Mother
//
//  Created by Jonathan on 29/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MGSNetRequest;

@interface MGSServerRequestProcessor : NSObject {

}

- (BOOL)parseNetRequest:(MGSNetRequest *)netRequest;
- (void)sendValidRequestReply:(MGSNetRequest *)netRequest;

@end
