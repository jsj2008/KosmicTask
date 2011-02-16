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


@interface MGSInternetSharingServer : MGSInternetSharing <MGSPortMapperDelegate>{
	MGSPortMapper *_portMapper;
}

- (id)initWithExternalPort:(NSInteger)externalPort listeningPort:(NSInteger)listeningPort;
- (void)startPortMapping;
- (void)stopPortMapping;
- (void)remapPortMapping;
- (void)initialisePortMapping;
- (NSDictionary *)statusDictionary;
- (void)request:(NSNotification *)note;
- (void)postStatusNotification;
- (MGSInternetSharingMappingStatus)mappingStatus;
- (NSString *)gatewayName;
@end
