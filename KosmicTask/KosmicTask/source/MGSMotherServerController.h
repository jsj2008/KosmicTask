//
//  MGSMotherServerController.h
//  Mother
//
//  Created by Jonathan on 11/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MGSMotherServerConnectionController;
@class MGSMotherServerSocketController;
@class MGSMotherServerLocalController;
@class MGSNetServerHandler;

@interface MGSMotherServerController : NSObject {
	MGSMotherServerConnectionController *_connection;
	MGSMotherServerSocketController *_socket;
	MGSMotherServerLocalController *_local;
	MGSNetServerHandler *_bonjour;

}

- (BOOL)searchForServices;

@property (readonly) MGSMotherServerConnectionController *connection;
@property (readonly) MGSMotherServerSocketController *socket;
@property (readonly) MGSMotherServerLocalController *local;
@property (readonly) MGSNetServerHandler *bonjour;


@end

