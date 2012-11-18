//
//  MGSNetClient.h
//  Mother
//
//  Created by Jonathan on 28/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSNetClientSocket.h"
#import "MGSClientNetRequest.h"
#import "MGSMotherModes.h"

@class MGSScript;
@class MGSNetClient;
@class MGSNetClientContext;

// default keys
extern NSString *MGSDefaultBadHeartbeatLimit;

// dictionary keys
extern NSString *MGSNetClientKeyAddress;
extern NSString *MGSNetClientKeyDisplayName;
extern NSString *MGSNetClientKeyKeepConnected;
extern NSString *MGSNetClientKeyPortNumber;
extern NSString *MGSNetClientKeySecureConnection;
extern NSString *MGSNetClientKeyNote;

// key paths
extern NSString *MGSNetClientKeyPathHostStatus;
extern NSString *MGSNetClientKeyPathRunMode;
extern NSString *MGSNetClientKeyPathScriptAccess;

@protocol MGSNetClientDelegate

@optional
- (void)netClientNotResponding:(MGSNetClient *)netClient;		// sent after client stops responding
- (void)netClientResponding:(MGSNetClient *)netClient;			// sent after client starts responding
- (void)netClientScriptDataUpdated:(MGSNetClient *)netClient;	// client script data has been edited
- (void)netClientTXTRecordUpdated:(MGSNetClient *)netClient;	// client TXT record has been updated
- (void)netClientAuthenticationStatusChanged:(MGSNetClient *)netClient;	// client authentication status changed
- (void)netClientScriptDictUpdated:(MGSNetClient *)netClient;	// client script dict has changed
@end

typedef enum _MGSHostType {
	MGSHostTypeUnknown = 0, // not connected
	MGSHostTypeLocal, // localhost
	MGSHostTypeRemote,		// remote host
} MGSHostType;

typedef enum _MGSHostStatus {
	MGSHostStatusNotYetAvailable = 0,	// host not yet available
	MGSHostStatusAvailable ,			// host service available 
	MGSHostStatusNotResponding,			// host was available but not currently responding
	MGSHostStatusDisconnected,			// host has disconnected and client set to be deleted
} MGSHostStatus;

typedef enum _MGSClientStatus {
	MGSClientStatusNotAvailable = 0,		// client has not yet received script dict
	MGSClientStatusAvailable = 1,			// client available, script dict has been retrieved
} MGSClientStatus;

typedef enum _MGSScriptAccess {
	MGSScriptAccessInit = 0x0,
	MGSScriptAccessNone = 0x1,
	MGSScriptAccessPublic = 0x2,	// scripts have public access
	MGSScriptAccessTrusted = 0x4,		// scripts have authenticated user access
} MGSScriptAccess;

@class MGSNetRequest;
@class MGSClientTaskController;

@interface MGSNetClient : NSObject 
	<MGSNetSocketDelegate, MGSNetRequestOwner, NSNetServiceDelegate> {
	NSNetService *_netService;						// host service - valid for Bonjour discovered clients only
	BOOL _visible;
	NSMutableArray *_pendingRequests;						// requests waiting to be sent
	NSMutableArray *_executingRequests;				// running request threads
	NSMapTable *_contexts;							// client contexts
	NSDictionary *_authenticationDictionary;			// dict of last successful authentication details
	MGSClientTaskController *_taskController;			// task controller
	BOOL _sendExecuteValidation;
		
	// client
	MGSClientStatus _clientStatus;		// client status
	
	// host
	NSString *_hostName;				// host name
	UInt16 _hostPort;					// host server port
	NSString *_serviceName;				// Bonjour service name - full host name
	NSString *_serviceShortName;		// Bonjour service name - host name minus .local domain
	MGSHostType _hostType;				// host type is local or remote
	NSImage *_hostImage;				// image representing host type and status
	NSImage *_hostIcon;					// 16x16 image representing host type and status
	MGSHostStatus _hostStatus;			// host status
	NSInteger _badHeartbeatCount;		// consecutive number of times that host has not responded to heartbeat
	NSString *_hostUserName;			// name of host user
	BOOL _hostViaBonjour;				// host found via bonjour
    BOOL _isResolving;					// YES if resolving address
	BOOL _useSSL;						// YES if SSL encryption is active
	BOOL _securePublicTasks;			// YES if public tasks are to be secured
	BOOL _keepConnected;				// YES if keep client connected between restarts - applies to manually added clients only
	BOOL _TXTRecordReceived;			// YES if at least one valid TXT record has been received
	NSUInteger _initialRequestRetryCount;	// initial request retry count
	BOOL _validatedConnection;			// connection has a valid licence
	NSTimeInterval _bonjourResolveTimeout;
	id _delegate;
		
	NSOperationQueue *_operationQueue;
}
- (id)initWithNetService:(NSNetService *)aNetService;
- (id)initWithDictionary:(NSDictionary *)dict;

- (BOOL)canConnect;
- (void)connectAndSendRequest:(MGSClientNetRequest *)netRequest;
- (BOOL)hasService:(NSNetService *)netService;
- (void)sendHeartbeat;
- (void)sendHeartbeatNow;
- (void)serviceRemoved;
- (BOOL)isLocalHost;
- (BOOL)isConnected;
- (NSString *)hostName;
- (UInt16) hostPort;

- (BOOL)canEditScript:(MGSScript *)script;

- (NSImage *)securityIcon;
- (NSImage *)authenticationIcon;
- (NSDictionary *)dictionary;
- (void)TXTRecordUpdate;
- (BOOL)isAuthenticated;
- (int)hostSortIndex;
- (void)requestSearch:(NSDictionary *)searchDict withOwner:(id <MGSNetRequestOwner>)owner;
- (bool)canSearch;
- (NSDictionary *)authenticationDictionaryForRunMode;

// context handling
- (void)setRunMode:(eMGSMotherRunMode)mode forWindow:(NSWindow *)window;
- (BOOL)addContextForWindow:(NSWindow *)window;
- (void)removeContextForWindow:(NSWindow *)window;
- (MGSNetClientContext *)contextForWindow:(NSWindow *)window;
- (MGSNetClientContext *)applicationWindowContext;
- (void)errorOnRequestQueue:(MGSClientNetRequest *)netRequest code:(NSInteger)code reason:(NSString *)failureReason;
- (void)applySecurity;

@property (copy) NSString *serviceShortName;
@property (copy) NSString *serviceName;
@property (assign) NSImage *hostIcon;
@property MGSHostStatus hostStatus;

@property (readonly) NSNetService *netService;
@property BOOL visible;
@property BOOL sendExecuteValidation;
@property MGSHostType hostType;
@property (assign) NSImage *hostImage;
@property (assign) NSString *hostUserName;
@property id delegate;
@property BOOL useSSL;
@property (copy) NSDictionary *authenticationDictionary;
@property BOOL hostViaBonjour;
@property BOOL keepConnected;
@property MGSClientStatus clientStatus;
@property (readonly) MGSClientTaskController *taskController;
@property BOOL TXTRecordReceived;
@property NSUInteger initialRequestRetryCount;
@property BOOL validatedConnection;
@property BOOL securePublicTasks;
@end



