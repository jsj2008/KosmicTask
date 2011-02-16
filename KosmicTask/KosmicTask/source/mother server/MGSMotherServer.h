//
//  MGSMotherServer.h
//  Mother
//
//  Created by Jonathan on 04/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "MGSMotherServerProtocol.h"

#define MOTHER_IANA_REGISTERED_PORT 7742

@class MGSNetServerHandler;
@class MGSInternetSharingServer;

@interface MGSMotherServer : NSObject <MGSMotherServerProtocol>
{
	MGSNetServerHandler *_netServerHandler;
	MGSInternetSharingServer *_internetSharingServer;
	BOOL _initialised;
	int _serverPort;
	int _externalPort;
}

- (void)startServerOnPortString:(NSString *)str;
- (BOOL)initialise;
- (void)dispose;
	
@property (readonly) int externalPort;
@property (readonly) int listeningPort;
@property (readonly) BOOL initialised;

@end
