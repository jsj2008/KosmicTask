//
//  MGSInternetSharingServer.m
//  Mother
//
//  Created by Jonathan on 08/09/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSInternetSharingServer.h"
#import "MGSPreferences.h"
#import "MGSDistributedNotifications.h"
#import "NSDictionary_Mugginsoft.h"
#import "MGSPortChecker.h"
#import "NSBundle_Mugginsoft.h"

@interface MGSInternetSharingServer()
- (void)savePreferences;
- (void)startPortChecking;
- (void)stopPortChecking;
- (BOOL)portToolsAreWorking;
- (void)refreshPortMapping;
- (MGSPortMapper *)portMapper;

@property (readwrite) BOOL portMapperIsWorking;
@property (readwrite) BOOL portCheckerIsWorking;
@end

@implementation MGSInternetSharingServer

@synthesize portMapperIsWorking = _portMapperIsWorking;
@synthesize portCheckerIsWorking = _portCheckerIsWorking;
/*
 
 init
 
 */
- (id)init
{
	return nil;
}

/*
 
 init with external port and listening port
 
 designated initialiser
 
 */
- (id)initWithExternalPort:(NSInteger)externalPort listeningPort:(NSInteger)listeningPort
{
	if ((self = [super init])) {
		
        self.portCheckerIsWorking = NO;
        self.portMapperIsWorking = NO;
		self.listeningPort = listeningPort;
		
		// register to receive internet sharing request notification
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(request:) 
																name:MGSDistNoteInternetSharingRequest object:self.noteObjectString];
	
		// set external port
		MGSPreferences *preferences = [MGSPreferences standardUserDefaults];		
		if (![preferences objectForKey:MGSExternalPortNumber]) {
            self.externalPort = externalPort; 
		}
		
        // start port mapping.
        // we do not need to start and stop the port mapper.
        // rather we start it and add and remove mappings as required.
        if (self.automaticallyMapPort) {
            [self startPortMapping];
        }
        
        // let the port mapper handle reachability
        BOOL usePortMapperReachability = YES;
        
        // enable reachability callbacks
        if (!usePortMapperReachability) {
            // Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the
            // method "reachabilityChanged" will be called.
            [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];

            _internetReach = [Reachability reachabilityForInternetConnection];
            [_internetReach startNotifier];
        }
        
        if (!_responsePending) {
            [self postStatusNotification];
        }
        
	}
	
	return self;
}

#pragma mark -
#pragma mark Notification handling

/*
 
 request notification
 
 the sender of this notification will expect for a response and may
 be showing a wait state.
 
 */
- (void)request:(NSNotification *)note
{
    // we only deal with one request at a time
    if (_responsePending) {
        return;
    }
    
	NSDictionary *userInfo = [note userInfo];
    
    
    // response required
    BOOL resposeRequired = [[userInfo objectForKey:MGSInternetSharingKeyResponseRequired] boolValue];
    
	// get the request id
	MGSInternetSharingRequestID requestID = [[userInfo objectForKey:MGSInternetSharingKeyRequest] integerValue];
	
	switch (requestID) {
		
            // mapping refresh
        case kMGSInternetSharingRequestRefreshMapping:
        {
            [self refreshPortMapping];
        }
        break;
            
            // status request
		case kMGSInternetSharingRequestStatus:
        {
            // we do a port check and return the overal status when the check is done
            [self startPortChecking];
        }
        break;
            
            // internet access request
		case kMGSInternetSharingRequestInternetAccess:
			self.allowInternetAccess = [[userInfo objectForKey:MGSAllowInternetAccess] boolValue];
            if (self.allowInternetAccess) {
                self.automaticallyMapPort = NO;
                [self startPortChecking];
             } else {
                self.automaticallyMapPort = NO;
                [self stopPortMapping];
           }
 			break;
            
            // local access request
		case kMGSInternetSharingRequestLocalAccess:
			self.allowLocalAccess = [[userInfo objectForKey:MGSAllowLocalAccess] boolValue];
 			break;
            
            // allow local authentication
		case kMGSInternetSharingRequestAllowLocalAuthentication:
			self.allowLocalUsersToAuthenticate = [[userInfo objectForKey:MGSAllowLocalUsersToAuthenticate] boolValue];
 			break;
            
            // allow remote authentication
		case kMGSInternetSharingRequestAllowRemoteAuthentication:
			self.allowRemoteUsersToAuthenticate = [[userInfo objectForKey:MGSAllowRemoteUsersToAuthenticate] boolValue];
 			break;
                        
            // automatically map port
		case kMGSInternetSharingRequestMapPort:
        {
			NSInteger port = [[userInfo objectForKey:MGSExternalPortNumber] integerValue];
            if (port == 0) {
                MLog(RELEASELOG, @"Cannot complete map port request. Requested port is 0.");
                break;
            }
            
			self.automaticallyMapPort = [[userInfo objectForKey:MGSEnableInternetAccessAtLogin] boolValue];
            if (self.automaticallyMapPort) {
                
                if ([self mappingStatus] == kMGSInternetSharingPortMapped) {
                    MLog(RELEASELOG, @"Cannot complete map port request. Mapping is already active.");
                    break;
                }
            }
            
            self.externalPort = port;
            
            if (self.automaticallyMapPort) {
                 [self startPortMapping];
             } else {
                [self stopPortMapping];
            }
        }
			break;
            
             // unrecognised
		default:
			MLog(RELEASELOG, @"unrecognised internet sharing request id: %i", requestID);
			break;
	}
    
    // save preferences in case server crashes
    [self savePreferences];
	
    if (resposeRequired && !_responsePending ) {
        [self postStatusNotification];
    }
}

