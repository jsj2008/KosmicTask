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
@end

@interface MGSPortMapper : NSObject {
	TCMPortMapping *_mapping;
	id _delegate;
}

@property id <MGSPortMapperDelegate> delegate;

- (id)initWithExternalPort:(int)externalPort listeningPort:(int)listeningPort;
- (void)remapWithExternalPort:(int)externalPort listeningPort:(int)listeningPort;
- (void)startMapping;
- (void)stopMapping;
- (void)dispose;
- (void)setDelegate:(id <MGSPortMapperDelegate>)delegate;
- (TCMPortMappingStatus)mappingStatus;
- (NSString *)externalIPAddress;
- (NSString *)gatewayName;
- (NSInteger)externalPort;
@end
