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
#import "NSString_Mugginsoft.h"

@interface MGSInternetSharingServer()
- (void)savePreferences;
- (void)startPortChecking;
- (void)stopPortChecking;
- (void)refreshPortMapping;
- (MGSPortMapper *)portMapper;
- (void)postPortMapperStatus;
- (void)postPortCheckerStatus;
- (NSMutableDictionary *)portCheckerStatusDictionary;
- (NSMutableDictionary *)portMapperStatusDictionary;

@property (readwrite) BOOL portMapperIsWorking;
@property (readwrite) BOOL portCheckerIsWorking;
@end

@implementation MGSInternetSharingServer

@synthesize portMapperIsWorking = _portMapperIsWorking;
@synthesize portCheckerIsWorking = _portCheckerIsWorking;
@synthesize doPortCheckWhenPortMapperFinishes = _doPortCheckWhenPortMapperFinishes;

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
		
        self.doPortCheckWhenPortMapperFinishes = NO;
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
        [self startPortMapper];
        
        // let the port mapper handle reachability
        BOOL usePortMapperReachability = YES;
        
        // enable reachability callbacks
        if (!usePortMapperReachability) {
            
            // Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the
            // method "reachabilityChanged" will be called.
            [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object:nil];

            _internetReach = [Reachability reachabilityForInternetConnection];
            [_internetReach startNotifier];
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
  
	NSDictionary *userInfo = [note userInfo];
           
	// get the request id
	MGSInternetSharingRequestID requestID = [[userInfo objectForKey:MGSInternetSharingKeyRequest] integerValue];
	
	switch (requestID) {
		
            // status request
        case kMGSInternetSharingRequestStatus:
        {
            [self postPortMapperStatus];
            [self postPortCheckerStatus];
        }
        break;
            
            // mapping refresh request
        case kMGSInternetSharingRequestRefreshMapping:
        {
            if (_portMapperIsWorking) return;

            [self refreshPortMapping];
        }
        break;
            
            // port check request
		case kMGSInternetSharingRequestPortCheck:
        {
            if (_portCheckerIsWorking) return;

            NSInteger port = [[userInfo objectForKey:MGSExternalPortNumber] integerValue];
            if (port == 0) {
                MLog(RELEASELOG, @"Cannot complete port check request. Requested port is 0.");
                break;
            }

            self.externalPort = port;
            
            // we do a port check and return the port status status when the check is done
            [self startPortChecking];
        }
        break;
            
            // internet access request
		case kMGSInternetSharingRequestInternetAccess:
			self.allowInternetAccess = [[userInfo objectForKey:MGSAllowInternetAccess] boolValue];
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
            if (_portMapperIsWorking) return;

			NSInteger port = [[userInfo objectForKey:MGSExternalPortNumber] integerValue];
            if (port == 0) {
                MLog(RELEASELOG, @"Cannot complete map port request. Requested port is 0.");
                break;
            }
            
            self.externalPort = port;
			self.automaticallyMapPort = [[userInfo objectForKey:MGSEnableInternetAccessAtLogin] boolValue];
            
            // note that if the mapper protocol is none then we just update the mapping table
            // but no mapping actually occurs.
            if (self.automaticallyMapPort) {
                 [self enablePortMapping];
             } else {
                [self disablePortMapping];
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
        remap = NO;
    }
    super.externalPort = port;
    
    if (remap && _portMapper) {
        [self enablePortMapping];
    }
}

#pragma mark -
#pragma mark Reachability

/*
 
 - reachabilityChanged:
 
 */
- (void)reachabilityChanged:(NSNotification* )note
{
    /*
    
     we don't expect to enable our own reachability test as
     the reachability in TCMPortMapper perfomrs well
     
     */
    
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
    
    [self refreshPortMapping];
}


#pragma mark -
#pragma mark Port checking

/*
 
 - startPortChecking
 
 */
- (void)startPortChecking
{
    self.portReachabilityStatus = kMGSPortTryingToReach;
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
    self.portMapperIsWorking = NO;
}

#pragma mark -
#pragma mark Port mapping
/*
 
 - startPortMapper
 
 */
- (void)startPortMapper
{
    // start it once only
    if (_portMapper) {
        MLogInfo(@"Invalid start. The port mapper is already active.");
        return;
    }
    
	// start mapping if port mot mapped
    [[self portMapper] startPortMapper];
}

/*
 
 - enablePortMapping
 
 */
- (void)enablePortMapping
{
    [_portMapper remapWithExternalPort:(int)self.externalPort listeningPort:(int)self.listeningPort];
}

/*
 
 - disablePortMapping
 
 */
- (void)disablePortMapping
{
    [[self portMapper] removeMapping];
}

/*
 
 - portMapper
 
 */
- (MGSPortMapper *)portMapper
{
	// lazy allocation
	if (!_portMapper) {
		
        // port 0 is ignored for mapping purposes.
        // to start the mapper with no initial map pass in 0
        int initialPortMapping = 0;
        
        // start with mapped port
        if (self.automaticallyMapPort) {
            initialPortMapping = (int)self.externalPort;
        }
        
		// initialise the mapper
		_portMapper = [[MGSPortMapper alloc] initWithExternalPort:initialPortMapping listeningPort:(int)self.listeningPort];
		_portMapper.delegate = self;
		
	}
	
    return _portMapper;
}

/*
 
 - refreshPortMapping
 
 */
- (void)refreshPortMapping
{
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
    self.mappingProtocol = [_portMapper mappingProtocol];
    
    switch ([_portMapper mappingStatus])
    {
        case TCMPortMappingStatusTrying:
            self.mappingStatus = kMGSInternetSharingPortTryingToMap;
            break;
            
        case TCMPortMappingStatusMapped:
            self.mappingStatus = kMGSInternetSharingPortMapped;
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
    
    if (self.doPortCheckWhenPortMapperFinishes) {
        [self startPortChecking];
    }
}

/*
 
 - portMapperDidFindRouter
 
 */
- (void)portMapperDidFindRouter
{
    if ([_portMapper gatewayName]) {
        self.gatewayName = [_portMapper gatewayName];
    }
    
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
    
    if (!self.portMapperIsWorking) {
        [self postPortMapperStatus];
    }
}

/*
 
 - portMapperExternalIPAddressDidChange
 
 */
- (void)portMapperExternalIPAddressDidChange
{
    self.IPAddressString = [_portMapper externalIPAddress];

    if (!self.portMapperIsWorking) {
        [self postPortMapperStatus];
    }
}


/*
 
 - portMappingDidChangeMappingStatus
 
 */
- (void)portMappingDidChangeMappingStatus
{
    if (!self.portMapperIsWorking) {
        [self postPortMapperStatus];
    }
}

#pragma mark -
#pragma mark MGSPortCheckerDelegate

/*
 
 - portCheckerDidFinishProbing:
 
 */

- (void)portCheckerDidFinishProbing:(MGSPortChecker *)portChecker
{

    // update address only if port checker has found a valid IP.
    // note that we will receive the IP address even if the port is closed.
    if ([portChecker.gatewayAddress mgs_isIPAddress] && ![portChecker.gatewayAddress isEqualToString:@"0.0.0.0"]) {
        self.IPAddressString = portChecker.gatewayAddress;
    } else {
        self.IPAddressString = _portMapper.externalIPAddress;
    }
    
    switch ([portChecker status]) {
        case kMGS_PORT_STATUS_NA:
            self.portReachabilityStatus = kMGSPortReachabilityNA;
        break;

        case kMGS_PORT_STATUS_OPEN:
            self.portReachabilityStatus = kMGSPortReachable;
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
}

/*
 
 - setPortCheckerIsWorking:
 
 */
- (void)setPortCheckerIsWorking:(BOOL)value
{
    _portCheckerIsWorking = value;
    NSMutableDictionary *dict = nil;
    
    if (_portCheckerIsWorking) {
        dict =  [NSMutableDictionary dictionaryWithObjectsAndKeys:
                    @YES, MGSInternetSharingKeyPortCheckerActive,
                    [NSNumber numberWithInteger:[self portReachabilityStatus]], MGSInternetSharingKeyReachabilityStatus,
                    nil];
    } else {
        dict = [self portCheckerStatusDictionary];
        [dict setObject:@NO forKey:MGSInternetSharingKeyPortCheckerActive];
    }
    [self postDistributedResponseNotificationWithDict:dict];
}
/*
 
 - setPortMapperIsWorking:
 
 */
- (void)setPortMapperIsWorking:(BOOL)value
{
    _portMapperIsWorking = value;
    NSMutableDictionary *dict = nil;
    
    if (_portMapperIsWorking) {
        dict =  [NSMutableDictionary dictionaryWithObjectsAndKeys:
                 @YES, MGSInternetSharingKeyPortMapperActive,
                 @(kMGSInternetSharingPortTryingToMap), MGSInternetSharingKeyMappingStatus,
                 nil];

    } else {
        dict = [self portMapperStatusDictionary];
        [dict setObject:@NO forKey:MGSInternetSharingKeyPortMapperActive];
    }
    [self postDistributedResponseNotificationWithDict:dict];
}

/*
 
 - postPortCheckerStatus
 
 */
- (void)postPortCheckerStatus
{
    NSMutableDictionary *dict = [self portCheckerStatusDictionary];

    [self postDistributedResponseNotificationWithDict:dict];

}
/*
 
 - portCheckerStatusDictionary
 
 */
- (NSMutableDictionary *)portCheckerStatusDictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 @NO, MGSInternetSharingKeyPortCheckerActive,
                                 [NSNumber numberWithInteger:[self portReachabilityStatus]], MGSInternetSharingKeyReachabilityStatus,
                                 [self IPAddressString], MGSInternetSharingKeyIPAddress,
                                 nil];
    
    return dict;
    
}
/*
 
 - postPortMapperStatus
 
 */
- (void)postPortMapperStatus
{
    NSMutableDictionary *dict = [self portMapperStatusDictionary];
    [self postDistributedResponseNotificationWithDict:dict];

}
/*
 
 - portMapperStatusDictionary
 
 */
- (NSMutableDictionary *)portMapperStatusDictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 @NO, MGSInternetSharingKeyPortMapperActive,
                                 [NSNumber numberWithInteger:kMGSInternetSharingRequestStatus], MGSInternetSharingKeyRequest,
                                 [NSNumber numberWithInteger:[self mappingStatus]], MGSInternetSharingKeyMappingStatus,
                                 [NSNumber numberWithInteger:[self mappingProtocol]], MGSInternetSharingKeyMappingProtocol,
                                 [NSNumber numberWithInteger:[self routerStatus]], MGSInternetSharingKeyRouterStatus,
                                 [self IPAddressString], MGSInternetSharingKeyIPAddress,
                                 [self gatewayName], MGSInternetSharingKeyGatewayName,
                                 [NSNumber numberWithInteger:self.externalPort], MGSExternalPortNumber,
                                 [NSNumber numberWithBool:self.automaticallyMapPort], MGSEnableInternetAccessAtLogin,
                                 nil];
    
    return dict;
}
@end
