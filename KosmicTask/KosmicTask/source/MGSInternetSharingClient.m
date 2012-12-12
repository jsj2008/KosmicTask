//
//  MGSInternetSharingClient.m
//  Mother
//
//  Created by Jonathan on 08/09/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSInternetSharingClient.h"
#import "MGSDistributedNotifications.h"
#import "MGSPreferences.h"
#import "NSDictionary_Mugginsoft.h"
#import "MGSImageManager.h"

// class extension
@interface MGSInternetSharingClient()
- (void)response:(NSNotification *)note;
- (void)externalPortWasChanged;
- (void)cancelPortChangeRequest;

@property NSString *portStatusText;
@property NSString *routerStatusText;
@property NSString *mappingProtocolText;
@property BOOL portMapperIsWorking;
@property BOOL portCheckerIsWorking;
@property (readwrite) NSString *desiredPortNumberText;

@end

@implementation MGSInternetSharingClient

static id _sharedInstance = nil;

@synthesize startStopButtonText = _startStopButtonText;
@synthesize portStatusText = _portStatusText;
@synthesize routerStatusText = _routerStatusText;
@synthesize portMapperIsWorking = _portMapperIsWorking;
@synthesize portCheckerIsWorking = _portCheckerIsWorking;
@synthesize mappingProtocolText = _mappingProtocolText;
@synthesize desiredPortNumberText = _desiredPortNumberText;

#pragma mark -
#pragma mark Factory
/*
 
 shared instance
 
 */
+ (id)sharedInstance
{
	if (!_sharedInstance) {
		_sharedInstance = [[self alloc] init];
	}
	
	return _sharedInstance;
}

#pragma mark -
#pragma mark Instance
/*
 
 init
 
 */
- (id)init
{
   
	if ((self = [super init])) {
		_portMapperIsWorking = NO;
		_portCheckerIsWorking = NO;
        _processingResponse = NO;
        
		// standard app icon image
		_appIconImage = [[NSApp applicationIconImage] copy];
		
		// active internet sharing app icon image
		_appActiveSharingIconImage = [_appIconImage copy];
		[_appActiveSharingIconImage lockFocus];
		NSImage *orb = [self.activeStatusLargeImage copy];
		[orb setSize:NSMakeSize(56, 56)];
		//CGFloat x = ([_appActiveSharingIconImage size].width - [orb size].width)/2;
		//CGFloat y = ([_appActiveSharingIconImage size].height - [orb size].height)/2;
		
		[orb compositeToPoint:NSMakePoint(0, 0) operation:NSCompositeSourceOver];
		[_appActiveSharingIconImage unlockFocus];		
		
		// register for status update notification
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(response:) 
																name:MGSDistNoteInternetSharingResponse object:self.noteObjectString];
        
        [self requestStatusUpdate];
	}
	
	return self;
}

#pragma mark -
#pragma mark Notification handling
/*
 
 - requestStatusUpdate
 
 */
- (void)requestStatusUpdate
{
	NSDictionary *requestDict = [NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInteger:kMGSInternetSharingRequestStatus], MGSInternetSharingKeyRequest,
                                 [NSNumber numberWithBool:YES], MGSInternetSharingKeyResponseRequired,
								 nil];
	
	[self postDistributedRequestNotificationWithDict:requestDict];
}


/*
 
 - requestPortCheck
 
 */
- (void)requestPortCheck
{
	NSDictionary *requestDict = [NSDictionary dictionaryWithObjectsAndKeys: 
								 [NSNumber numberWithInteger:kMGSInternetSharingRequestPortCheck], MGSInternetSharingKeyRequest,
                                 [NSNumber numberWithInteger:self.externalPort], MGSExternalPortNumber,
                                 [NSNumber numberWithBool:YES], MGSInternetSharingKeyResponseRequired,
								 nil];
	
	[self postDistributedRequestNotificationWithDict:requestDict];
}

/*
 
 - requestMappingRefresh
 
 */
- (void)requestMappingRefresh
{
	NSDictionary *requestDict = [NSDictionary dictionaryWithObjectsAndKeys:
								 @(kMGSInternetSharingRequestRefreshMapping), MGSInternetSharingKeyRequest,
                                 @YES, MGSInternetSharingKeyResponseRequired,
								 nil];
	
	[self postDistributedRequestNotificationWithDict:requestDict];
}


/*
 
 response notification
 
 */
