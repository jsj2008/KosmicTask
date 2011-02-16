/*
 *  MGSMotherServerProtocol.h
 *  Mother
 *
 *  Created by Jonathan on 11/11/2007.
 *  Copyright 2007 Mugginsoft. All rights reserved.
 *
 */
#define MGSMotherServerName @"MGSMotherServer"

// define messages that client will receive from server
@protocol MGSMotherClientProtocol
@end

// define messages that server will receive from client
@protocol MGSMotherServerProtocol
- (BOOL)registerClient:(in byref id <MGSMotherClientProtocol>)client;
- (BOOL)unregisterClient:(in byref id <MGSMotherClientProtocol>)client;
@end
