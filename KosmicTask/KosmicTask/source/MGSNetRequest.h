//
//  MGSNetRequest.h
//  Mother
//
//  Created by Jonathan on 30/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSDisposableObject.h"

@class MGSError;

#define MGS_STANDARD_TIMEOUT 60

typedef enum _eMGSRequestType {
    kMGSRequestTypeWorker = 0,  
    kMGSRequestTypeLogging = 1
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
@class MGSNetSocket;
@class MGSNetRequest;
@class MGSNetRequestPayload;
@class MGSRequestProgress;

// net request delegate protocol
@protocol MGSNetRequestDelegate

@optional
- (void)sendRequestOnClient:(MGSNetRequest *)request;
- (void)netRequestReplyOnClient:(MGSNetRequest *)netRequest;
- (void)sendResponseOnSocket:(MGSNetRequest *)netRequest wasValid:(BOOL)valid;
- (void)authenticationFailed:(MGSNetRequest *)netRequest;
@end


@interface MGSNetRequest : MGSDisposableObject <NSCopying> {
    eMGSRequestType _requestType;
	MGSNetMessage *_requestMessage;		// request message sent from client to server
	MGSNetMessage *_responseMessage;	// response message from server to client
	MGSNetSocket *_netSocket;			// netsocket
	eMGSRequestStatus _status;			// request status
	id _delegate;						// delegate
	MGSError *_error;					// request error
	NSTimeInterval _readTimeout;		// request read timeout
	NSTimeInterval _writeTimeout;		// request write timeout
	unsigned long int _requestID;		// request sequence counter
	BOOL _allowUserToAuthenticate;		// allow user to authenticate the request
	NSMutableArray *temporaryPaths;		// paths to be removed when the request is finalised
	NSUInteger _flags;
    NSMutableArray *_chunksReceived;    // chunks received
    NSMutableArray *_childRequests;     // child requests
    MGSNetRequest *_parentRequest;      // parent request
}

+ (NSThread *)networkThread;
-(void)initialise;
- (void)resetMessages;
- (void)setSocketDisconnected;

- (void)setErrorCode:(NSInteger)code description:(NSString *)description;



- (BOOL)isReadSuspended;
- (void)setReadSuspended:(BOOL)newValue;
- (void)setWriteSuspended:(BOOL)newValue;
- (BOOL)isWriteSuspended;
- (void)chunkStringReceived:(NSString *)chunk;

- (void)addScratchPath:(NSString *)path;

- (void)disconnect;
- (NSString *)UUID;
- (BOOL)sent;

- (void)dispose;

- (NSString *)requestCommand;
- (NSString *)kosmicTaskCommand;
- (BOOL)secure;
- (void)inheritConnection:(MGSNetRequest *)request;

- (BOOL)validateOnCompletion:(MGSError **)mgsError;
- (BOOL)isSocketConnected;
- (void)prepareToResend;
- (BOOL)commandBasedNegotiation;


- (void)addChildRequest:(MGSNetRequest *)request;

@property (assign) NSMutableArray *childRequests;		// logging request
@property (assign) MGSNetRequest *parentRequest;			// parent request
@property (readonly) MGSNetSocket *netSocket;
@property (assign) MGSNetMessage *requestMessage;
@property (readonly) MGSNetMessage *responseMessage;
@property eMGSRequestStatus status;
@property (assign) id delegate;
@property (assign) MGSError *error;
@property NSTimeInterval readTimeout;
@property NSTimeInterval writeTimeout;
@property (readonly) unsigned long int requestID;
@property BOOL allowUserToAuthenticate;
@property (readonly) NSUInteger flags;
@property (readonly) NSMutableArray *chunksReceived;
@property eMGSRequestType requestType;
@end


