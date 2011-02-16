//
//  MGSNetSocket.m
//  Mother
//
//  Created by Jonathan on 25/08/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSMother.h"
#import "MGSNetSocket.h"
#import "MGSAsyncSocket.h"
#import "MGSNetHeader.h"
#import "MGSNetMessage.h"
#import "MGSNetRequest.h"
#import "MGSNetAttachment.h"
#import "MGSNetNegotiator.h"

enum MGSNetSocketFlags {
	kSecureConnectionRequested      = 1 <<  0,  // If set, a secure connection has been requested
	kSecureConnection				= 1 <<  1,  // If set, a secure connection has been established
};

NSString *const MGSNetSocketSecurityException = @"MGSNetSocketSecurityException";
NSString *const MGSNetSocketException = @"MGSNetSocketException";

#define ATTACHMENT_DATA_BLOCK_LENGTH 10000

// class extension
@interface MGSNetSocket ()
@end

@interface MGSNetSocket (Private)
- (BOOL)sendAttachments;
- (BOOL)readAttachmentData:(NSData *)data;
@end


@implementation MGSNetSocket

@synthesize netRequest = _netRequest;
@synthesize socket = _socket;

/*
 
 init
 
 */
- (id)init
{
	return [self initWithMode:NETSOCKET_CLIENT];
}

/*
 
 init With Mode
 
 designated initialiser
 
 */
- (id)initWithMode:(NSUInteger)mode
{
	if ((self = [super init])) {
		
		if (mode != NETSOCKET_CLIENT && mode != NETSOCKET_SERVER) {
			NSAssert(NO, @"invalid socket mode");
			return nil;
		}
		
		_mode = mode;
		_netRequest = nil;
		_socket = nil;
		_delegate = nil;
		_sendAttachmentIndex = 0;
		_readAttachmentIndex = 0;
	}
	
	return self;
}

/*
 
 disconnect called
 
 */
- (BOOL)disconnectCalled // JM 23-02-08  GC compatibility
{
	return [_socket disconnectCalled];
}

/*
 
 delegate
 
 */
- (id <MGSNetSocketDelegate>)delegate
{
	return _delegate;
}

/*
 
 set delegate
 
 */
- (void)setDelegate:(id <MGSNetSocketDelegate>)aDelegate
{
	_delegate = aDelegate;
}

/*
 
 finalize
 
 */
- (void)finalize
{
	// disconnect must have been called on the socket
	BOOL disconnectCalled = [self disconnectCalled];
	NSAssert(disconnectCalled, @"disconnect not called on socket");
	[super finalize];
}


/*
 
 disconnect
 
 */
- (void)disconnect
{
	[_socket disconnect];
}

/*
 
 socket is connected
 
 */
- (BOOL)isConnected
{
	return [_socket isConnected];
}

/*
 
 - isConnectedToLocalHost
 
 */
- (BOOL)isConnectedToLocalHost
{
	if ([self isConnected]) { 
		return [_socket.localHost isEqual:_socket.connectedHost];
	}
	
	return NO;
}
/*
 
 send request
 
 needs to be overidden
 
 */
- (void)sendRequest
{
	[NSException raise:MGSNetSocketException format:@"method must be overridden"];
}

/*
 
 send response
 
 needs to be overidden
 
 */
- (void)sendResponse
{
	[NSException raise:MGSNetSocketException format:@"method must be overridden"];
}

/*
 
 read message
 
 */
- (MGSNetMessage *)messageToBeRead
{
	return _mode == NETSOCKET_CLIENT ? _netRequest.responseMessage : _netRequest.requestMessage;
}

/*
 
 write message
 
 */
- (MGSNetMessage *)messageToBeWritten
{
	return _mode == NETSOCKET_CLIENT ? _netRequest.requestMessage : _netRequest.responseMessage;
}

#pragma mark -
#pragma mark AsyncSocket delegate messages
/*
 
 on socket did read data
 
 */
