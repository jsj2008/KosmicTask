//
//  MGSInternetSharing.m
//  Mother
//
//  Created by Jonathan on 05/09/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSInternetSharing.h"
#import "MGSImageManager.h"
#import "MGSPortMapper.h"
#import "MGSDistributedNotifications.h"
#import "MGSPreferences.h"
#import "MGSMotherServer.h"

// class extension
@interface MGSInternetSharing()
@property () NSImage *allowInternetAccessStatusImage;
@property () NSImage *allowLocalAccessStatusImage;
@end

@interface MGSInternetSharing(Private)
@end


NSString *MGSInternetSharingKeyRequest = @"MGSInternetSharingRequest";
NSString *MGSInternetSharingKeyMappingStatus = @"MGSInternetSharingMappingStatus";
NSString *MGSInternetSharingKeyIPAddress = @"MGSInternetSharingKeyIPAddress";
NSString *MGSInternetSharingKeyGatewayName = @"MGSInternetSharingKeyGatewayName";

@implementation MGSInternetSharing

@synthesize statusImage = _statusImage;
@synthesize externalPort = _externalPort;
@synthesize listeningPort = _listeningPort;
@synthesize allowInternetAccess = _allowInternetAccess;
@synthesize allowLocalAccess = _allowLocalAccess;
@synthesize enableInternetAccessAtLogin = _enableInternetAccessAtLogin;
@synthesize noteObjectString = _noteObjectString;
@synthesize mappingStatus = _mappingStatus;
@synthesize statusString = _statusString;
@synthesize IPAddressString = _IPAddressString;
@synthesize gatewayName = _gatewayName;
@synthesize responseReceived = _responseReceived;
@synthesize isActive = _isActive;
@synthesize activeStatusImage = _activeStatusImage;
@synthesize inactiveStatusImage = _inactiveStatusImage;
@synthesize activeStatusLargeImage = _activeStatusLargeImage;
@synthesize inactiveStatusLargeImage = _inactiveStatusLargeImage;
@synthesize allowInternetAccessStatusImage = _allowInternetAccessStatusImage;
@synthesize allowLocalAccessStatusImage = _allowLocalAccessStatusImage;
@synthesize allowLocalUsersToAuthenticate = _allowLocalUsersToAuthenticate;
@synthesize allowRemoteUsersToAuthenticate = _allowRemoteUsersToAuthenticate;

/*
 
 init
 
 */
- (id)init
{
	if ((self = [super init])) {
		
		_listeningPort = MOTHER_IANA_REGISTERED_PORT;
		_externalPort = MOTHER_IANA_REGISTERED_PORT;
		_allowInternetAccess = NO;
        _allowLocalAccess = YES;
        _allowLocalUsersToAuthenticate = YES;
        _allowRemoteUsersToAuthenticate = NO;
		_enableInternetAccessAtLogin = NO;
		_IPAddressString = NSLocalizedString(@"not available", @"Internet sharing IP address not available");
		_gatewayName = NSLocalizedString(@"not available", @"Internet sharing gateway name not available");
		_mappingStatus = kMGSInternetSharingPortNotMapped;
		_noteObjectString = [[MGSPortMapper class] className];
		_responseReceived = YES;
		_activeStatusImage = [[[MGSImageManager sharedManager] greenDot] copy];
		_inactiveStatusImage = [[[MGSImageManager sharedManager] redDot] copy];
		_activeStatusLargeImage = [[[MGSImageManager sharedManager] greenDotLarge] copy];
		_inactiveStatusLargeImage = [[[MGSImageManager sharedManager] redDotLarge] copy];
	}
	
	return self;
}

/*
 
 dispose
 
 */
- (void)dispose
{
}

/*
 
 post distributed request notification with dictionary
 
 */
- (void)postDistributedRequestNotificationWithDict:(NSDictionary *)dict waitOnResponse:(BOOL)wait
{
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

/*
 
 post distributed response notification with dictionary
 
 */
- (void)postDistributedResponseNotificationWithDict:(NSDictionary *)dict
{
	// send out a distributed notification
	[[NSDistributedNotificationCenter defaultCenter] 
	 postNotificationName: MGSDistNoteInternetSharingResponse
	 object:self.noteObjectString 
	 userInfo:dict
	 deliverImmediately:YES];
}


/*
 
 set mapping status _
 
 */
- (void)setMappingStatus:(MGSInternetSharingMappingStatus)mappingStatus
{
	
	// mapping status
	_mappingStatus = mappingStatus;
	
	[self willChangeValueForKey:@"statusString"];
	[self willChangeValueForKey:@"statusImage"];
	[self willChangeValueForKey:@"isActive"];
	
	switch (_mappingStatus) {
		case kMGSInternetSharingPortTryingToMap:
			_statusImage = [[[MGSImageManager sharedManager] yellowDot] copy];
			_statusString = NSLocalizedString(@"Remapping external port ...", @"Trying to map router port");
			_isActive = NO;
			break;
			
		case kMGSInternetSharingPortMapped:
			_statusImage = self.activeStatusImage;
			_statusString = NSLocalizedString(@"External port mapped", @"Router port mapped");
			_isActive = YES;
			break;
			
		case kMGSInternetSharingPortNotMapped:
		default:
			_statusImage = self.inactiveStatusImage;
			_statusString = NSLocalizedString(@"External port not mapped", @"Router port not mapped");
			_isActive = NO;
			break;
			
	}
	[self didChangeValueForKey:@"statusString"];
	[self didChangeValueForKey:@"statusImage"];
	[self didChangeValueForKey:@"isActive"];
}

/*
 
 - setAllowInternetAccess:
 
 */
-(void)setAllowInternetAccess:(BOOL)value {
    _allowInternetAccess = value;
    if (_allowInternetAccess) {
        self.allowInternetAccessStatusImage = _activeStatusImage;
    } else {
        self.allowInternetAccessStatusImage = _inactiveStatusImage;
    }
}

/*
 
 - setAllowLocalAccess:
 
 */
-(void)setAllowLocalAccess:(BOOL)value {
    _allowLocalAccess = value;
    if (_allowLocalAccess) {
        self.allowLocalAccessStatusImage = _activeStatusImage;
    } else {
        self.allowLocalAccessStatusImage = _inactiveStatusImage;
    }
}

/*
 
 - setAllowRemoteUsersToAuthenticate:
 
 */
- (void)setAllowRemoteUsersToAuthenticate:(BOOL)value
{
    _allowRemoteUsersToAuthenticate = value;
}

/*
 
 - setAllowLocalUsersToAuthenticate:
 
 */
- (void)setAllowLocalUsersToAuthenticate:(BOOL)value
{
    _allowLocalUsersToAuthenticate = value;
}
/*
 
 validate external port
 
 this is part  of the KVC machinery.
 it can be invoked automatically by bindings if the
 NSValidatesImmediatelyBindingOption bindings option is present
 
 */
- (BOOL)validateExternalPort:(id *)ioValue error:(NSError **)outError
{
	#pragma unused(outError)
	
	id object = *ioValue;
	NSInteger port = [*ioValue integerValue];
	if (!object || port < MGS_MIN_INTERNET_SHARING_PORT || port > MGS_MAX_INTERNET_SHARING_PORT) {
		port = MOTHER_IANA_REGISTERED_PORT;
		*ioValue = [NSNumber numberWithInteger:port];
	}
	
	return YES;
}
@end

@implementation MGSInternetSharing(Private)

@end
