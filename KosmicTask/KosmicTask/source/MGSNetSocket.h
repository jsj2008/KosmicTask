//
//  MGSNetSocket.h
//  Mother
//
//  Created by Jonathan on 25/08/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define NETSOCKET_CLIENT 0
#define NETSOCKET_SERVER 1

enum MGSNetSocketWriteTags {
    kMGSSocketWriteProbe = 0,
    kMGSSocketWriteMessage,
    kMGSSocketWriteAttachmentData,
    kMGSSocketWriteAttachmentChunk,
    kMGSSocketWriteAttachmentLastChunk,
};

enum MGSNetSocketReadTags {
    kMGSSocketReadMessage = 0,
    kMGSSocketReadAttachmentData,
    kMGSSocketReadAttachmentChunkSize,
    kMGSSocketReadAttachmentChunk,
    kMGSSocketReadAttachmentLastChunk,
};

extern NSString *const MGSNetSocketSecurityException;
extern NSString *const MGSNetSocketException;

@class MGSNetRequest;
@class MGSAsyncSocket;
@class MGSNetSocket;
@class MGSNetMessage;

// formal delegate protocol
@protocol MGSNetSocketDelegate <NSObject>

@optional

@required
- (void)netSocketDisconnect:(MGSNetSocket *)netSocket;
- (BOOL)netSocketShouldConnect:(MGSNetSocket *)netSocket;
@end

@interface MGSNetSocket : NSObject {
	@private
	MGSNetRequest *_netRequest;
	MGSAsyncSocket *_socket;
	id _delegate;
	NSUInteger _mode;
	NSUInteger _sendAttachmentIndex;
	NSUInteger _readAttachmentIndex;
	NSUInteger _flags;
}

@property (assign) MGSNetRequest *netRequest;
@property MGSAsyncSocket *socket;


- (id)initWithMode:(NSUInteger)mode;
- (void)disconnect;
- (BOOL)disconnectCalled; // JM 23-02-08  GC compatibility;
- (id <MGSNetSocketDelegate>)delegate;
- (void)setDelegate:(id <MGSNetSocketDelegate>)delegate;
- (BOOL)isConnected;
- (void)onSocket:(MGSAsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag;
- (void)onReadBadDataWithErrors:(NSString *)errors;
- (void)onWriteBadDataWithErrors:(NSString *)error;
- (void)onSocket:(MGSAsyncSocket *)sock didWriteDataWithTag:(long)tag;
- (void)queueReadMessage;
- (void)queueSendMessage;
- (MGSNetMessage *)messageToBeRead;
- (MGSNetMessage *)messageToBeWritten;
- (void)sendResponse;
- (void)sendResponseChunk:(NSData *)data;
- (void)sendRequest;
- (void)progressOfRead:(unsigned long *)bytesDone totalBytes:(unsigned long *)bytesTotal;
- (void)progressOfWrite:(unsigned long *)bytesDone totalBytes:(unsigned long *)bytesTotal;
- (void)startTLS:(NSDictionary *)sslProperties;
- (BOOL)startSecurity;
- (BOOL)acceptRequestNegotiator;
- (BOOL)willSecure;
- (BOOL)isConnectedToLocalHost;
@end
