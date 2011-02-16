//
//  MGSNetServer.h
//  Mother
//
//  Created by Jonathan on 23/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSNetServerSocket.h"

@class MGSAsyncSocket;

@interface MGSNetServer : NSObject <MGSNetSocketDelegate> {
	MGSAsyncSocket *_acceptorSocket;
	NSNetService *_netService;
	NSMutableArray *_serverSockets;	
}
@property NSNetService *netService;

- (BOOL)acceptOnPort:(UInt16)portNumber;
@end
