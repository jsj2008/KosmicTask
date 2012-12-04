//
//  MGSInternetSharingServer.h
//  Mother
//
//  Created by Jonathan on 08/09/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSInternetSharing.h"
#import "MGSPortMapper.h"
#import "MGSPortChecker.h"
#import "Reachability.h"

@interface MGSInternetSharingServer : MGSInternetSharing <MGSPortMapperDelegate, MGSPortCheckerDelegate>{
	MGSPortMapper *_portMapper;
    MGSPortChecker *_portChecker;
    Reachability *_internetReach;
    BOOL _responsePending;
    BOOL _portMapperIsWorking;
    BOOL _portCheckerIsWorking;
}

- (id)initWithExternalPort:(NSInteger)externalPort listeningPort:(NSInteger)listeningPort;
- (void)startPortMapping;
- (void)stopPortMapping;
- (void)remapPortMapping;
- (NSDictionary *)statusDictionary;
- (void)request:(NSNotification *)note;
- (void)postStatusNotification;

@property (readonly) BOOL portMapperIsWorking;
@property (readonly) BOOL portCheckerIsWorking;
@end
