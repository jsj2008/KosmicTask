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


enum _MGSRequestResponsePending {
    kMGSMGSRequestResponsePendingNone = 0,
    kMGSMGSRequestResponsePendingPortAccess = 0x01,
    kMGSMGSRequestResponsePendingPortMapping = 0x02,
    
};

typedef NSInteger MGSRequestResponsePending;

@interface MGSInternetSharingServer : MGSInternetSharing <MGSPortMapperDelegate, MGSPortCheckerDelegate>{
	MGSPortMapper *_portMapper;
    MGSPortChecker *_portChecker;
    Reachability *_internetReach;
    MGSRequestResponsePending _responsePending;
    BOOL _portMapperIsWorking;
    BOOL _portCheckerIsWorking;
    BOOL _doPortCheckWhenPortMapperFinishes;
}


- (id)initWithExternalPort:(NSInteger)externalPort listeningPort:(NSInteger)listeningPort;
- (void)startPortMapper;
- (void)disablePortMapping;
- (void)enablePortMapping;
- (void)request:(NSNotification *)note;

@property (readonly) BOOL portMapperIsWorking;
@property (readonly) BOOL portCheckerIsWorking;
@property BOOL doPortCheckWhenPortMapperFinishes;
@end