- (void)response:(NSNotification *)note
{
    BOOL requestPortCheck = NO;
	_processingResponse = YES;
	NSDictionary *userInfo = [note userInfo];
	
	MLog(DEBUGLOG, @"Internet sharing response dict received by client: %@", [userInfo propertyListStringValue]);
	
	// get the request id
	MGSInternetSharingRequestID requestID = [[userInfo objectForKey:MGSInternetSharingKeyRequest] integerValue];
	
	switch (requestID) {
			
			// status request
		case kMGSInternetSharingRequestStatus:
        {
            id obj = nil;

            if ((obj = [userInfo objectForKey:MGSInternetSharingKeyPortMapperActive])) {
                
                self.portMapperIsWorking = [obj boolValue];
                
                // request a port check when mapper is done
                if (!self.portMapperIsWorking) {
                    requestPortCheck = YES;
                }
            }

            if ((obj = [userInfo objectForKey:MGSInternetSharingKeyPortCheckerActive])) {
                self.portCheckerIsWorking = [obj boolValue];
            }

            if ((obj = [userInfo objectForKey:MGSInternetSharingKeyMappingStatus])) {
                self.mappingStatus = [obj integerValue];
                
            }
            if ((obj = [userInfo objectForKey:MGSInternetSharingKeyRouterStatus])) {
                
                MGSInternetSharingRouterStatus prevRouterStatus = self.routerStatus;
                
                self.routerStatus = [obj integerValue];
                
                if (prevRouterStatus != self.routerStatus) {
                    requestPortCheck = YES;
                }

            }
            
            if ((obj = [userInfo objectForKey:MGSInternetSharingKeyMappingProtocol])) {
                self.mappingProtocol = [obj integerValue];
            }
            
            if ((obj = [userInfo objectForKey:MGSExternalPortNumber])) {
                
                NSInteger portNumber =  [obj integerValue];
                
                if (portNumber != self.externalPort) {
                    self.desiredPortNumberText = [NSString stringWithFormat:@"%@\n%lu %@",
                                                  NSLocalizedString(@"Desired port", @"comment"),
                                                  (long) self.externalPort,
                                                  NSLocalizedString(@"is in use", @"comment")
                                                  ];
                } else {
                    self.desiredPortNumberText = @"";
                }
                self.externalPort = portNumber;
            }
            
            if ((obj = [userInfo objectForKey:MGSAllowInternetAccess])) {
                self.allowInternetAccess = [obj boolValue];
            }
            
            if ((obj = [userInfo objectForKey:MGSAllowLocalAccess])) {
                self.allowLocalAccess = [obj boolValue];
            }
            
            if ((obj = [userInfo objectForKey:MGSEnableInternetAccessAtLogin])) {
                self.automaticallyMapPort = [obj boolValue];
            }
            
            if ((obj = [userInfo objectForKey:MGSInternetSharingKeyIPAddress])) {
                self.IPAddressString = obj;
            }
            
            if ((obj = [userInfo objectForKey:MGSInternetSharingKeyGatewayName])) {
                self.gatewayName = obj;
            }
            
            if ((obj = [userInfo objectForKey:MGSAllowLocalUsersToAuthenticate])) {
                self.allowLocalUsersToAuthenticate = [obj boolValue];
            }
            
            if ((obj = [userInfo objectForKey:MGSAllowRemoteUsersToAuthenticate])) {
                self.allowRemoteUsersToAuthenticate = [obj boolValue];
            }
            
            if ((obj = [userInfo objectForKey:MGSInternetSharingKeyReachabilityStatus])) {
                self.portReachabilityStatus = [obj integerValue];
            }
        }
        break;
			
			// unrecognised
            
		default:
			MLog(RELEASELOG, @"unrecognised internet sharing request id: %i", requestID);
			break;
	}

	_processingResponse = NO;
    
    NSInvocation *requestInvocation = nil;
    if (_portMapperRequestInvocation) {
        requestInvocation = _portMapperRequestInvocation;
        _portMapperRequestInvocation = nil;
    } else if (_portCheckerRequestInvocation) {
        requestInvocation = _portCheckerRequestInvocation;
        _portCheckerRequestInvocation = nil;
    }

    // if we have an outstanding request invocation then invoke it
    if (requestInvocation) {
        
        NSDictionary *dict = nil;
        [requestInvocation getArgument:&dict atIndex:2];
        
        // dict must be a property list
        if (![NSPropertyListSerialization propertyList:dict isValidForFormat:NSPropertyListXMLFormat_v1_0]) {
            MLogInfo(@"Invalid property list detected prior to invocation: %@", dict);
        } else {
            [requestInvocation invoke];
        }
        
        // any port check is now redundant
        requestPortCheck = NO;
    }
    
    if (requestPortCheck) {
        [self requestPortCheck];
    }

}

