//
//  MGSNetClientSocket.h
//  Mother
//
//  Created by Jonathan on 01/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSNetSocket.h"

@interface MGSNetClientSocket : MGSNetSocket {
	NSString *clientServiceName;
	BOOL useSSL;
}
- (BOOL)connectToHost:(NSString*)host onPort:(UInt16)port forRequest:(MGSNetRequest *)netRequest;

@end
