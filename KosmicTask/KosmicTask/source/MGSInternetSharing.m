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
/*
 
 init
 
 */
- (id)init
{
	if ((self = [super init])) {
		
		self.listeningPort = MOTHER_IANA_REGISTERED_PORT;
		self.externalPort = MOTHER_IANA_REGISTERED_PORT;
		self.allowInternetAccess = NO;
		self.enableInternetAccessAtLogin = NO;
		self.IPAddressString = NSLocalizedString(@"not available", @"Internet sharing IP address not available");
		self.gatewayName = NSLocalizedString(@"not available", @"Internet sharing gateway name not available");
		self.mappingStatus = kMGSInternetSharingPortNotMapped;
		_noteObjectString = [[MGSPortMapper class] className];
		self.responseReceived = NO;
		self.activeStatusImage = [[[MGSImageManager sharedManager] greenDot] copy];
		self.inactiveStatusImage = [[[MGSImageManager sharedManager] redDot] copy];
		self.activeStatusLargeImage = [[[MGSImageManager sharedManager] greenDotLarge] copy];
		self.inactiveStatusLargeImage = [[[MGSImageManager sharedManager] redDotLarge] copy];
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
- (void)postDistributedRequestNotificationWithDict:(NSDictionary *)dict
{
	self.responseReceived = NO;
	
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
