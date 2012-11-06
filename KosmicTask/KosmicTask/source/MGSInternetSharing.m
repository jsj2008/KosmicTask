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
@property NSImage *statusImage;
@property () NSImage *allowInternetAccessStatusImage;
@property () NSImage *allowLocalAccessStatusImage;
- (void)updateRemoteAccessStatusImage;
- (void)updateLocalAccessStatusImage;
- (void)updatePortStatusImage;
@end

@interface MGSInternetSharing(Private)
@end


NSString *MGSInternetSharingKeyRequest = @"MGSInternetSharingRequest";
NSString *MGSInternetSharingKeyMappingStatus = @"MGSInternetSharingMappingStatus";
NSString *MGSInternetSharingKeyIPAddress = @"MGSInternetSharingKeyIPAddress";
NSString *MGSInternetSharingKeyGatewayName = @"MGSInternetSharingKeyGatewayName";
NSString *MGSInternetSharingKeyReachabilityStatus = @"MGSInternetSharingKeyReachabilityStatus";
NSString *MGSInternetSharingKeyResponseRequired = @"MGSInternetSharingKeyResponseRequired";

@implementation MGSInternetSharing

@synthesize statusImage = _statusImage;
@synthesize externalPort = _externalPort;
@synthesize listeningPort = _listeningPort;
@synthesize allowInternetAccess = _allowInternetAccess;
@synthesize allowLocalAccess = _allowLocalAccess;
@synthesize automaticallyMapPort = _automaticallyMapPort;
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
@synthesize activeUserStatusImage = _activeUserStatusImage;
@synthesize activePortStatusImage = _activePortStatusImage;
@synthesize inactivePortStatusImage = _inactivePortStatusImage;
@synthesize reachabilityStatus = _reachabilityStatus;

#pragma mark -
#pragma mark Instance
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
		_automaticallyMapPort = NO;
		_IPAddressString = [self notAvailableString];
		_gatewayName = [self notAvailableString];
		_mappingStatus = kMGSInternetSharingPortNotMapped;
		_noteObjectString = [[MGSPortMapper class] className];
		_responseReceived = YES;
		_activeUserStatusImage = [[[MGSImageManager sharedManager] greenDotUser] copy];
		_activeStatusImage = [[[MGSImageManager sharedManager] greenDotNoUser] copy];
		_inactiveStatusImage = [[[MGSImageManager sharedManager] redDotNoUser] copy];
		_activeStatusLargeImage = [[[MGSImageManager sharedManager] greenDotLarge] copy];
		_inactiveStatusLargeImage = [[[MGSImageManager sharedManager] redDotLarge] copy];
		_activePortStatusImage = [[[MGSImageManager sharedManager] greenTick16] copy];
		_inactivePortStatusImage = [[[MGSImageManager sharedManager] redCross16] copy];
        
		// read preferences
		MGSPreferences *preferences = [MGSPreferences standardUserDefaults];
		
		if ([preferences objectForKey:MGSExternalPortNumber]) {
			self.externalPort = [preferences integerForKey:MGSExternalPortNumber];
		}
		
		self.allowInternetAccess = [preferences boolForKey:MGSAllowInternetAccess];
        self.allowLocalAccess = [preferences boolForKey:MGSAllowLocalAccess];
		self.automaticallyMapPort = [preferences boolForKey:MGSEnableInternetAccessAtLogin];
		self.allowLocalUsersToAuthenticate = [preferences boolForKey:MGSAllowLocalUsersToAuthenticate];
		self.allowRemoteUsersToAuthenticate = [preferences boolForKey:MGSAllowRemoteUsersToAuthenticate];
        
	}
	
	return self;
}

/*
 
 dispose
 
 */
- (void)dispose
{
}

#pragma mark -
#pragma mark Notification processing
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

#pragma mark -
#pragma mark Accessors

/*
 
 set mapping status _
 
 */
