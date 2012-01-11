//
//  MGSNetRequest.h
//  Mother
//
//  Created by Jonathan on 30/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MGSError;

#define MGS_STANDARD_TIMEOUT 60

typedef enum _eMGSRequestType {
    kMGSRequestTypeWorker = 0,
    kMGSRequestTypeLogging= 1
} eMGSRequestType;

// net request status
typedef enum _eMGSRequestStatus {
	kMGSStatusExceptionOnConnecting = -2,
	kMGSStatusCannotConnect = -1,
	
	kMGSStatusNotConnected = 0,
	
	kMGSStatusResolving = 1,
	kMGSStatusConnecting = 2,
	kMGSStatusConnected = 3,
	kMGSStatusDisconnected = 4,
	
	// message exchange status
	
	// sending message
	kMGSStatusSendingMessage = 51,
	kMGSStatusSendingMessageAttachments = 52,
	kMGSStatusMessageSent = 54,
	
	// receiving message
	kMGSStatusReadingMessageHeaderPrefix = 100,
	kMGSStatusReadingMessageHeader = 101,
	kMGSStatusReadingMessageBody = 102,
	kMGSStatusReadingMessageAttachments = 103,
	kMGSStatusMessageReceived = 104,
	
	
} eMGSRequestStatus;

@class MGSNetMessage;
@class MGSNetClient;
@class MGSNetSocket;
@class MGSNetRequest;
@class MGSNetRequestPayload;
@class MGSRequestProgress;

// net request owner protocol
// this protocol does not often feature the request itself
// as the owner is unaware of MGSNetRequest and makes its
// request solely via MGSNetClient
@protocol MGSNetRequestOwner <NSObject>

@optional 

// request status update
-(void)netRequestUpdate:(MGSNetRequest *)netRequest;

// request status update
-(void)netRequestChunkReceived:(NSString *)chunk;

// request will send
-(NSDictionary *)netRequestWillSend:(MGSNetRequest *)netRequest;

// request error
//-(void)netRequestError:(MGSNetRequest *)netRequest;

@required

// request response
-(void)netRequestResponse:(MGSNetRequest *)netRequest payload:(MGSNetRequestPayload *)payload;

@end

// net request delegate protocol
@protocol MGSNetRequestDelegate

@optional
- (void)netRequestReplyOnClient:(MGSNetRequest *)netRequest;
- (void)sendResponseOnSocket:(MGSNetRequest *)netRequest wasValid:(BOOL)valid;
- (void)authenticationFailed:(MGSNetRequest *)netRequest;
@end


@interface MGSNetRequest : NSObject {
    eMGSRequestType _requestType;
	MGSNetMessage *_requestMessage;		// request message sent from client to server
	MGSNetMessage *_responseMessage;	// response message from server to client
	MGSNetClient *_netClient;			// netclient defining service to use to connect to server
	MGSNetSocket *_netSocket;			// netsocket
	eMGSRequestStatus _status;			// request status
	id _delegate;						// delegate
	id _owner;							// the request's owner - they will receive status updates only
	MGSError *_error;					// request error
	NSTimeInterval _readTimeout;		// request read timeout
	NSTimeInterval _writeTimeout;		// request write timeout
	unsigned long int _requestID;		// request sequence counter
	id _ownerObject;					// owner object associated with request
	NSString *_ownerString;				// owner string associated with request
	BOOL _allowUserToAuthenticate;		// allow user to authenticate the request
	NSMutableArray *temporaryPaths;		// paths to be removed when the request is finalised
	BOOL disposed;
	BOOL _sendUpdatesToOwner;			// flag send updates to owner
	MGSNetRequest *_prevRequest;		// previous request
	MGSNetRequest *_nextRequest;		// next request
    NSMutableArray *_childRequests;     // child requests
    MGSNetRequest *_parentRequest;      // parent request
	NSUInteger _flags;
    NSMutableArray *_chunksReceived;    // chunks received
}

+ (id)requestWithClient:(MGSNetClient *)netClient;
+ (id)requestWithClient:(MGSNetClient *)netClient command:(NSString *)command;
+ (id)requestWithConnectedSocket:(MGSNetSocket *)socket;
+ (void)sendRequestError:(MGSNetRequest *)request to:(id)owner;
+ (NSThread *)networkThread;
- (MGSNetRequest *)nextQueuedRequestToSend;
- (id)nextOwnerInRequestQueue;
- (void)resetMessages;
- (MGSNetRequest *)firstRequest;

- (MGSNetRequest *)initWithNetClient:(MGSNetClient *)netClient;
- (MGSNetRequest *)initWithConnectedSocket:(MGSNetSocket *)socket;
- (void)sendRequestOnClient;
- (void)sendResponseOnSocket;
- (void)sendResponseChunkOnSocket:(NSData *)data;
- (void)sendErrorToOwner;

- (void)setSocketDisconnected;
- (BOOL)authenticateWithAutoResponseOnFailure:(BOOL)autoResponse;
- (void)setErrorCode:(NSInteger)code description:(NSString *)description;
- (BOOL)authenticate;

- (void)updateProgress:(MGSRequestProgress *)progress;

- (BOOL)isReadSuspended;
- (void)setReadSuspended:(BOOL)newValue;
- (void)setWriteSuspended:(BOOL)newValue;
- (BOOL)isWriteSuspended;

- (void)addScratchPath:(NSString *)path;

- (void)disconnect;
- (NSString *)UUID;
- (BOOL)sent;

- (void)dispose;
- (void)sendRequestOnClientSocket;

- (NSString *)requestCommand;
- (NSString *)kosmicTaskCommand;
- (BOOL)secure;
- (MGSNetRequest *)enqueueNegotiateRequest;
- (void)inheritConnection:(MGSNetRequest *)request;
- (MGSNetRequest *)queuedNegotiateRequest;

- (BOOL)validateOnCompletion:(MGSError **)mgsError;
- (BOOL)isSocketConnected;
- (void)prepareToResend;
- (BOOL)commandBasedNegotiation;

- (void)tagError:(MGSError *)error;
- (void)addChildRequest:(MGSNetRequest *)request;


@property (readonly) MGSNetSocket *netSocket;
@property (readonly) MGSNetClient *netClient;
@property (readonly) MGSNetMessage *requestMessage;
@property (readonly) MGSNetMessage *responseMessage;
@property eMGSRequestStatus status;
@property (assign) id delegate;
@property (assign) id owner;
@property (assign) MGSError *error;
@property NSTimeInterval readTimeout;
@property NSTimeInterval writeTimeout;
@property (readonly) unsigned long int requestID;
@property (assign) id ownerObject;
@property (copy)NSString *ownerString;
@property BOOL allowUserToAuthenticate;
@property BOOL sendUpdatesToOwner;
@property (assign) MGSNetRequest *prevRequest;			// previous request
@property (assign) MGSNetRequest *nextRequest;			// next request
@property (assign) NSMutableArray *childRequests;		// logging request
@property (assign) MGSNetRequest *parentRequest;			// parent request
@property (readonly) NSUInteger flags;
@property (readonly) NSMutableArray *chunksReceived;
@property eMGSRequestType requestType;
@end


