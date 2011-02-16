//
//  MGSNetServerSocket.h
//  Mother
//
//  Created by Jonathan on 04/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSNetSocket.h"

@class MGSNetServerSocket;

@interface MGSNetServerSocket : MGSNetSocket {
	BOOL _enableSSLSecurity;
}

- (id)initWithAcceptSocket:(MGSAsyncSocket *)socket;


@end
