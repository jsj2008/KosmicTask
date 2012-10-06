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

NSString *MGSInternetSharingKeyRequest;
NSString *MGSInternetSharingKeyMappingStatus;
NSString *MGSInternetSharingKeyIPAddress;
NSString *MGSInternetSharingKeyGatewayName;

typedef enum _MGSInternetSharingRequestID {
	kMGSInternetSharingRequestStatus = 0,
	kMGSInternetSharingRequestInternetAccess = 1,
	kMGSInternetSharingRequestStartMapping = 2,
	kMGSInternetSharingRequestStopMapping = 3,
	kMGSInternetSharingRequestStartAtLogin = 4,
	kMGSInternetSharingRequestRemapPort = 5,
    kMGSInternetSharingRequestLocalAccess = 6,
    kMGSInternetSharingRequestAllowLocalAuthentication = 7,
    kMGSInternetSharingRequestAllowRemoteAuthentication = 8,
} MGSInternetSharingRequestID;

typedef enum _MGSInternetSharingMappingStatus {
	kMGSInternetSharingPortNotMapped = 0,
	kMGSInternetSharingPortTryingToMap = 1,
	kMGSInternetSharingPortMapped = 2,
} MGSInternetSharingMappingStatus;

@interface MGSInternetSharing : NSObject {
@private
	NSImage *_statusImage;
    NSImage *_allowInternetAccessStatusImage;
    NSImage *_allowLocalAccessStatusImage;
	NSInteger _externalPort;
	NSInteger _listeningPort;
	BOOL _allowInternetAccess;
    BOOL _allowLocalAccess;
	BOOL _enableInternetAccessAtLogin;
    BOOL _allowLocalUsersToAuthenticate;
    BOOL _allowRemoteUsersToAuthenticate;
	NSString *_noteObjectString;
	MGSInternetSharingMappingStatus _mappingStatus;
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
}

@property (readonly) NSImage *statusImage;
@property (readonly) NSImage *allowInternetAccessStatusImage;
@property (readonly) NSImage *allowLocalAccessStatusImage;
@property NSInteger externalPort;
@property NSInteger listeningPort;
@property BOOL allowInternetAccess;
@property BOOL allowLocalAccess;
@property BOOL enableInternetAccessAtLogin;
@property BOOL allowLocalUsersToAuthenticate;
@property BOOL allowRemoteUsersToAuthenticate;
@property (readonly) NSString *noteObjectString;
@property MGSInternetSharingMappingStatus mappingStatus;
@property (readonly) NSString *statusString;
@property (copy) NSString *IPAddressString;
@property (copy) NSString *gatewayName;
@property BOOL responseReceived;
@property (readonly) BOOL isActive;
@property (copy) NSImage *activeStatusImage;
@property (copy) NSImage *activeUserStatusImage;
@property (copy) NSImage *inactiveStatusImage;
@property (copy) NSImage *activeStatusLargeImage;
@property (copy) NSImage *inactiveStatusLargeImage;

- (void)dispose;
- (void)postDistributedRequestNotificationWithDict:(NSDictionary *)dict waitOnResponse:(BOOL)wait;
- (void)postDistributedResponseNotificationWithDict:(NSDictionary *)dict;
@end
