//
//  MGSMotherClient.h
//  Mother
//
//  Created by Jonathan on 11/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSMotherServerProtocol.h"

@class MGSMotherClient;

@interface MGSMotherServerConnectionController : NSObject {
	NSDistantObject <MGSMotherServerProtocol> *_motherServerProxy;
	BOOL _serverConnected;
	NSString *_hostName;
	//NSData *_addressData;
	MGSMotherClient *_clientController;
}

- (BOOL)connectToAddress:(NSData *)data;
- (BOOL)disconnect;

@property (readonly) BOOL connected;
@property (copy, readwrite) NSString *hostName;

@end

@interface MGSMotherServerConnectionController (NSConnectionNotification)
@end

