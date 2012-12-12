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
- (void)portMapperExternalIPAddressDidChange:(NSNotification *)aNotification;
- (void)portMapperWillSearchForRouter:(NSNotification *)aNotification;
- (void)portMapperDidFindRouter:(NSNotification *)aNotification;
- (void)portMappingDidChangeMappingStatus:(NSNotification *)aNotification;
- (TCMPortMapper *)portMapper;
- (void)addMappingWithExternalPort:(int)externalPort listeningPort:(int)listeningPort;

@property (readwrite) MGSPortMapperRouter routerStatus;
@end

@implementation MGSPortMapper

@synthesize delegate = _delegate;
@synthesize routerStatus = _routerStatus;

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
		TCMPortMapper *pm = [self portMapper];
		pm.appIdentifier = @"KosmicTask";
        
        _routerStatus = kPortMapperRouterUnknown;
        
		// add mapping
		[self addMappingWithExternalPort:externalPort listeningPort:listeningPort];
		
		// register for local notifications
        NSNotificationCenter *center=[NSNotificationCenter defaultCenter];
        
        // did start work
		[center addObserver:self selector:@selector(portMapperDidStartWork:) name:TCMPortMapperDidStartWorkNotification object:pm];
        
        // did end work
		[center addObserver:self selector:@selector(portMapperDidFinishWork:) name:TCMPortMapperDidFinishWorkNotification object:pm];
        
        // external IP address did change
        [center addObserver:self selector:@selector(portMapperExternalIPAddressDidChange:) name:TCMPortMapperExternalIPAddressDidChange object:pm];
        
        // router search will begin
        [center addObserver:self selector:@selector(portMapperWillSearchForRouter:) name:TCMPortMapperWillStartSearchForRouterNotification object:pm];
        
        // router found
        [center addObserver:self selector:@selector(portMapperDidFindRouter:) name:TCMPortMapperDidFinishSearchForRouterNotification object:pm];
        
        // mapping status changed
        [center addObserver:self selector:@selector(portMappingDidChangeMappingStatus:) name:TCMPortMappingDidChangeMappingStatusNotification object:nil];
	
		
	}
	
	return self;
}

/*
 
 set delegate
 
 */
- (void)setDelegate:(id <MGSPortMapperDelegate>)delegate
{
	_delegate = delegate;
}

#pragma mark -
#pragma mark Accessors

/*
 
 - portMapper
 
 */
- (TCMPortMapper *)portMapper
{
    return [TCMPortMapper sharedInstance];
}

/*
 
 external IP address
 
 */
