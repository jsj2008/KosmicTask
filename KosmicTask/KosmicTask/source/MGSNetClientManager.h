//
//  MGSNetClientManager.h
//  Mother
//
//  Created by Jonathan on 04/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSClientNetRequest.h"
#import "MGSNetClient.h"

extern NSString *MGSDefaultHeartBeatInterval;
extern NSString *MGSDefaultStartDelay;
extern NSString *MGSDefaultPersistentConnections;

@class MGSNetClient;
@class MGSNetClientManager;


// formal delegate protocol
// note that a class does not even have to adopt a protocol
// in order to satisfy the compiler.
// merely defining that such optional methods MAY exist is enough.
// so no need for categories on NSObject
@protocol MGSNetClientManagerDelegate

@optional
- (void)addStaticClient:(MGSNetClient *)netClient;
-(void)netClientHandlerClientFound:(MGSNetClient *)sender;
-(void)netClientHandlerClientRemoved:(MGSNetClient *)sender;
-(void)netClientHandlerClientListChanged:(MGSNetClientManager *)sender;
@required
@end

@interface MGSNetClientManager : NSObject <NSNetServiceBrowserDelegate, MGSNetClientDelegate> {
	NSMutableArray *_netClients;
	NSMutableArray *_deferredNetClients;
	NSNetServiceBrowser *_serviceBrowser;
	NSString * _serviceType;
	NSString * _domain;
	id __weak _delegate;
	NSTimer *_heartbeatTimer;	// timer to generate heartbeats
	MGSNetClient *_saveNetClient;
	BOOL _terminateAfterReviewChanges;
	BOOL _deferRemoteClientConnections;	// defer remote client connections until localhost connected
	MGSNetClient * _selectedNetClient;
}
+ (id)sharedController;

- (BOOL)searchForServices;
- (NSInteger)clientsHiddenCount;
- (NSInteger)clientsCount;
- (NSInteger)clientsVisibleCount;
- (MGSNetClient *)clientAtIndex:(NSUInteger)index;
- (void)informDelegateClientListChanged;
- (NSUInteger)indexOfClient:(MGSNetClient *)client;
- (void)sortUsingDescriptors:(NSArray *)descriptors;
- (MGSNetClient *)localClient;
//- (MGSNetClient *)addClientFromDictionary:(NSDictionary *)dict;
- (void)removeStaticClient:(MGSNetClient *)netClient;
- (void)addStaticClient:(MGSNetClient *)netClient;
- (void)restorePersistentClients;
- (NSMutableArray *)hostViaUserDictionaries;
- (MGSNetClient *)clientForServiceName:(NSString *)serviceName;
- (MGSNetClient *)clientForServiceName:(NSString *)serviceName port:(NSInteger)port;
- (NSInteger)requestSearchAll:(NSDictionary *)searchDict withOwner:(id <MGSNetRequestOwner>)owner;
- (NSInteger)requestSearchLocal:(NSDictionary *)searchDict withOwner:(id <MGSNetRequestOwner>)owner;
- (NSInteger)requestSearchShared:(NSDictionary *)searchDict withOwner:(id <MGSNetRequestOwner>)owner;
- (BOOL)requestSearch:(NSDictionary *)searchDict clientServiceName:(NSString *)serviceName withOwner:(id <MGSNetRequestOwner>)owner;
- (void)reviewSaveConfigurationAndQuitEnumeration:(NSNumber *)contNumber ;
- (NSApplicationTerminateReply)saveClientConfiguration:(MGSNetClient *)netClient doCallBack:(BOOL)doCallBack;
- (NSApplicationTerminateReply)checkForUnsavedConfigurationOnClient:(MGSNetClient *)netClient terminating:(BOOL)terminating;
- (void)validateClients;

@property (readonly) NSString *serviceType;
@property (readonly) NSString *domain;
@property (weak, nonatomic) id <MGSNetClientManagerDelegate, NSObject> delegate;
@property (nonatomic) BOOL deferRemoteClientConnections;
@property (readonly) MGSNetClient *selectedNetClient;
@end

@interface MGSNetClientManager (NetServiceDelegate)
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict;
- (void)netServiceDidResolveAddress:(NSNetService *)sender;
@end


@interface MGSNetClientManager (NetServiceBrowserDelegate)
- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)netServiceBrowser;
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser 
		   didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing;
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didNotSearch:(NSDictionary *)errorInfo;
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)netServiceBrowser;
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser 
		 didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing;
- (void)undeferRemoteClientConnections;
@end


//
// define informal protocol for our delegate
// NOTE: this category shows up in IB connection
// pallete, probably because it looks like and action.
// redefined as an optional protocol
/*@interface NSObject (MGSNetClientHandlerDelegate)

-(void)netClientHandlerDidResolve:(MGSNetClient *)sender;
-(void)netClientHandlerDidNotResolve:(MGSNetClient *)sender;
-(void)netClientHandlerServiceFound:(MGSNetClient *)sender;
-(void)netClientHandlerServiceRemoved:(MGSNetClientHandler *)sender;
-(void)netClientHandlerClientDataUpdated:(MGSNetClientHandler *)sender;
@end */