/*
 
 post distributed request notification with dictionary
 
 */
- (void)postDistributedRequestNotificationWithDict:(NSDictionary *)dict
{
    BOOL useInvocation = YES;
    
    if (useInvocation && (self.portMapperIsWorking || self.portCheckerIsWorking)) {
        
        // dict must be a property list
        if (![NSPropertyListSerialization propertyList:dict isValidForFormat:NSPropertyListXMLFormat_v1_0]) {
            MLogInfo(@"Invalid property list detected: %@", dict);
            return;
        }

        NSMethodSignature *aSignature = [[self class] instanceMethodSignatureForSelector:_cmd];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:aSignature];
        invocation.target = self;
        invocation.selector = _cmd;
        [invocation setArgument:&dict atIndex:2];
        [invocation retainArguments];
        
        if (self.portMapperIsWorking) {
            _portMapperRequestInvocation = invocation;
            _portCheckerRequestInvocation = nil;
        } else {
            _portCheckerRequestInvocation = invocation;
        }
        
#undef MGS_DEBUG_INVOCATION
#ifdef MGS_DEBUG_INVOCATION
        MLogInfo(@"Property list set as argument to invocation: %@", dict);
#endif       
        
        return;
    }
    
	[super postDistributedRequestNotificationWithDict:dict];
}

#pragma mark -
#pragma mark Accessors
/*
 
 - setAllowInternetAccess:
 
 */
- (void)setAllowInternetAccess:(BOOL)value
{
	[super setAllowInternetAccess:value];
	
	// if not processing response
	if (!_processingResponse) {
		BOOL responseRequired = YES;
        
		NSDictionary *requestDict = [NSDictionary dictionaryWithObjectsAndKeys: 
									 [NSNumber numberWithInteger:kMGSInternetSharingRequestInternetAccess], MGSInternetSharingKeyRequest,
									 [NSNumber numberWithBool:value], MGSAllowInternetAccess,
                                     [NSNumber numberWithBool:responseRequired], MGSInternetSharingKeyResponseRequired,
									 nil];
		
		[self postDistributedRequestNotificationWithDict:requestDict];
		
	}
}

/*
 
 - setAllowLocalAccess:
 
 */
- (void)setAllowLocalAccess:(BOOL)value
{
	[super setAllowLocalAccess:value];
	
	// if not processing response
	if (!_processingResponse) {
		
		NSDictionary *requestDict = [NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithInteger:kMGSInternetSharingRequestLocalAccess], MGSInternetSharingKeyRequest,
									 [NSNumber numberWithBool:value], MGSAllowLocalAccess,
									 nil];
		
		[self postDistributedRequestNotificationWithDict:requestDict];
		
	}
}



/*
 
 - setAllowLocalUsersToAuthenticate:
 
 */
- (void)setAllowLocalUsersToAuthenticate:(BOOL)value
{
	[super setAllowLocalUsersToAuthenticate:value];
	
	// if not processing response
	if (!_processingResponse) {
		
		NSDictionary *requestDict = [NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithInteger:kMGSInternetSharingRequestAllowLocalAuthentication], MGSInternetSharingKeyRequest,
									 [NSNumber numberWithBool:value], MGSAllowLocalUsersToAuthenticate,
									 nil];
		
		[self postDistributedRequestNotificationWithDict:requestDict];
		
	}
}

/*
 
 - setAllowRemoteUsersToAuthenticate:
 
 */
- (void)setAllowRemoteUsersToAuthenticate:(BOOL)value
{
	[super setAllowRemoteUsersToAuthenticate:value];
	
	// if not processing response
	if (!_processingResponse) {
		
		NSDictionary *requestDict = [NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithInteger:kMGSInternetSharingRequestAllowRemoteAuthentication], MGSInternetSharingKeyRequest,
									 [NSNumber numberWithBool:value], MGSAllowRemoteUsersToAuthenticate,
									 nil];
		
		[self postDistributedRequestNotificationWithDict:requestDict];
		
	}
}
/*
 
 set enable internet access at login
 
 */