/*
 
 post status notification
 
 */
- (void)postStatusNotification
{
	// send out a status distributed notification
	[self postDistributedResponseNotificationWithDict:[self statusDictionary]];
    
    _responsePending = NO;
}

/*
 
 status dictionary
 
 */
- (NSDictionary *)statusDictionary
{
	NSMutableDictionary *dict =  [NSMutableDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithInteger:kMGSInternetSharingRequestStatus], MGSInternetSharingKeyRequest,
                           [NSNumber numberWithInteger:[self mappingStatus]], MGSInternetSharingKeyMappingStatus,
                            [NSNumber numberWithInteger:[self routerStatus]], MGSInternetSharingKeyRouterStatus,
                           [NSNumber numberWithInteger:[self portReachabilityStatus]], MGSInternetSharingKeyReachabilityStatus,
                           [self IPAddressString], MGSInternetSharingKeyIPAddress,
                           [self gatewayName], MGSInternetSharingKeyGatewayName,
                           [NSNumber numberWithInteger:self.externalPort], MGSExternalPortNumber,
                           [NSNumber numberWithBool:self.automaticallyMapPort], MGSEnableInternetAccessAtLogin,
                           nil];
	
    // sending back the access data is optional
    if (NO) {
        NSDictionary *accessDict =  [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithBool:self.allowInternetAccess], MGSAllowInternetAccess,
                                  [NSNumber numberWithBool:self.allowLocalAccess], MGSAllowLocalAccess,
                                  [NSNumber numberWithBool:self.allowLocalUsersToAuthenticate], MGSAllowLocalUsersToAuthenticate,
                                  [NSNumber numberWithBool:self.allowRemoteUsersToAuthenticate], MGSAllowRemoteUsersToAuthenticate,
                                  nil];
        [dict addEntriesFromDictionary:accessDict];
    }
    
	MLog(DEBUGLOG, @"Internet sharing response dict sent by server: %@", [dict propertyListStringValue]);
	
	return dict;
}

#pragma mark -
#pragma mark Accessors

/*
 
 - setExternalPort:
 
 */
- (void)setExternalPort:(NSInteger)port
{
    BOOL remap = NO;
    
    if (self.externalPort != port) {
        remap = YES;
    }
    super.externalPort = port;
    
    if (remap && _portMapper) {
        [self remapPortMapping];
    }
}

/*
 
 - portToolsAreWorking
 
 */
- (BOOL)portToolsAreWorking
{
    return (self.portCheckerIsWorking || self.portMapperIsWorking);
}
#pragma mark -
#pragma mark Reachability

/*
 
 - reachabilityChanged:
 
 */