-(void) onSocket:(MGSAsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag
{
	NSString *error = nil;
	NSException *throwMe = nil;
	
	@try {
		
		// get data string rep
		NSString *dataString = nil;
		
		switch (_netRequest.status) {
				
			// no string rep valid
			case kMGSStatusReadingMessageAttachments:
			case kMGSStatusMessageReceived:
				dataString = @"no data string rep available";
				break;
				
			default:
				dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
				break;
		}
		
		
		// data length
		NSInteger dataLength = [data length];
		
		// Print string.
		if (NO) {
			MLog(DEBUGLOG, @"Socket received data: %@", dataString);
		}
		
		NSAssert(_netRequest, @"net request is nil");
		
		// update net message with bytes read
		MGSNetMessage *netMessage = [self messageToBeRead];
		netMessage.bytesTransferred += (unsigned long long)dataLength;
		
		NSAssert(netMessage, @"net message is nil");
		
		switch (_netRequest.status) {
				
				// awaiting message header
			case kMGSStatusReadingMessageHeaderPrefix:
				
				// expecting a fixed length prefix
				if (dataLength != MGSNetHeaderLength) {
					MLog(RELEASELOG, @"invalid header prefix length received %@", dataString);
					error = @"invalid header prefix";
					goto cleanup;
				}
				
				// validate prefix
				if ([netMessage.header validatePrefix:dataString]) {
					
					// get total length of header
					NSUInteger length = netMessage.header.headerLength;
					
					// subtract length already read
					length -= MGSNetHeaderLength;
					
					_netRequest.status = kMGSStatusReadingMessageHeader;
					netMessage.expectedLength = length;
					
					// Read remaining header data from the socket.
					[sock readDataToLength:length withTimeout:_netRequest.readTimeout tag:tag];	
				} else {
					MLog(RELEASELOG, @"invalid header prefix received %@", dataString);
					error = @"invalid header prefix";
					goto cleanup;
				}
				break;
				
				// header prefix received, awaiting header completion
			case kMGSStatusReadingMessageHeader:
				
				if (dataLength != netMessage.expectedLength) {
					error = @"unexpected header length";
					MLog(RELEASELOG, @"unexpected header length %@", dataString);
					goto cleanup;				
				}
				
				// validate header
				if ([netMessage.header validateHeader:dataString]) {
					
					// get the payload size
					NSUInteger length = netMessage.header.contentLength;
					
					// get request timeouts from the header
					_netRequest.readTimeout = netMessage.header.responseTimeout;
					_netRequest.writeTimeout = netMessage.header.requestTimeout;
					
					_netRequest.status = kMGSStatusReadingMessagePayload;
					netMessage.expectedLength = length;
					
					// Read payload data from this socket.
					[sock readDataToLength:length withTimeout:_netRequest.readTimeout tag:tag];	
				} else {
					error = @"invalid header received";
					MLog(RELEASELOG, @"invalid header received %@", dataString);
					goto cleanup;
				}
				break;
				
				// header received, awaiting payload
			case kMGSStatusReadingMessagePayload:
				if (dataLength != netMessage.expectedLength) {
					error = @"unexpected payload length";
					MLog(RELEASELOG, @"unexpected payload length %@", dataString);
					goto cleanup;				
				}
				
				// get the dict from the data
				if (![netMessage messageDictFromData:data]) {
					error = @"bad message payload data";
					MLog(RELEASELOG, @"cannot extract dictionary from payload %@", dataString);
					goto cleanup;
				}
				
				// start reading attachments
				//
				// after - readAttachmentData has returned
				// status may be kMGSStatusMessageReceived if no attachments
				// or all attachments have been sent
				//
				if (![self readAttachmentData:nil]) {
					error = @"cannot read attachment data";
					MLog(RELEASELOG, @"%@", error);
					goto cleanup;
				}
				
				break;
				
				// reading attachments
			case kMGSStatusReadingMessageAttachments:

				if (![self readAttachmentData:data]) {
					error = @"cannot read attachment data";
					MLog(RELEASELOG, @"%@", error);
					goto cleanup;
				}
				
				
				break;

			case kMGSStatusMessageReceived:
				break;

			default:
				error = @"bad request status";
				MLog(RELEASELOG, @"Socket read data not processed.");
				goto cleanup;
				break;
		}
	}
	@catch (NSException *e) {
		error = [NSString stringWithFormat: @"Exception reading network data: ", e];
		throwMe = e;
		goto cleanup;
	}
	
	return;
	
cleanup:
	[self onReadBadDataWithErrors: error];
	
	if (throwMe) {
		@throw throwMe;
	}
	
	return;
	
}

/* 
 
 on read bad data with errors
 
 if overridden the subclass must call the super implementation
 
 */
- (void)onReadBadDataWithErrors:(NSString *)error
{
#pragma unused(error)
	
	[self disconnect];
}


/* 
 
 on write bad data with errors
 
 if overridden the subclass must call the super implementation
 
 */
- (void)onWriteBadDataWithErrors:(NSString *)error
{
	#pragma unused(error)
	
	[self disconnect];
}

/*
 
 socket did write data
 
 */
-(void) onSocket:(MGSAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	#pragma unused(sock)
	#pragma unused(tag)
	
	NSString *error = nil;
	NSException *throwMe = nil;
	
	@try {		
		
		// get number of bytes written and update message
		unsigned long bytesDone = 0, bytesTotal = 0;
		[self progressOfWrite:&bytesDone totalBytes:&bytesTotal];
		
		MGSNetMessage *message = [self messageToBeWritten];
		message.bytesTransferred += (unsigned long long)bytesDone;
				
		switch (_netRequest.status) {
				
			// If sending message content has completed then start sending attachments
			//
			// Note that the message header and payload are sent as one data block.
			// The message is usually short so passing it as a single NSData object should be okay.
			// Attachments are sent in a number of data blocks.
			// Attachments may be any size. It is not feasible to pass these as an NSData instance.
			// The attachment data will be written to file as it is read.
			//
			case kMGSStatusSendingMessage:
			case kMGSStatusSendingMessageAttachments:
				
				// send attachment data if required
				if (![self sendAttachments]) {
					error = @"cannot send attachment data";
					goto cleanup;				
				}
				
				break;
				
			default:
				break;
				
		}
		
		switch (_netRequest.status) {
				
				// if sending attachments then wait for callback
			case kMGSStatusSendingMessageAttachments:
				return;
				
			case kMGSStatusMessageSent:
				
				// all request data sent, queue read message
				[self queueReadMessage];
				MLog(DEBUGLOG, @"Read queued");
				break;
				
			default:
				MLog(RELEASELOG, @"invalid request status: %i", _netRequest.status);
				break;
		}
	}
	@catch (NSException *e) {
		error = [NSString stringWithFormat: @"Exception writing network data: ", e];
		throwMe = e;
		goto cleanup;
	}
	
	return;
	
cleanup:
	[self onWriteBadDataWithErrors: error];
	
	if (throwMe) {
		@throw throwMe;
	}
	
	return;
}

/*
 
 - onSocketDidSecure:
 
 */
- (void)onSocketDidSecure:(AsyncSocket *)sock
{
	NSAssert(sock == _socket, @"message from unknown socket");
	
	_flags |= kSecureConnection;
	_flags &= ~kSecureConnectionRequested;
	
	MLog(DEBUGLOG, @"Socket secured");
}

/*
 
 - willSecure
 
 */
- (BOOL)willSecure
{
	// AsyncSocket queues its requests and will make the socket secure when
	// pending non secure reads and writes complete
	return (_flags & kSecureConnection) || (_flags & kSecureConnectionRequested);
}

/*
 
 queue read message
 
 */
- (void)queueReadMessage
{
	_netRequest.status = kMGSStatusReadingMessageHeaderPrefix;
	
	// queue another read.
	// if the remote socket disconnects then a willDisconnect message
	// will be sent followed by didDisconnect.
	// allowing the read to detect the socket EOF allows the normal
	// TCP shutdown sequence to be followed.
	[_socket readDataToLength:MGSNetHeaderLength withTimeout:_netRequest.readTimeout tag:0];
	
	MLog(DEBUGLOG, @"A read has been queued. Awaiting response...");
	
}

/*
 
 queue send message
 
 */
- (void)queueSendMessage
{
	NSAssert(_socket, @"socket is nil");
	NSAssert(_netRequest, @"net request is nil");
	
	// get message packet
	MGSNetMessage *netMessage = [self messageToBeWritten];
	NSMutableData *data = [netMessage messagePacket];
	if (!data) {
		[self disconnect];
		[_netRequest setError:[netMessage packetError]];
		[NSException raise:MGSNetSocketException format:@"Message packet is empty."];	
	}
	
	if ([netMessage authenticationDictionary] && ![self willSecure] && ![self isConnectedToLocalHost]) {
		MLogInfo(@"MGSNetSocket instance: %p", self);
		[NSException raise:MGSNetSocketSecurityException format:@"Cannot attempt to authenticate over a non secure connection."];
	}
	
	// send the packet data
	_netRequest.status = kMGSStatusSendingMessage;
	[_socket writeData:data withTimeout:_netRequest.writeTimeout tag:0];
}

/*
 
 progress of read
 
 note that this is the progress of the current read operation not the entire request.
 if a series of data blocks are to be read then this method reports the progress
 within each block.
 
 */
- (void)progressOfRead:(unsigned long *)bytesDone totalBytes:(unsigned long *)bytesTotal
{
	long tag;
	NSUInteger done = 0;
	NSUInteger total = 0;
	float progressReturn = [self.socket progressOfReadReturningTag:&tag bytesDone:&done total:&total];

	if (isnan(progressReturn)) {
		// if read not in progress we get back NAN
		//MLog(RELEASELOG, @"invalid value returned");
	} else {
		*bytesDone = (unsigned long)done;
		*bytesTotal = (unsigned long)total;
	}
}


/*
 
 progress of write
 
 */
- (void)progressOfWrite:(unsigned long *)bytesDone totalBytes:(unsigned long *)bytesTotal
{
	long tag;
	NSUInteger done = 0;
	NSUInteger total = 0;
	float progressReturn = [self.socket progressOfWriteReturningTag:&tag bytesDone:&done total:&total];
	
	// progressReturn will contain NAN if the write hasn't commenced yet.
	// this always occurs when initiating a request as an observer is notified when the duration timer
	// is initialised, which causes this message to be sent.
	if (isnan(progressReturn)) {
		//MLog(RELEASELOG, @"invalid value returned");
		done = 0;
		total = 0;
	} 
	
	*bytesDone = (unsigned long)done;
	*bytesTotal = (unsigned long)total;
	
}

#pragma mark -
#pragma mark Negotiator

/*
 
 - acceptRequestNegotiator
 
 */
- (BOOL)acceptRequestNegotiator
{
	BOOL success = YES;
	
	MGSNetNegotiator *negotiator = self.netRequest.responseMessage.negotiator;
	if (negotiator) {
		if ([negotiator TLSSecurityRequested]) {
			if (![self startSecurity]) {
				MLogInfo(@"Negotiator security request failed");
				return NO;
			}
		} else {
			MLogDebug(@"No Negotiator security requested");
		}
	} else {
		MLogDebug(@"No Negotiator found");
	}
	
	return success;
}

#pragma mark -
#pragma mark Security
/*
 
 - startTLS:
 
 */
- (void)startTLS:(NSDictionary *)sslProperties
{
	if (![self willSecure]) {
		_flags |= kSecureConnectionRequested;
		[self.socket startTLS:sslProperties];
	}
}

/*
 
 - startSecurity
 
 */
- (BOOL)startSecurity
{
	return NO;
}

@end

@implementation MGSNetSocket (Private)

/*
 
 send attachments
 
 */
- (BOOL)sendAttachments
{
	NSString *error = nil;
	MGSNetAttachment *attachment = nil;
	
	@try {
		
		MGSNetMessage *netMessage = [self messageToBeWritten];
		
		// get attachments - may be none
		NSArray *attachments = [netMessage.attachments array];
		if (!attachments || [attachments count] == 0) {
			
			MLog(DEBUGLOG, @"No attachments sent.");
			
			_netRequest.status = kMGSStatusMessageSent;
			return YES;
		}
		
		// initialise sending attachments
		if (_netRequest.status != kMGSStatusSendingMessageAttachments) {
			_sendAttachmentIndex = 0;
			_netRequest.status = kMGSStatusSendingMessageAttachments;		
		}

		// get current attachment
		attachment = [attachments objectAtIndex:_sendAttachmentIndex];
		if (![attachment openForReading]) {
			error = @"Cannot open attachment file for reading";
			goto errorExit;
		}

		// get length still to send
		unsigned long long remainingLength = [attachment validatedLength] - [attachment readOffset];
		
		// if attachment data sent then initialise sending of next attachment
		if (remainingLength == 0) {

			MLog(DEBUGLOG, @"Attachment sent: index: %i path: %@ actual length: %qu validated length: %qu", _sendAttachmentIndex, attachment.filePath, [attachment readOffset], attachment.validatedLength);

			[attachment closeForReading];
			_sendAttachmentIndex++;
			
			// check if all attachments sent
			if (_sendAttachmentIndex >= [attachments count]) {
				_netRequest.status = kMGSStatusMessageSent;
				return YES;
			}
			
			// get new attachment
			attachment = [attachments objectAtIndex:_sendAttachmentIndex];
			if (![attachment openForReading]) {
				error = @"cannot open attachment file for reading";
				goto errorExit;
			}
			
			remainingLength = [attachment validatedLength] - [attachment readOffset];
		}

		// read attachment data from file
		MGSError *mgsError = nil;
		unsigned long long readLength = remainingLength > ATTACHMENT_DATA_BLOCK_LENGTH ? ATTACHMENT_DATA_BLOCK_LENGTH : remainingLength;
		NSData *data = [attachment readDataOfLength:(NSUInteger)readLength error:&mgsError];
		if (!data) {
			error = @"cannot read data from attachment file";
			goto errorExit;
		}
		
		// send the attachment data
		[_socket writeData:data withTimeout:_netRequest.writeTimeout tag:0];
		
	} 
	@catch (NSException *e) {
		error = [NSString stringWithFormat: @"Exception sending attachment data:", e];
		goto errorExit;
	}
	
	return YES;
	
errorExit:
	if (attachment) {
		[attachment closeForReading];
	}
	
	MLog(RELEASELOG, error);
	return NO;
}

/*
 
 read attachment data
 
 */
- (BOOL)readAttachmentData:(NSData *)data
{
	NSString *error = nil;
	MGSNetAttachment *attachment = nil;
	
	@try {
		MGSNetMessage *netMessage = [self messageToBeRead];
		
		// get attachments - may be none
		NSArray *attachments = [netMessage.attachments array];
		if (!attachments || [attachments count] == 0) {

			MLog(DEBUGLOG, @"No attachments read.");
			
			_netRequest.status = kMGSStatusMessageReceived;
			return YES;
		}
		
		// initialise reading attachments
		if (_netRequest.status != kMGSStatusReadingMessageAttachments) {
			_readAttachmentIndex = 0;
			_netRequest.status = kMGSStatusReadingMessageAttachments;		
		}

		// get current attachment
		attachment = [attachments objectAtIndex:_readAttachmentIndex];
		if (![attachment openForWriting]) {
			error = @"cannot open attachment file for writing";
			goto errorExit;
		}

		// if data available write to file
		if (data) {
			MGSError *mgsError = nil;
			if (![attachment writeData:data error:&mgsError]) {
				error = @"cannot write data to attachment file";
				goto errorExit;
			}
		}

		// get length still to read
		unsigned long long remainingLength = [attachment requiredLength] - [attachment writeOffset];

		// if attachment data read then initialise reading of next attachment
		if (remainingLength == 0) {

			MLog(DEBUGLOG, @"Attachment read: index: %i path: %@ actual length: %qu required length: %qu", _readAttachmentIndex, attachment.filePath, [attachment writeOffset], attachment.requiredLength);
			
			// close the attachment
			[attachment closeForWriting];
			
			_readAttachmentIndex++;
						
			// check if all attachments read
			if (_readAttachmentIndex >= [attachments count]) {
				
				// parse attachments
				[netMessage parseAttachments];

				_netRequest.status = kMGSStatusMessageReceived;
				return YES;
			}

			// get new attachment
			attachment = [attachments objectAtIndex:_readAttachmentIndex];
			if (![attachment openForWriting]) {
				error = @"cannot open attachment file for writing";
				goto errorExit;
			}
			
			remainingLength = [attachment requiredLength] - [attachment writeOffset];
		}

		unsigned long long readLength = remainingLength > ATTACHMENT_DATA_BLOCK_LENGTH ? ATTACHMENT_DATA_BLOCK_LENGTH : remainingLength;

		// read the attachment data
		[_socket readDataToLength:(NSUInteger)readLength withTimeout:_netRequest.readTimeout tag:0];	
		
	} 
	@catch (NSException *e) {
		error = [NSString stringWithFormat: @"Exception reading attachment data:", e];
		goto errorExit;
	}
	
	return YES;
	
errorExit:
	if (attachment) {
		[attachment closeForWriting];
	}
	MLog(RELEASELOG, error);
	return NO;
}


@end
