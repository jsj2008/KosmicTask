//
//  MGSPortMapper.m
//  Mother
//
//  Created by Jonathan on 04/09/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSMother.h"
#import "MGSPortMapper.h"
#import "MGSDistributedNotifications.h"

// class extension
@interface MGSPortMapper()
- (void)portMapperDidStartWork:(NSNotification *)aNotification;
- (void)portMapperDidFinishWork:(NSNotification *)aNotification;
@end

@implementation MGSPortMapper

@synthesize delegate = _delegate;

/*
 
 init
 
 */
- (id)init
{
	return nil;
}

/*
 
 map external port to local port
 
 designated initialiser
 
 */
- (id)initWithExternalPort:(int)externalPort listeningPort:(int)listeningPort
{
	if ((self = [super init])) {
		
		// access shared mapper
		TCMPortMapper *pm = [TCMPortMapper sharedInstance];
		
		// remap
		[self remapWithExternalPort:externalPort listeningPort:listeningPort];
		
		// register for local notifications
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(portMapperDidStartWork:) 
													 name:TCMPortMapperDidStartWorkNotification object:pm];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(portMapperDidFinishWork:)
													 name:TCMPortMapperDidFinishWorkNotification object:pm];
	
		
	}
	
	return self;
}

/*
 
 external IP address
 
 */
- (NSString *)externalIPAddress
{
	return [[TCMPortMapper sharedInstance] externalIPAddress];
}

/*
 
 external port
 
 the actual external port may differ from what was requested if the requested port is in use
 */
- (NSInteger)externalPort
{
	return [_mapping externalPort];
}

/*
 
 gateway name
 
 */
- (NSString *)gatewayName
{
	return [[TCMPortMapper sharedInstance] routerName];
}

/*
 
 port mapper did start work
 
 */
- (void)portMapperDidStartWork:(NSNotification *)aNotification {
	#pragma unused(aNotification)
	
	MLog(DEBUGLOG, @"port mapper did start work");

	[_delegate portMapperDidStartWork];
}

/*
 
 port mapper did finish work
 
 */
- (void)portMapperDidFinishWork:(NSNotification *)aNotification 
{
	
	#pragma unused(aNotification)
	
	if ([_mapping mappingStatus]==TCMPortMappingStatusMapped) {
	
		 MLog(RELEASELOG, @"port mapping established: %@", [_mapping description]);
		
	} else {
		
		MLog(RELEASELOG, @"port mapping could not be established: %@", [_mapping description]);

	}
	
	[_delegate portMapperDidFinishWork];
}

/*
 
 mapping status
 
 */
- (TCMPortMappingStatus)mappingStatus
{
	if (_mapping) {
		return [_mapping mappingStatus];
	} else {
		return TCMPortMappingStatusUnmapped;
	}
}

/*
 
 dispose 
 
 call on termination
 
 
 */
- (void)dispose
{
	// stop the port mapper permanently
	[[TCMPortMapper sharedInstance] stopBlocking];
	
	// remove observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*
 
 start 
 
 */
- (void)startMapping
{
	[[TCMPortMapper sharedInstance] start];
}

/*
 
 stop 
 
 */
- (void)stopMapping
{
	[[TCMPortMapper sharedInstance]  stop];
}

/*
 
 remap external port to local port
 
 designated initialiser
 
 */
- (void)remapWithExternalPort:(int)externalPort listeningPort:(int)listeningPort
{		
	// access shared mapper
	TCMPortMapper *pm = [TCMPortMapper sharedInstance];
	
	// remove existing mapping
	if (_mapping) {
		[pm removePortMapping:_mapping];
	}
	
	// create mapping
	_mapping = [TCMPortMapping portMappingWithLocalPort:listeningPort 
									desiredExternalPort:externalPort 
									  transportProtocol:TCMPortMappingTransportProtocolTCP
											   userInfo:nil];
	[pm addPortMapping: _mapping];
}

/*
 
 set delegate
 
 */
- (void)setDelegate:(id <MGSPortMapperDelegate>)delegate
{
	_delegate = delegate;
}


@end