- (void)reachabilityChanged:(NSNotification* )note
{
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass: [Reachability class]]);

    NetworkStatus netStatus = [curReach currentReachabilityStatus];
    //BOOL connectionRequired= [curReach connectionRequired];
    
    // internet reachability has changed.
    // code is iOS based hence the WWAN reachability.
    if (curReach == _internetReach) {
        
        switch (netStatus)
        {
            case NotReachable:
                break;
                
            case ReachableViaWWAN:
                break;
                
            case ReachableViaWiFi:
                break;
        }
        
    }
    
    if (!_responsePending) {
        [self startPortChecking];
    }
}


#pragma mark -
#pragma mark Port checking

/*
 
 - startPortChecking
 
 */
- (void)startPortChecking
{
    self.portReachabilityStatus = kMGSPortReachabilityNA;
    if (!_portChecker) {
        
        NSString *portCheckerURL = @"http://portcheck.mugginsoft.com";
        NSString *portCheckerPath = @"sys";
        
        NSURL *url = [NSURL URLWithString:portCheckerURL];
        _portChecker = [[MGSPortChecker alloc] initForURL:url];
        if (!_portChecker) {
             return;
        }
        _portChecker.portQueryTimeout = 10.0;
        _portChecker.delegate = self;
        // set correct checker path
        NSString *path = _portChecker.path;
        _portChecker.path = [portCheckerPath stringByAppendingPathComponent:path];
    }

    // we may have changed port
    _portChecker.portNumber = self.externalPort;

    _responsePending = YES;
    self.portCheckerIsWorking = YES;
    [_portChecker start];
}

/*
 
 - stopPortChecking
 
 */
- (void)stopPortChecking
{
    self.portCheckerIsWorking = NO;
    [_portChecker stop];
    [self postStatusNotification];
}

#pragma mark -
#pragma mark Port mapping
/*
 
 - startPortMapping
 
 */
- (void)startPortMapping
{
       
	// start mapping if port mot mapped
	if ([self mappingStatus] == kMGSInternetSharingPortNotMapped) {
        _responsePending = YES;
		[[self portMapper] startMapping];
	}
}

/*
 
 remap port mapping
 
 */
- (void)remapPortMapping
{
	if (_portMapper) {
		if (self.externalPort > 0) {
             _responsePending = YES;
			[_portMapper remapWithExternalPort:(int)self.externalPort listeningPort:(int)self.listeningPort];
		}
	} else {
		MLogInfo(@"Cannot remap. Port mapper is not allocated.");
	}
}

/*
 
 stop port mapping
 
 */
- (void)stopPortMapping
{
	// stop mapping if port mapped
    if (_portMapper) {
        if ([self mappingStatus] == kMGSInternetSharingPortMapped) {
             _responsePending = YES;
            [_portMapper stopMapping];
        }
    } else {
		MLogInfo(@"Cannot stop. Port mapper is not allocated.");        
    }
}

/*
 
 - portMapper
 
 */
- (MGSPortMapper *)portMapper
{
	//NSAssert(self.listeningPort != 0, @"Cannot start port mapper as listening port not defined");
	
	// lazy allocation
	if (!_portMapper) {
		
		// validate external port
		//if (self.externalPort == 0) {
		//	return nil;
		//}
		
		// initialise the mapper
		_portMapper = [[MGSPortMapper alloc] initWithExternalPort:(int)self.externalPort listeningPort:(int)self.listeningPort];
		_portMapper.delegate = self;
		
	}
	
    return _portMapper;
}

/*
 
 - refreshPortMapping
 
 */
- (void)refreshPortMapping
{
    _responsePending = YES;
    
    [[self portMapper] refreshMapping];
}

#pragma mark -
#pragma mark Disposal
/*
 
 dispose
 
 call on termination
 
 */
- (void)dispose
{
	// stop the port mapper permanently
	[_portMapper dispose];
	
	// remove observers
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	
    [self savePreferences];
    
}

#pragma mark -
#pragma mark Preference handling
/*
 
 - savePreferences
 
 */
