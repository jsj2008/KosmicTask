//
//  MGSNetController.h
//  Mother
//
//  Created by Jonathan on 17/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MGSNetServer;

//extern NSString *MGSBonjourResolveAddress;

@interface MGSNetServerHandler : NSObject <NSNetServiceDelegate, NSNetServiceBrowserDelegate> {
	MGSNetServer *_netServer;
	NSString *_serviceType;
	NSString *_serviceName;
	NSString *_domain;
	id _delegate;
	NSTimer * _LMTimer;
    NSNetServiceBrowser *_serviceBrowser;
    NSMutableArray *_netServices;
    NSMutableSet *_IPv4BonjourAddresses;
    NSMutableSet *_IPv6BonjourAddresses;
    NSMutableSet *_BonjourAddresses;
    //NSMutableDictionary *_addressesForHostName;
}
+ (id)sharedController;

// server methods
- (BOOL)startServerOnPort:(UInt16)portNumber;
- (void)updateTXTRecord;

@property (copy) NSString *serviceType;
@property (copy) NSString *serviceName;
@property (copy) NSString *domain;
@property id delegate;
@end