- (void)setAutomaticallyMapPort:(BOOL)value
{
	[super setAutomaticallyMapPort:value];
    [self cancelPortChangeRequest];
    
	// if not processing response
	if (!_processingResponse) {
		
		NSDictionary *requestDict = [NSDictionary dictionaryWithObjectsAndKeys: 
									 [NSNumber numberWithInteger:kMGSInternetSharingRequestMapPort], MGSInternetSharingKeyRequest,
									 [NSNumber numberWithBool:value], MGSEnableInternetAccessAtLogin,
                                     [NSNumber numberWithInteger:self.externalPort], MGSExternalPortNumber,
                                     [NSNumber numberWithBool:YES], MGSInternetSharingKeyResponseRequired,
									 nil];
		
		[self postDistributedRequestNotificationWithDict:requestDict];
		
	}
}

/*
 
 - setExternalPort:
 
 */
- (void)setExternalPort:(NSInteger)externalPort
{
    [super setExternalPort:externalPort];
    [self cancelPortChangeRequest];
    
    // delay invoking this method to allow for the case were we change the port
    // then click the map button.
    // this approach allows us to coallesce two calls to the server into one.
    [self performSelector:@selector(externalPortWasChanged) withObject:nil afterDelay:0.1];
}

/*
 
 - setReachabilityStatus:
 
 */
- (void)setPortReachabilityStatus:(MGSPortReachability)status
{
	[super setPortReachabilityStatus:status];
	
	switch (self.portReachabilityStatus) {
		case kMGSPortReachabilityNA:
            self.portStatusText = NSLocalizedString(@"No (check did not complete)", @"Reachability not available");
			break;
			
		case kMGSPortReachable:
            self.portStatusText = NSLocalizedString(@"Yes", @"Port is reachable");
			break;
			
        case kMGSPortTryingToReach:
            self.portStatusText = NSLocalizedString(@"Checking port...", @"Trying port");
            break;
            
		case kMGSPortNotReachable:
		default:
            self.portStatusText = NSLocalizedString(@"No", @"Port is not reachable");
			break;
			
	}
}

#pragma mark -
#pragma mark Validation

/*
 
 - setRouterStatus:
 
 */
- (void)setRouterStatus:(MGSInternetSharingRouterStatus)value
{
    super.routerStatus = value;
    
    switch (self.routerStatus) {
            
        // cannot determine the router status
        case kMGSInternetSharingRouterUnknown:
            self.routerStatusText = NSLocalizedString(@"Not available", @"Comment");
            break;
            
        // router connected and has an external IP
        case kMGSInternetSharingRouterHasExternalIP:
            self.routerStatusText = NSLocalizedString(@"Connected and has IP address", @"Comment");
            break;
            
        // router does not support UPnP or NAT-PMP
        case kMGSInternetSharingRouterIncompatible:
            self.routerStatusText = NSLocalizedString(@"Connected", @"Comment");
            break;
            
        // router not found on network
        case kMGSInternetSharingRouterNotFound:
            self.routerStatusText = NSLocalizedString(@"Not found", @"Comment");
            break;
    }
}

/*
 
 - setRouterStatus:
 
 */
- (void)setMappingProtocol:(MGSPortMapperProtocol)value
{
    super.mappingProtocol = value;
    
    switch (self.mappingProtocol) {
        case kMGSPortMapperProtocolNone:
            self.mappingProtocolText =  NSLocalizedString(@"Auto mapping is not available", @"Comment");
            break;
            
        case kMGSPortMapperProtocolUPNP:
            self.mappingProtocolText =  NSLocalizedString(@"UPnP", @"Comment");
            break;

        case kMGSPortMapperProtocolNAT_PMP:
            self.mappingProtocolText =  NSLocalizedString(@"NAT-PMP", @"Comment");
            break;

        case kMGSPortMapperProtocolBoth:
            self.mappingProtocolText =  NSLocalizedString(@"Both", @"Comment");
            break;
    }
}

#pragma mark -
#pragma mark External port change request handling
/*
 
 - externalPortWasChanged
 
 */
- (void)externalPortWasChanged
{
    if (!_processingResponse) {
        if (self.automaticallyMapPort) {
            self.automaticallyMapPort = YES;    // force remap
        } else {
            [self requestPortCheck];
        }
    }
}

/*
 
 - cancelPortChangeRequest
 
 */
- (void)cancelPortChangeRequest
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(externalPortWasChanged) object:nil];
}
@end
