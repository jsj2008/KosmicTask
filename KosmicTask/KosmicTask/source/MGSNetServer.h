//
//  MGSNetServer.h
//  Mother
//
//  Created by Jonathan on 23/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSNetServerSocket.h"

@interface MGSNetServer : NSObject <MGSNetSocketDelegate> {
	MGSAsyncSocket *_acceptorSocket;
	NSNetService * _netService;
	NSMutableArray *_serverSockets;
    MGSAsyncSocket *_socketForInvalidAddress;
    NSSet *allowedAddresses;
    NSSet *_bannedAddresses;
}
@property (strong) NSNetService *netService;
@property (strong)NSSet *localNetworkAddresses;
@property (strong)NSSet *bannedAddresses;

- (BOOL)acceptOnPort:(UInt16)portNumber;

@end
