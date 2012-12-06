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
- (void)validateRouterStatus:(id)sender;

@property NSString *portStatusText;
@property NSString *routerStatusText;
@property BOOL portMapperIsWorking;
@property BOOL portCheckerIsWorking;

@end

@implementation MGSInternetSharingClient

static id _sharedInstance = nil;

@synthesize startStopButtonText = _startStopButtonText;
@synthesize portStatusText = _portStatusText;
@synthesize routerStatusText = _routerStatusText;
@synthesize portMapperIsWorking = _portMapperIsWorking;
@synthesize portCheckerIsWorking = _portCheckerIsWorking;

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
                    [self requestPortCheck];
                }
            }

            if ((obj = [userInfo objectForKey:MGSInternetSharingKeyPortCheckerActive])) {
                self.portCheckerIsWorking = [obj boolValue];
            }

            if ((obj = [userInfo objectForKey:MGSInternetSharingKeyMappingStatus])) {
                self.mappingStatus = [obj integerValue];
            }
            if ((obj = [userInfo objectForKey:MGSInternetSharingKeyRouterStatus])) {
                self.routerStatus = [obj integerValue];
                [self performSelector:@selector(validateRouterStatus:) withObject:nil afterDelay:0];
            }
            
            if ((obj = [userInfo objectForKey:MGSExternalPortNumber])) {
                self.externalPort = [obj integerValue];
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
    
    // if we have an outstanding request invocation then invoke it
    if (_requestInvocation) {
        
        NSDictionary *dict = nil;
        [_requestInvocation getArgument:&dict atIndex:2];
        
        // dict must be a property list
        if (![NSPropertyListSerialization propertyList:dict isValidForFormat:NSPropertyListXMLFormat_v1_0]) {
            MLogInfo(@"Invalid property list detected prior to invocation: %@", dict);
        } else {
            [_requestInvocation invoke];
        }
        
        _requestInvocation = nil;
        
    }
}

/*
 
 post distributed request notification with dictionary
 
 */
- (void)postDistributedRequestNotificationWithDict:(NSDictionary *)dict
{
    BOOL useInvocation = NO;
    
    // are we awaiting a response?
    if (useInvocation) {
        
        // dict must be a property list
        if (![NSPropertyListSerialization propertyList:dict isValidForFormat:NSPropertyListXMLFormat_v1_0]) {
            MLogInfo(@"Invalid property list detected: %@", dict);
            return;
        }

        // this approach fails because when invoked the dict argument
        // seems to contain a CFType which is invalid for a Plist
        NSMethodSignature *aSignature = [[self class] instanceMethodSignatureForSelector:_cmd];
        _requestInvocation = [NSInvocation invocationWithMethodSignature:aSignature];
        _requestInvocation.target = self;
        _requestInvocation.selector = _cmd;
        [_requestInvocation setArgument:&dict atIndex:2];
        [_requestInvocation setArgument:&wait atIndex:3];
        [_requestInvocation retainArguments];
        
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
 
 set mapping status _
 
 */
- (void)setMappingStatus:(MGSInternetSharingMappingStatus)mappingStatus
{
	
	// mapping status
	[super setMappingStatus:mappingStatus];
	/*
	[self willChangeValueForKey:@"startStopButtonText"];
	
	switch (self.mappingStatus) {
		case kMGSInternetSharingPortTryingToMap:
			_startStopButtonText = NSLocalizedString(@"...", @"Trying to map router port");
            self.portStatusText = NSLocalizedString(@"...", @"Trying to map router port");
			break;
			
		case kMGSInternetSharingPortMapped:
			_startStopButtonText = NSLocalizedString(@"Close", @"Router port mapped");
            self.portStatusText = NSLocalizedString(@"open", @"Port is open");
			break;
			
		case kMGSInternetSharingPortNotMapped:
		default:
			_startStopButtonText = NSLocalizedString(@"Open", @"Router port not mapped");
            self.portStatusText = NSLocalizedString(@"closed", @"Port is closed");
			break;
			
	}
	[self didChangeValueForKey:@"startStopButtonText"];
	*/
	// update application icon to reflect Internet sharing status
	/*NSImage *appIconImage;
	if (self.isActive) {
		appIconImage = _appActiveSharingIconImage;
	} else {
		appIconImage = _appIconImage;
	}*/

	// set application icon
	// note that whatever is set here seems to get used when creating
	// miniwindows for other application windows.
	// so if the orb is displayed here then it will appear in the miniwindows too.
	// if the sharing is subsequently stopped then the miniwindow display may be out of sync.
	//[NSApp setApplicationIconImage: appIconImage];
	// or update dock tile
	// this seems to cause an icon flash
	//NSDockTile *dockTile = [NSApp dockTile];
	//[dockTile setContentView:[[MGSImageManager sharedManager] imageView:appIconImage]];
	//[dockTile display];
}

/*
 
 - setReachabilityStatus:
 
 */
- (void)setPortReachabilityStatus:(MGSPortReachability)status
{
	[super setPortReachabilityStatus:status];
	
	switch (self.portReachabilityStatus) {
		case kMGSPortReachabilityNA:
            self.portStatusText = NSLocalizedString(@"No (?)", @"Reachability not available");
			break;
			
		case kMGSPortReachable:
            self.portStatusText = NSLocalizedString(@"Yes", @"Port is reachable");
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
 
 - validateRouterStatus:
 
 */
- (void)validateRouterStatus:(id)sender
{
#pragma unused(sender)
    
    switch (self.routerStatus) {
            
        // cannot determine the router status
        case kMGSInternetSharingRouterUnknown:
            self.routerStatusText = NSLocalizedString(@"Status unknown", @"Comment");
            break;
            
        // router connected and has an external IP
        case kMGSInternetSharingRouterHasExternalIP:
            self.routerStatusText = NSLocalizedString(@"Has external IP", @"Comment");
            break;
            
        // router does not support UPnP or NAT-PMP
        case kMGSInternetSharingRouterIncompatible:
            self.routerStatusText = NSLocalizedString(@"No auto map support", @"Comment");
            break;
            
        // router not found on network
        case kMGSInternetSharingRouterNotFound:
            self.routerStatusText = NSLocalizedString(@"Router not found", @"Comment");
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
            self.automaticallyMapPort = self.automaticallyMapPort;
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
