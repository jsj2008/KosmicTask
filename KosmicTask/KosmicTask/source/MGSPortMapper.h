//
//  MGSPortMapper.h
//  Mother
//
//  Created by Jonathan on 04/09/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TCMPortMapper/TCMPortMapper.h"

@protocol MGSPortMapperDelegate <NSObject>
@required
- (void)portMapperDidStartWork;
- (void)portMapperDidFinishWork;
- (void)portMapperDidFindRouter;
- (void)portMapperExternalIPAddressDidChange;
- (void)portMappingDidChangeMappingStatus;
@end

enum _MGSPortMapperRouter {
    kPortMapperRouterUnknown,
    kPortMapperRouterHasExternalIP,
    kPortMapperRouterIncompatible,
    kPortMapperRouterNotFound
};
typedef NSInteger MGSPortMapperRouter;

@interface MGSPortMapper : NSObject {
	TCMPortMapping *_mapping;
	id _delegate;
    MGSPortMapperRouter _routerStatus;
}

@property id <MGSPortMapperDelegate> delegate;
@property (readonly) MGSPortMapperRouter routerStatus;

- (id)initWithExternalPort:(int)externalPort listeningPort:(int)listeningPort;
- (void)remapWithExternalPort:(int)externalPort listeningPort:(int)listeningPort;
- (void)startPortMapper;
- (void)stopMapping;
- (void)dispose;
- (void)refreshMapping;
- (void)setDelegate:(id <MGSPortMapperDelegate>)delegate;
- (TCMPortMappingStatus)mappingStatus;
- (NSString *)externalIPAddress;
- (NSString *)gatewayName;
- (NSInteger)externalPort;
- (void)removeMapping;
@end