- (NSString *)externalIPAddress
{
    TCMPortMapper *pm = [self portMapper];
    NSString *externalIPAddress = nil;
    
    if ([pm isRunning]) {
        externalIPAddress = [pm externalIPAddress];
        if (!externalIPAddress || [externalIPAddress isEqualToString:@"0.0.0.0"]) {
            externalIPAddress = NSLocalizedString(@"Not available", @"");
        }
     } else {
         externalIPAddress = NSLocalizedString(@"Not available", @"");
    }
    
    return externalIPAddress;
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
 
 - gatewayName
 
 */
- (NSString *)gatewayName
{
	NSString *gatewayName = [[self portMapper] routerName];
     
    return gatewayName;
}

/*
 
 - mappingProtocol
 
 */
- (MGSPortMapperProtocol)mappingProtocol
{
    MGSPortMapperProtocol protocol = kMGSPortMapperProtocolNone;
    
    NSString *protocolString = [[self portMapper] mappingProtocol];
    
    if ([protocolString isEqualToString:TCMNATPMPPortMapProtocol]) {
        protocol = kMGSPortMapperProtocolNAT_PMP;
    } else if ([protocolString isEqualToString:TCMUPNPPortMapProtocol]) {
        protocol = kMGSPortMapperProtocolUPNP; 
    }

    return protocol;
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
	[[self portMapper] stopBlocking];
	
	// remove observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark Mapping operations
/*
 
 - startMapping 
 
 */
- (void)startPortMapper
{
	[[self portMapper] start];
}

/*
 
 - stopMapping 
 
 */
- (void)stopMapping
{
	[[self portMapper] stop];
}

/*
 
 - refreshMapping
 
 */
- (void)refreshMapping
{
	[[self portMapper] refresh];
}


/*
 
 - remapWithExternalPort:listeningPort:

 */
- (void)remapWithExternalPort:(int)externalPort listeningPort:(int)listeningPort
{		
    [self addMappingWithExternalPort:externalPort listeningPort:listeningPort];
}

/*
 
 - addMappingWithExternalPort:listeningPort:
 
 */
- (void)addMappingWithExternalPort:(int)externalPort listeningPort:(int)listeningPort
{
    // we only need to manage one mapping so remove an existing mapping
    [self removeMapping];
    
	// create mapping
    // if the port is zero then do not add the mapping
    if (externalPort > 0) {
        
        /*
         note that simply removing and adding a mapping with different external
         port numbers will not work when executed in the same call. it does work if the
         removal and add are accomplished separately.
         
         the port mapper is threaded and the remove operation does not finish before
         the add thread causes the remove update to finish.
         
         the effect is that the mapper sees that we already have a mapping that
         matches the desired private port and updates the requested mapping
         public port with the existing public port.
         
         the overall effect is that the mapping stays exactly the same
         */
        _mapping = [TCMPortMapping portMappingWithLocalPort:listeningPort
                                        desiredExternalPort:externalPort
                                          transportProtocol:TCMPortMappingTransportProtocolTCP
                                                   userInfo:nil];
        [[self portMapper] addPortMapping: _mapping];
    }
}
/*
 
 - removeMapping
 
 */
- (void)removeMapping
{
    // remove existing mapping
	if (_mapping) {
		[[self portMapper] removePortMapping:_mapping];
	}
}

#pragma mark -
#pragma mark Port mapper notifications

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
	
	if ([_mapping mappingStatus] == TCMPortMappingStatusMapped) {
        
        MLogInfo(@"Port mapping established: %@", [_mapping description]);
		
	} else {
		
		MLogInfo(@"Port mapping was not established: %@", [_mapping description]);
        
	}
	
	[_delegate portMapperDidFinishWork];
}

/*
 
 - portMapperExternalIPAddressDidChange:
 
 */
- (void)portMapperExternalIPAddressDidChange:(NSNotification *)aNotification {
#pragma unused(aNotification)
    
    MLogDebug(@"PortMapper external IP address did change.");
    
    [_delegate portMapperExternalIPAddressDidChange];
}

/*
 
 - portMapperWillSearchForRouter:
 
 */
- (void)portMapperWillSearchForRouter:(NSNotification *)aNotification {
#pragma unused(aNotification)
    
    MLogDebug(@"PortMapper searching for router.");
}

/*
 
 - portMapperDidFindRouter:
 
 */
- (void)portMapperDidFindRouter:(NSNotification *)aNotification {
#pragma unused(aNotification)
    
     MLogDebug(@"PortMapper did find router.");
    
    TCMPortMapper *pm = [self portMapper];
    
    if ([pm externalIPAddress]) {
		// external address was found
        self.routerStatus = kPortMapperRouterHasExternalIP;
    } else {
        
        // we found the router but could not get the external address which suggests that
        // UPNP or NAT-PMP is not supported
		if ([pm routerIPAddress]) {
            self.routerStatus = kPortMapperRouterIncompatible;
		} else {
            self.routerStatus = kPortMapperRouterNotFound;
		}
    }
    
    [_delegate portMapperDidFindRouter];
}


/*
 
 - portMappingDidChangeMappingStatus:
 
 */
- (void)portMappingDidChangeMappingStatus:(NSNotification *)aNotification {
#pragma unused(aNotification)
    
    MLogDebug(@"PortMapper mapping status did change.");
    
    [_delegate portMappingDidChangeMappingStatus];
}

@end
