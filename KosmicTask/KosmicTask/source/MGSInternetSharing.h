//
//  MGSInternetSharing.h
//  Mother
//
//  Created by Jonathan on 05/09/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define MGS_MIN_INTERNET_SHARING_PORT 1024
#define MGS_MAX_INTERNET_SHARING_PORT 49151

extern NSString *MGSInternetSharingKeyRequest;
extern NSString *MGSInternetSharingKeyMappingStatus;
extern NSString *MGSInternetSharingKeyReachabilityStatus;
extern NSString *MGSInternetSharingKeyIPAddress;
extern NSString *MGSInternetSharingKeyGatewayName;
extern NSString *MGSInternetSharingKeyResponseRequired;
extern NSString *MGSInternetSharingKeyRouterStatus;

enum _MGSInternetSharingRequestID {
	kMGSInternetSharingRequestStatus = 0,
	kMGSInternetSharingRequestInternetAccess = 1,
	kMGSInternetSharingRequestMapPort = 4,
    kMGSInternetSharingRequestLocalAccess = 6,
    kMGSInternetSharingRequestAllowLocalAuthentication = 7,
    kMGSInternetSharingRequestAllowRemoteAuthentication = 8,
    kMGSInternetSharingRequestRefreshMapping = 9,
};
typedef NSInteger MGSInternetSharingRequestID;

enum _MGSInternetSharingMappingStatus {
    kMGSInternetSharingPortStatusNA = 0,    // port status NA
	kMGSInternetSharingPortTryingToMap = 1, // trying to map
	kMGSInternetSharingPortNotMapped = 2,   // port could not be mapped
	kMGSInternetSharingPortMapped = 3,      // port mapped (automatic)
};
typedef NSInteger MGSInternetSharingMappingStatus;

enum _MGSInternetSharingRouterStatus {
    kMGSInternetSharingRouterUnknown = 0,
    kMGSInternetSharingRouterHasExternalIP = 1,
    kMGSInternetSharingRouterIncompatible = 2,
    kMGSInternetSharingRouterNotFound = 3
};
typedef NSInteger MGSInternetSharingRouterStatus;

enum {
    kMGSPortReachabilityNA = 0,
    kMGSPortReachable = 1,
    kMGSPortNotReachable = 2,
};
typedef NSInteger MGSPortReachability;

@interface MGSInternetSharing : NSObject {
@private
	NSImage *_statusImage;
    NSImage *_allowInternetAccessStatusImage;
    NSImage *_allowLocalAccessStatusImage;
	NSInteger _externalPort;
	NSInteger _listeningPort;
	BOOL _allowInternetAccess;
    BOOL _allowLocalAccess;
	BOOL _automaticallyMapPort;
    BOOL _allowLocalUsersToAuthenticate;
    BOOL _allowRemoteUsersToAuthenticate;
	NSString *_noteObjectString;
	MGSInternetSharingMappingStatus _mappingStatus;
    MGSInternetSharingRouterStatus _routerStatus;
	NSString *_statusString;
	NSString *_IPAddressString;
	NSString *_gatewayName;
	BOOL _responseReceived;
	BOOL _isActive;
    NSImage *_activeUserStatusImage;
	NSImage *_activeStatusImage;
	NSImage *_inactiveStatusImage;
	NSImage *_activeStatusLargeImage;
	NSImage *_inactiveStatusLargeImage;
    NSImage *_activePortStatusImage;
	NSImage *_inactivePortStatusImage;
    MGSPortReachability _portReachabilityStatus;
}

@property (readonly) NSImage *statusImage;
@property (readonly) NSImage *allowInternetAccessStatusImage;
@property (readonly) NSImage *allowLocalAccessStatusImage;
@property NSInteger externalPort;
@property NSInteger listeningPort;
@property BOOL allowInternetAccess;
@property BOOL allowLocalAccess;
@property BOOL automaticallyMapPort;
@property BOOL allowLocalUsersToAuthenticate;
@property BOOL allowRemoteUsersToAuthenticate;
@property (readonly) NSString *noteObjectString;
@property MGSInternetSharingMappingStatus mappingStatus;
@property MGSInternetSharingRouterStatus routerStatus;
@property MGSPortReachability portReachabilityStatus;
@property (readonly) NSString *statusString;
@property (copy) NSString *IPAddressString;
@property (copy) NSString *gatewayName;
@property BOOL responseReceived;
@property (readonly) BOOL isActive;
@property (copy) NSImage *activeUserStatusImage;
@property (copy) NSImage *activeStatusImage;
@property (copy) NSImage *inactiveStatusImage;
@property (copy) NSImage *activePortStatusImage;
@property (copy) NSImage *inactivePortStatusImage;
@property (copy) NSImage *activeStatusLargeImage;
@property (copy) NSImage *inactiveStatusLargeImage;

- (void)dispose;
- (void)postDistributedRequestNotificationWithDict:(NSDictionary *)dict waitOnResponse:(BOOL)wait;
- (void)postDistributedResponseNotificationWithDict:(NSDictionary *)dict;
- (NSString *)notAvailableString;
@end