- (void)savePreferences
{
	// write out preferences
	[[MGSPreferences standardUserDefaults] setObject:[NSNumber numberWithBool:self.automaticallyMapPort] forKey:MGSEnableInternetAccessAtLogin];
	[[MGSPreferences standardUserDefaults] setObject:[NSNumber numberWithBool:self.allowInternetAccess] forKey:MGSAllowInternetAccess];
	[[MGSPreferences standardUserDefaults] setObject:[NSNumber numberWithBool:self.allowLocalUsersToAuthenticate] forKey:MGSAllowLocalUsersToAuthenticate];
	[[MGSPreferences standardUserDefaults] setObject:[NSNumber numberWithBool:self.allowRemoteUsersToAuthenticate] forKey:MGSAllowRemoteUsersToAuthenticate];
	[[MGSPreferences standardUserDefaults] setObject:[NSNumber numberWithBool:self.allowLocalAccess] forKey:MGSAllowLocalAccess];
	[[MGSPreferences standardUserDefaults] setObject:[NSNumber numberWithInteger:self.externalPort] forKey:MGSExternalPortNumber];
	[[MGSPreferences standardUserDefaults] synchronize];
	
}



#pragma mark -
#pragma mark MGSPortMapperDelegate

/*
 
 port mapper did start work
 
 */
- (void)portMapperDidStartWork
{
	self.portMapperIsWorking = YES;
}

/*
 
 port mapper did finish work
 
 */
- (void)portMapperDidFinishWork
{
    self.IPAddressString = [self notAvailableString];
    self.gatewayName = [self notAvailableString];
    
    switch ([_portMapper mappingStatus])
    {
        case TCMPortMappingStatusTrying:
            self.mappingStatus = kMGSInternetSharingPortTryingToMap;
            break;
            
        case TCMPortMappingStatusMapped:
            self.mappingStatus = kMGSInternetSharingPortMapped;
            self.IPAddressString = [_portMapper externalIPAddress];
            self.gatewayName = [_portMapper gatewayName];
            break;
            
        case TCMPortMappingStatusUnmapped:
        default:
            self.mappingStatus = kMGSInternetSharingPortNotMapped;
            break;
    }
 
	NSInteger externalPort = [_portMapper externalPort];
	
	// our allocated port may differ from our requested port if the requested port was already mapped
	if (self.externalPort != externalPort && externalPort != 0) {
		self.externalPort = externalPort;
	}
	
    self.portMapperIsWorking = NO;
    
	[self startPortChecking];
}

/*
 
 - portMapperDidFindRouter
 
 */
- (void)portMapperDidFindRouter
{
    switch ([_portMapper routerStatus]) {
        case kPortMapperRouterUnknown:
            self.routerStatus = kMGSInternetSharingRouterUnknown;
            break;
            
        case kPortMapperRouterHasExternalIP:
            self.routerStatus = kMGSInternetSharingRouterHasExternalIP;
            break;
            
        case kPortMapperRouterIncompatible:
            self.routerStatus = kMGSInternetSharingRouterIncompatible;
            break;
            
        case kPortMapperRouterNotFound:
            self.routerStatus = kMGSInternetSharingRouterNotFound;
            break;
    }
    
    // may arrive during a tool probe or not
    if (![self portToolsAreWorking]) {
        [self postStatusNotification];
    }
}

/*
 
 - portMapperExternalIPAddressDidChange
 
 */
- (void)portMapperExternalIPAddressDidChange
{
    // may arrive during a tool probe or not
    if (![self portToolsAreWorking]) {
        [self postStatusNotification];
    }
}


/*
 
 - portMappingDidChangeMappingStatus
 
 */
- (void)portMappingDidChangeMappingStatus
{
    // may arrive during a tool probe or not
    if (![self portToolsAreWorking]) {
        [self postStatusNotification];
    }
}

#pragma mark -
#pragma mark MGSPortCheckerDelegate

/*
 
 - portCheckerDidFinishProbing:
 
 */

- (void)portCheckerDidFinishProbing:(MGSPortChecker *)portChecker
{

    self.IPAddressString = [self notAvailableString];
    
    switch ([portChecker status]) {
        case kMGS_PORT_STATUS_NA:
            self.portReachabilityStatus = kMGSPortReachabilityNA;
        break;

        case kMGS_PORT_STATUS_OPEN:
            self.portReachabilityStatus = kMGSPortReachable;
            self.externalPort = portChecker.portNumber;
            self.IPAddressString = portChecker.gatewayAddress;
        break;

        case kMGS_PORT_STATUS_CLOSED:
            self.portReachabilityStatus = kMGSPortNotReachable;
        break;

        case kMGS_PORT_STATUS_ERROR:
        default:
            self.portReachabilityStatus = kMGSPortReachabilityNA;
        break;
    }

    self.portCheckerIsWorking = NO;
    [self postStatusNotification];
    
}

@end
