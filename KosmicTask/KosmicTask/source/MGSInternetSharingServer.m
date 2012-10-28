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
@end

@implementation MGSInternetSharingServer

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
		
		self.listeningPort = listeningPort;
		
		// register to receive internet sharing request notification
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(request:) 
																name:MGSDistNoteInternetSharingRequest object:self.noteObjectString];
	
		// read preferences
		MGSPreferences *preferences = [MGSPreferences standardUserDefaults];
		
		if ([preferences objectForKey:MGSExternalPortNumber]) {
			self.externalPort = [preferences integerForKey:MGSExternalPortNumber];
		} else {
			self.externalPort = externalPort; 
		}
		
		self.allowInternetAccess = [preferences boolForKey:MGSAllowInternetAccess];
        self.allowLocalAccess = [preferences boolForKey:MGSAllowLocalAccess];
		self.automaticallyMapPort = [preferences boolForKey:MGSEnableInternetAccessAtLogin];
		self.allowLocalUsersToAuthenticate = [preferences boolForKey:MGSAllowLocalUsersToAuthenticate];
		self.allowRemoteUsersToAuthenticate = [preferences boolForKey:MGSAllowRemoteUsersToAuthenticate];
        
        if (self.automaticallyMapPort) {
            [self startPortMapping];
        }
        
        // Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the
        // method "reachabilityChanged" will be called.
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];

        _internetReach = [Reachability reachabilityForInternetConnection];
        [_internetReach startNotifier];
        
        if (!_notificationPending) {
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
    if (_notificationPending) {
        return;
    }
    
	NSDictionary *userInfo = [note userInfo];
    
	// get the request id
	MGSInternetSharingRequestID requestID = [[userInfo objectForKey:MGSInternetSharingKeyRequest] integerValue];
	
	switch (requestID) {
			
            // status request
		case kMGSInternetSharingRequestStatus:
        {
			NSInteger port = [[userInfo objectForKey:MGSExternalPortNumber] integerValue];
            if (port == 0) {
                break;
            }
            self.externalPort = port;
            
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
            NSInteger prevPort = self.externalPort;
			NSInteger port = [[userInfo objectForKey:MGSExternalPortNumber] integerValue];
            if (port == 0) {
                break;
            }
            self.externalPort = port;
			self.automaticallyMapPort = [[userInfo objectForKey:MGSEnableInternetAccessAtLogin] boolValue];
            
            if (self.automaticallyMapPort) {
                
                if ([self mappingStatus] == kMGSInternetSharingPortMapped) {
                    self.externalPort = prevPort;
                    MLog(RELEASELOG, @"Cannot complete map port request as mapping is already active.");
                    break;
                }
                
                // if no port mapper defined then start it up
                if (!_portMapper) {
                    [self startPortMapping];
                 } else {
                     
                     // if port has changed then remap, otherwise start
                     if (prevPort != self.externalPort) {
                         [self remapPortMapping];
                         [self startPortMapping];
                     } else {
                         [self startPortMapping];
                     }
                }
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
	
    if (!_notificationPending) {
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
    
    _notificationPending = NO;
}

/*
 
 status dictionary
 
 */
- (NSDictionary *)statusDictionary
{
	NSDictionary *dict =  [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithInteger:kMGSInternetSharingRequestStatus], MGSInternetSharingKeyRequest,
                           [NSNumber numberWithInteger:[self mappingStatus]], MGSInternetSharingKeyMappingStatus,
                           [NSNumber numberWithInteger:[self reachabilityStatus]], MGSInternetSharingKeyReachabilityStatus,
                           [self IPAddressString], MGSInternetSharingKeyIPAddress,
                           [self gatewayName], MGSInternetSharingKeyGatewayName,
                           [NSNumber numberWithInteger:self.externalPort], MGSExternalPortNumber,
                           [NSNumber numberWithBool:self.allowInternetAccess], MGSAllowInternetAccess,
                           [NSNumber numberWithBool:self.allowLocalAccess], MGSAllowLocalAccess,
                           [NSNumber numberWithBool:self.automaticallyMapPort], MGSEnableInternetAccessAtLogin,
                           [NSNumber numberWithBool:self.allowLocalUsersToAuthenticate], MGSAllowLocalUsersToAuthenticate,
                           [NSNumber numberWithBool:self.allowRemoteUsersToAuthenticate], MGSAllowRemoteUsersToAuthenticate,
                           nil];
	
	MLog(DEBUGLOG, @"Internet sharing response dict sent by server: %@", [dict propertyListStringValue]);
	
	return dict;
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
    
    if (!_notificationPending) {
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
    self.reachabilityStatus = kMGSPortReachabilityNA;
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

    _notificationPending = YES;
    [_portChecker start];
}

/*
 
 - stopPortChecking
 
 */
- (void)stopPortChecking
{
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
	// make sure that we have initialised
    if (!_portMapper) {
        [self initialisePortMapping];
	}
    
	// start mapping if port mot mapped
	if ([self mappingStatus] == kMGSInternetSharingPortNotMapped) {
        _notificationPending = YES;
		[_portMapper startMapping];
	}
}

/*
 
 remap port mapping
 
 */
- (void)remapPortMapping
{
	if (_portMapper) {
		if (self.externalPort > 0) {
             _notificationPending = YES;
			[_portMapper remapWithExternalPort:self.externalPort listeningPort:self.listeningPort];
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
             _notificationPending = YES;
            [_portMapper stopMapping];
        }
    } else {
		MLogInfo(@"Cannot stop. Port mapper is not allocated.");        
    }
}

/*
 
 initialise port mapping
 
 */
- (void)initialisePortMapping
{
	NSAssert(self.listeningPort != 0, @"Cannot start port mapper as listening port not defined");
	
	// lazy allocation
	if (!_portMapper) {
		
		// validate external port
		if (self.externalPort == 0) {
			return;
		}
		
		// initialise the mapper
		_portMapper = [[MGSPortMapper alloc] initWithExternalPort:self.externalPort listeningPort:self.listeningPort];
		_portMapper.delegate = self;
		
	}
	
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
	//[self postStatusNotification];
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
	
	[self startPortChecking];
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
            self.reachabilityStatus = kMGSPortReachabilityNA;
        break;

        case kMGS_PORT_STATUS_OPEN:
            self.reachabilityStatus = kMGSPortReachable;
            self.externalPort = portChecker.portNumber;
            self.IPAddressString = portChecker.gatewayAddress;
        break;

        case kMGS_PORT_STATUS_CLOSED:
            self.reachabilityStatus = kMGSPortNotReachable;
        break;

        case kMGS_PORT_STATUS_ERROR:
        default:
            self.reachabilityStatus = kMGSPortReachabilityNA;
        break;
    }
    
    [self postStatusNotification];
    
}

@end
