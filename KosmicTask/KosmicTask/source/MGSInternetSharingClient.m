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
@property NSString *portStatusText;
@end

@implementation MGSInternetSharingClient

static id _sharedInstance = nil;

@synthesize startStopButtonText = _startStopButtonText;
@synthesize portStatusText = _portStatusText;

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


/*
 
 request a status update
 
 */
- (void)requestStatusUpdate
{
	NSDictionary *requestDict = [NSDictionary dictionaryWithObjectsAndKeys: 
								 [NSNumber numberWithInteger:kMGSInternetSharingRequestStatus], MGSInternetSharingKeyRequest,
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
			self.enableInternetAccessAtLogin = [[userInfo objectForKey:MGSEnableInternetAccessAtLogin] boolValue];
			self.IPAddressString = [userInfo objectForKey:MGSInternetSharingKeyIPAddress];
			self.gatewayName = [userInfo objectForKey:MGSInternetSharingKeyGatewayName];
			self.allowLocalUsersToAuthenticate = [[userInfo objectForKey:MGSAllowLocalUsersToAuthenticate] boolValue];
			self.allowRemoteUsersToAuthenticate = [[userInfo objectForKey:MGSAllowRemoteUsersToAuthenticate] boolValue];
			break;
			
			// unrecognised
		default:
			MLog(RELEASELOG, @"unrecognised internet sharing request id: %i", requestID);
			break;
	}

	_processingResponse = NO;
	self.responseReceived = YES;
}

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
- (void)setEnableInternetAccessAtLogin:(BOOL)value
{
	[super setEnableInternetAccessAtLogin:value];
	
	// if not processing response
	if (!_processingResponse) {
		
		NSDictionary *requestDict = [NSDictionary dictionaryWithObjectsAndKeys: 
									 [NSNumber numberWithInteger:kMGSInternetSharingRequestStartAtLogin], MGSInternetSharingKeyRequest,
									 [NSNumber numberWithBool:value], MGSEnableInternetAccessAtLogin,
									 nil];
		
		[self postDistributedRequestNotificationWithDict:requestDict waitOnResponse:NO];
		
	}
}

/*
 
 set mapping status _
 
 */
- (void)setMappingStatus:(MGSInternetSharingMappingStatus)mappingStatus
{
	
	// mapping status
	[super setMappingStatus:mappingStatus];
	
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
	
	// update application icon to reflect Internet sharing status
	NSImage *appIconImage;
	if (self.isActive) {
		appIconImage = _appActiveSharingIconImage;
	} else {
		appIconImage = _appIconImage;
	}

	// set application icon
	// note that whatever is set here seems to get used when creating
	// miniwindows for other application windows.
	// so if the orb is displayed here then it will appear in the miniwindows too.
	// if the sharing is subsequently stopped then the miniwindow display may be out of sync.
	[NSApp setApplicationIconImage: appIconImage];
	// or update dock tile
	// this seems to cause an icon flash
	//NSDockTile *dockTile = [NSApp dockTile];
	//[dockTile setContentView:[[MGSImageManager sharedManager] imageView:appIconImage]];
	//[dockTile display];
}

/*
 
 toggle start stop
 
 */
- (IBAction)toggleStartStop:(id)sender
{
	#pragma unused(sender)
	
	MGSInternetSharingRequestID requestID;

	switch (self.mappingStatus) {
		case kMGSInternetSharingPortTryingToMap:
			return;
			break;
			
		case kMGSInternetSharingPortMapped:
			requestID = kMGSInternetSharingRequestStopMapping;
			break;
			
		case kMGSInternetSharingPortNotMapped:
		default:
			requestID = kMGSInternetSharingRequestStartMapping;
			break;
			
	}
		
	NSDictionary *requestDict = [NSDictionary dictionaryWithObjectsAndKeys: 
								 [NSNumber numberWithInteger:requestID], MGSInternetSharingKeyRequest,
								 [NSNumber numberWithInteger:self.externalPort], MGSExternalPortNumber,
								 nil];
	[self postDistributedRequestNotificationWithDict:requestDict waitOnResponse:YES];
	
}
@end
