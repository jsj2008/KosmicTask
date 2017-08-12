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

enum _eMGSRequestType {
    kMGSRequestTypeWorker = 0,  
    kMGSRequestTypeLogging = 1
};
typedef NSInteger eMGSRequestType;

// net request status
enum _eMGSRequestStatus {
    kMGSStatusTerminated = -3,
	kMGSStatusExceptionOnConnecting = -2,
	kMGSStatusCannotConnect = -1,
	
	kMGSStatusNotConnected = 0,
	
    // these values reflect the socket state.
    // they say nothing about whether data has actually beet sent over the wire.
    // eg: the connected state will be reported even if the remote host drops the connection immediately.
	kMGSStatusResolving = 1,
	kMGSStatusConnecting = 2,
	kMGSStatusConnected = 3,    // socket reports connection
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
	
};
typedef NSInteger eMGSRequestStatus;

@class MGSNetMessage;
@class MGSNetSocket;
@class MGSNetRequest;
@class MGSNetRequestPayload;
@class MGSRequestProgress;

// net request delegate protocol
@protocol MGSNetRequestDelegate <NSObject>

@optional
- (void)sendRequestOnClient:(MGSNetRequest *)request;
- (void)requestDidComplete:(MGSNetRequest *)netRequest;
- (void)sendResponseOnSocket:(MGSNetRequest *)netRequest wasValid:(BOOL)valid;
- (void)requestAuthenticationFailed:(MGSNetRequest *)netRequest;
- (void)requestTimerExpired:(MGSNetRequest *)request;
@end


@interface MGSNetRequest : MGSDisposableObject <NSCopying> {
    eMGSRequestType _requestType;
	MGSNetMessage *_requestMessage;		// request message sent from client to server
	MGSNetMessage *_responseMessage;	// response message from server to client
	MGSNetSocket *_netSocket;			// netsocket
	eMGSRequestStatus _status;			// request status
	eMGSRequestStatus _previousStatus;	// previous request status
	__weak id <MGSNetRequestDelegate> _delegate;// delegate
    MGSError *_error;					// request error
	unsigned long int _requestID;		// request sequence counter
	NSMutableArray *temporaryPaths;		// paths to be removed when the request is finalised
	NSUInteger _flags;
    NSMutableArray *_chunksReceived;    // chunks received
    
@private
    NSMutableArray *_childRequests;     // child requests
	NSInteger _readTimeout;		// request read timeout
	NSInteger _writeTimeout;		// request write timeout
    NSInteger _timeout;
    NSTimer *_writeConnectionTimer;
    NSTimer *_requestTimer;
    BOOL _allowRequestTimeout;
    BOOL _allowWriteConnectionTimeout;
    __weak MGSNetRequest *_parentRequest;      // parent request
    NSUInteger _timeoutCount;
}

+ (NSThread *)networkThread;
-(void)initialise;
- (void)resetMessages;
- (void)socketDidDisconnect;
- (void)setErrorCode:(NSInteger)code description:(NSString *)description;
- (BOOL)isReadSuspended;
- (void)setReadSuspended:(BOOL)newValue;
- (void)setWriteSuspended:(BOOL)newValue;
- (BOOL)isWriteSuspended;
- (void)chunkStringReceived:(NSString *)chunk;
- (void)addScratchPath:(NSString *)path;
- (void)disconnect;
- (NSString *)UUID;
- (void)dispose;
- (NSString *)requestCommand;
- (NSString *)kosmicTaskCommand;
- (BOOL)secure;
- (BOOL)isSocketConnected;
- (BOOL)commandBasedNegotiation;
- (void)addChildRequest:(MGSNetRequest *)request;

// timeout handling
- (void)writeConnectionDidTimeout:(NSTimer *)timer;
- (void)requestDidTimeout:(NSTimer *)timer;
- (void)startRequestTimer;
- (void)setTimeoutForRead:(NSInteger)rt write:(NSInteger)wt;
- (void)startWriteConnectionTimer;

@property (readonly) NSMutableArray *childRequests;		// logging request
@property (weak) MGSNetRequest *parentRequest;			// parent request
@property (readonly) MGSNetSocket *netSocket;
@property (strong, nonatomic) MGSNetMessage *requestMessage;
@property (readonly, nonatomic) MGSNetMessage *responseMessage;
@property (nonatomic) eMGSRequestStatus status;
@property eMGSRequestStatus lastStatus;
@property (weak) id <MGSNetRequestDelegate> delegate;
@property (strong) MGSError *error;
@property (readonly) NSInteger readTimeout;
@property (readonly) NSInteger writeTimeout;
@property (nonatomic) NSInteger timeout;
@property (readonly) unsigned long int requestID;
@property (readonly) NSUInteger flags;
@property (readonly) NSMutableArray *chunksReceived;
@property eMGSRequestType requestType;
@property BOOL allowRequestTimeout;
@property BOOL allowWriteConnectionTimeout;
@property (readonly) NSUInteger timeoutCount;

@end


