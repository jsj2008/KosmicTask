//
//  MGSRemoteInterfaceController.h
//  Mother
//
//  Created by Jonathan on 23/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MGSNetController;
@class MGSNetServer;

@interface MGSNetworkInterfaceController : NSObject {
	MGSNetController *_netController;
	MGSNetServer *_Server;
	NSMutableArray *_Clients;
}

@property (readonly) MGSNetController *bonjour;

- (BOOL)startServerOnPort:(UInt16)portNumber;
- (BOOL)searchForServices;

@end