- (void)setMappingStatus:(MGSInternetSharingMappingStatus)status
{
	
	// mapping status
	_mappingStatus = status;
	
	[self willChangeValueForKey:@"statusString"];
	[self willChangeValueForKey:@"isActive"];
	
    _isActive = NO;
    
	switch (_mappingStatus) {
            
        case kMGSInternetSharingPortStatusNA:
			_statusString = NSLocalizedString(@"Port status unknown", @"Port status unknown");
            break;
            
		case kMGSInternetSharingPortTryingToMap:
			_statusString = NSLocalizedString(@"Mapping external port", @"Trying to map router port");
			break;
        
        case kMGSInternetSharingPortMapped:
			_statusString = NSLocalizedString(@"External port mapped", @"Trying to map router port");
            
#define MGS_INTERNET_SHARING_MARK_ACTIVE
#ifdef MGS_INTERNET_SHARING_MARK_ACTIVE
            _isActive = YES;
#endif
            break;
            
		case kMGSInternetSharingPortNotMapped:
		default:
			_statusString = NSLocalizedString(@"External port not mapped", @"Router port not mapped");
			break;
			
	}
	[self didChangeValueForKey:@"statusString"];
	[self didChangeValueForKey:@"isActive"];
}

/*
 
 - setReachabilityStatus:
 
 */
- (void)setReachabilityStatus:(MGSPortReachability)status
{
	
	// reachability status
	_reachabilityStatus = status;

    [self updatePortStatusImage];
}

/*
 
 - setAllowInternetAccess:
 
 */
-(void)setAllowInternetAccess:(BOOL)value {
    _allowInternetAccess = value;
    if (!_allowInternetAccess && self.allowRemoteUsersToAuthenticate) {
        self.allowRemoteUsersToAuthenticate = NO;
    }
    [self updateRemoteAccessStatusImage];
}

/*
 
 - setAllowLocalAccess:
 
 */
-(void)setAllowLocalAccess:(BOOL)value {
    _allowLocalAccess = value;
    if (!_allowLocalAccess && self.allowLocalUsersToAuthenticate) {
        self.allowLocalUsersToAuthenticate = NO;
    }

    [self updateLocalAccessStatusImage];
}

/*
 
 - setAllowRemoteUsersToAuthenticate:
 
 */
- (void)setAllowRemoteUsersToAuthenticate:(BOOL)value
{
    _allowRemoteUsersToAuthenticate = value;
    [self updateRemoteAccessStatusImage];

}

/*
 
 - setAllowLocalUsersToAuthenticate:
 
 */
- (void)setAllowLocalUsersToAuthenticate:(BOOL)value
{
    _allowLocalUsersToAuthenticate = value;
    [self updateLocalAccessStatusImage];
}

/*
 
 - notAvailableString
 
 */
- (NSString *)notAvailableString
{
    return NSLocalizedString(@"not available", @"Internet sharing property not available");
}
#pragma mark -
#pragma mark Status image updating
/*
 
 - updateRemoteAccessStatusImage
 
 */
- (void)updateRemoteAccessStatusImage
{
    if (_allowInternetAccess) {
        if (_allowRemoteUsersToAuthenticate) {
            self.allowInternetAccessStatusImage = _activeUserStatusImage;
        } else {
            self.allowInternetAccessStatusImage = _activeStatusImage;
        }
    } else {
        self.allowInternetAccessStatusImage = _inactiveStatusImage;
    }
    
}
/*
 
 - updateLocalAccessStatusImage
 
 */
- (void)updateLocalAccessStatusImage
{
    if (_allowLocalAccess) {
        if (_allowLocalUsersToAuthenticate) {
            self.allowLocalAccessStatusImage = _activeUserStatusImage;
        } else {
            self.allowLocalAccessStatusImage = _activeStatusImage;
        }
    } else {
        self.allowLocalAccessStatusImage = _inactiveStatusImage;
    }
    
}
/*
 
 - updatePortStatusImage
 
 */
- (void)updatePortStatusImage
{
    if (self.reachabilityStatus == kMGSPortReachable) {
        self.statusImage = self.activePortStatusImage;
    } else {
        self.statusImage = self.inactivePortStatusImage;
    }
}

#pragma mark -
#pragma mark Validation

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
