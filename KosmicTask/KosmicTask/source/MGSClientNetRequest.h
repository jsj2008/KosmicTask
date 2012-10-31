//
//  MGSClientNetRequest.h
//  KosmicTask
//
//  Created by Jonathan on 08/10/2012.
//
//

#import <Cocoa/Cocoa.h>
#import "MGSNetRequest.h"

@class MGSNetClient;
@class MGSClientNetRequest;

// net request owner protocol
// this protocol does not often feature the request itself
// as the owner is unaware of MGSNetRequest and makes its
// request solely via MGSNetClient
@protocol MGSNetRequestOwner <NSObject>

@optional

// request status update
-(void)netRequestUpdate:(MGSClientNetRequest *)netRequest;

// request status update
- (void)netRequestChunkReceived:(MGSClientNetRequest *)netRequest;

// request will send
-(NSDictionary *)netRequestWillSend:(MGSClientNetRequest *)netRequest;

// request error
//-(void)netRequestError:(MGSNetRequest *)netRequest;

@required

// request response
-(void)netRequestResponse:(MGSClientNetRequest *)netRequest payload:(MGSNetRequestPayload *)payload;

@end


@interface MGSClientNetRequest : MGSNetRequest {
    MGSNetClient *_netClient;			// netclient defining service to use to connect to server
    MGSClientNetRequest *_prevRequest;		// previous request
	MGSClientNetRequest *_nextRequest;		// next request
    id _owner;							// the request's owner - they will receive status updates only
	id _ownerObject;					// owner object associated with request
	NSString *_ownerString;				// owner string associated with request
	BOOL _sendUpdatesToOwner;			// flag send updates to owner
    BOOL _allowUserToAuthenticate;		// allow user to authenticate the request  
}
@property (assign) id owner;
@property (assign) id ownerObject;
@property (copy)NSString *ownerString;
@property BOOL sendUpdatesToOwner;
@property (readonly) MGSNetClient *netClient;
@property BOOL allowUserToAuthenticate;
@property (assign) MGSClientNetRequest *prevRequest;			// previous request
@property (assign) MGSClientNetRequest *nextRequest;			// next request

+ (id)requestWithClient:(MGSNetClient *)netClient;
+ (id)requestWithClient:(MGSNetClient *)netClient command:(NSString *)command;
- (MGSClientNetRequest *)initWithNetClient:(MGSNetClient *)netClient;
+ (void)sendRequestError:(MGSClientNetRequest *)request to:(id)owner;
- (void)sendRequestOnClient;
- (void)sendRequestOnClientSocket;
- (void)tagError:(MGSError *)error;
- (MGSClientNetRequest *)enqueueNegotiateRequest;
- (void)sendErrorToOwner;
- (void)sendChildRequests;
- (MGSClientNetRequest *)firstRequest;
- (MGSClientNetRequest *)queuedNegotiateRequest;
- (MGSClientNetRequest *)nextQueuedRequestToSend;
- (id)nextOwnerInRequestQueue;
- (void)updateProgress:(MGSRequestProgress *)progress;
- (void)prepareToResend;
- (BOOL)validateOnCompletion:(MGSError **)mgsError;
- (BOOL)sent;
- (void)inheritConnection:(MGSNetRequest *)request;
- (BOOL)prepareConnectionNegotiation;
@end
