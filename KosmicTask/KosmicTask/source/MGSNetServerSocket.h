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
    BOOL _connectionApproved;
}

- (id)initWithAcceptSocket:(MGSAsyncSocket *)socket;

@property (readonly) BOOL connectionApproved;

@end
