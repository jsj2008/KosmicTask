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
@end

@implementation MGSInternetSharingClient

static id _sharedInstance = nil;

@synthesize startStopButtonText = _startStopButtonText;
@synthesize portStatusText = _portStatusText;

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
		
		// request a status update
		[self requestStatusUpdate];
				
	}
	
	return self;
}

#pragma mark -
#pragma mark Notification handling
/*
 
 request a status update
 
 */
- (void)requestStatusUpdate
{
	NSDictionary *requestDict = [NSDictionary dictionaryWithObjectsAndKeys: 
								 [NSNumber numberWithInteger:kMGSInternetSharingRequestStatus], MGSInternetSharingKeyRequest,
                                 [NSNumber numberWithInteger:self.externalPort], MGSExternalPortNumber,
								 nil];
	
	[self postDistributedRequestNotificationWithDict:requestDict waitOnResponse:YES];
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
			self.mappingStatus = [[userInfo objectForKey:MGSInternetSharingKeyMappingStatus] integerValue];
			self.externalPort = [[userInfo objectForKey:MGSExternalPortNumber] integerValue];
			self.allowInternetAccess = [[userInfo objectForKey:MGSAllowInternetAccess] boolValue];
			self.allowLocalAccess = [[userInfo objectForKey:MGSAllowLocalAccess] boolValue];
			self.automaticallyMapPort = [[userInfo objectForKey:MGSEnableInternetAccessAtLogin] boolValue];
			self.IPAddressString = [userInfo objectForKey:MGSInternetSharingKeyIPAddress];
			self.gatewayName = [userInfo objectForKey:MGSInternetSharingKeyGatewayName];
			self.allowLocalUsersToAuthenticate = [[userInfo objectForKey:MGSAllowLocalUsersToAuthenticate] boolValue];
			self.allowRemoteUsersToAuthenticate = [[userInfo objectForKey:MGSAllowRemoteUsersToAuthenticate] boolValue];
            self.reachabilityStatus = [[userInfo objectForKey:MGSInternetSharingKeyReachabilityStatus] integerValue];
			break;
			
			// unrecognised
		default:
			MLog(RELEASELOG, @"unrecognised internet sharing request id: %i", requestID);
			break;
	}

	_processingResponse = NO;
	self.responseReceived = YES;
    
    if (_requestInvocation) {
        [_requestInvocation invoke];
        _requestInvocation = nil;
    }
}

/*
 
 post distributed request notification with dictionary
 
 */
- (void)postDistributedRequestNotificationWithDict:(NSDictionary *)dict waitOnResponse:(BOOL)wait
{
    // are we awaiting a reponse?
    if (!self.responseReceived) {
        
        NSMethodSignature *aSignature = [[self class] instanceMethodSignatureForSelector:_cmd];
        _requestInvocation = [NSInvocation invocationWithMethodSignature:aSignature];
        _requestInvocation.target = self;
        [_requestInvocation setArgument:dict atIndex:2];
        [_requestInvocation setArgument:&wait atIndex:3];
        [_requestInvocation retainArguments];
        
        return;
    }
    
	if (wait) {
        self.responseReceived = NO;
	}
    
	// send out a distributed notification
	[[NSDistributedNotificationCenter defaultCenter]
     postNotificationName: MGSDistNoteInternetSharingRequest
     object:self.noteObjectString
     userInfo:dict
     deliverImmediately:YES];
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
		
		NSDictionary *requestDict = [NSDictionary dictionaryWithObjectsAndKeys: 
									 [NSNumber numberWithInteger:kMGSInternetSharingRequestInternetAccess], MGSInternetSharingKeyRequest,
									 [NSNumber numberWithBool:value], MGSAllowInternetAccess,
									 nil];
		
		[self postDistributedRequestNotificationWithDict:requestDict waitOnResponse:YES];
		
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
		
		[self postDistributedRequestNotificationWithDict:requestDict waitOnResponse:NO];
		
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
		
		[self postDistributedRequestNotificationWithDict:requestDict waitOnResponse:NO];
		
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
		
		[self postDistributedRequestNotificationWithDict:requestDict waitOnResponse:NO];
		
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
									 nil];
		
		[self postDistributedRequestNotificationWithDict:requestDict waitOnResponse:YES];
		
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
- (void)setReachabilityStatus:(MGSPortReachability)status
{
	[super setReachabilityStatus:status];
	
	switch (self.reachabilityStatus) {
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
            [self requestStatusUpdate];
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
