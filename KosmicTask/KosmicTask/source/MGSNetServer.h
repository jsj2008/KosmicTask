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
    MGSAsyncSocket *_socketForInvalidAddress;
    NSSet *_allowedAddresses;
    NSSet *_bannedAddresses;
}
@property NSNetService *netService;
@property (assign)NSSet *allowedAddresses;
@property (assign)NSSet *bannedAddresses;

- (BOOL)acceptOnPort:(UInt16)portNumber;

@end
