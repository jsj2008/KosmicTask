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

MGS_INSTANCE_TRACKER_DEFINE;

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
- (BOOL)readAttachmentIdentityData:(NSData *)data withTag:(long)tag;
- (void)readAttachmentChunkedData:(NSData *)data withTag:(long)tag;
- (void)readAttachments:(NSData *)data withTag:(long)tag;
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
        
        MGS_INSTANCE_TRACKER_ALLOCATE;
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

    MGS_INSTANCE_TRACKER_DEALLOCATE;
    
    // we really don't want to access any objects in fiablize!
    
	// disconnect must have been called on the socket
	if (![self disconnectCalled]) {
        MLogInfo(@"disconnect not called on socket");
    }
    
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
 
 send response chunk
 
 needs to be overidden
 
 */
- (void)sendResponseChunk:(NSData *)data
{
    #pragma unused(data)
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
		_netRequest.lastStatus = _netRequest.status;
        
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
                    // we timeout the request as a whole not the read.
					[sock readDataToLength:length withTimeout:-1 tag:tag];
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
					[_netRequest setTimeoutForRead:netMessage.header.responseTimeout write:netMessage.header.requestTimeout];
					
					_netRequest.status = kMGSStatusReadingMessageBody;
					netMessage.expectedLength = length;
					
					// Read payload data from this socket.
                    // we timeout the request as a whole not the read.
					[sock readDataToLength:length withTimeout:-1 tag:tag];
				} else {
					error = @"invalid header received";
					MLog(RELEASELOG, @"invalid header received %@", dataString);
					goto cleanup;
				}
				break;
				
				// header received, awaiting payload
			case kMGSStatusReadingMessageBody:
                
                // validate the data length
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
				
                // start reading attachments if present.
                [self readAttachments:nil withTag:tag];
             				
				break;
				
				// continue reading attachments
			case kMGSStatusReadingMessageAttachments:
                
                //  read attachment data
                [self readAttachments:data withTag:tag];
				
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
		error = [NSString stringWithFormat: @"Socket read error: %@ %@", [e name], [e reason]];
		throwMe = e;
		goto cleanup;
	}
	
	return;
	
cleanup:
	[self onReadBadDataWithErrors:error];
	
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
    
        _netRequest.lastStatus = _netRequest.status;
		switch (_netRequest.status) {
				
			// If sending message content has completed then start sending attachments
			//
			// Note that the message header and payload are normally sent as one data block.
			// The message is usually short so passing it as a single NSData object should be okay.
			// Attachments are sent in a number of data blocks.
			// Attachments may be any size. It is not feasible to pass these as an NSData instance.
			// The attachment data will be written to file as it is read.
			//
			case kMGSStatusSendingMessage:
                // check we have sent all the message data.
                // we may send it in one or more packets
                if (message.bytesTransferred < message.nonAttachmentLength) {
                    return;
                }
                
			case kMGSStatusSendingMessageAttachments:
				
                // sending chunked attachments
                if ([message.header.attachmentTransferEncoding isEqualToString:MGSNetHeaderAttachmentTransferEncodingChunked]) {
                    
                    switch (_netRequest.status) {
                        
                        // we have sent our message so we now wait for chunks to be written
                        case kMGSStatusSendingMessage:
                            _netRequest.status = kMGSStatusSendingMessageAttachments;
                            break;

                        // we sent a chunk so check it it was the last one.
                        // if so our message is done.
                        case kMGSStatusSendingMessageAttachments:
                            
                            if (tag == kMGSSocketWriteAttachmentLastChunk) {
                                _netRequest.status = kMGSStatusMessageSent;
                            }
                            break;

                        default:
                            break;
                    }
                    
                // sending identity attachments
                } else if (![self sendAttachments]) {
					error = @"cannot send attachment data";
					goto cleanup;				
				}
				
				break;
				
			default:
				break;
				
		}
		
		switch (_netRequest.status) {
				
				// if sending attachments then wait for callback
                // or wait for more chunked data to be written
			case kMGSStatusSendingMessageAttachments:
				return;
				
			case kMGSStatusMessageSent:
				
				// all request data sent, queue read message
                
                // we only want to do this once!
                if (self.netRequest.lastStatus != kMGSStatusMessageSent) {
                    [self queueReadMessage];
                } else {
                    MLogDebug(@"Unexpected message status: %d", _netRequest.status);
                }
				break;
				
			default:
				MLog(RELEASELOG, @"invalid request status: %i", _netRequest.status);
				break;
		}
	}
	@catch (NSException *e) {
		error = [NSString stringWithFormat: @"Exception writing network data: %@", e];
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
    // we timeout the request as a whole not the read.
	[_socket readDataToLength:MGSNetHeaderLength withTimeout:-1 tag:kMGSSocketReadMessage];
	
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
    
    // send initial short data packet with a short timeout.
    // this might enable us to detect a local socket error quickly.
    // note that it does nothing to help us if the remote end just drops the connection.
    // maybe a waste of time.
    NSUInteger probeLength = 4;
    BOOL useProbe = NO;
    
    if ([data length] > probeLength && probeLength > 0 && useProbe) {
        NSRange probeRange = NSMakeRange(0,probeLength);

        NSData *probeData = [data subdataWithRange:probeRange];
        if (probeData) {
            
            // resize the data
            [data replaceBytesInRange:probeRange withBytes:NULL length:0];
            
            //
            // write the probe with a limited timeout.
            // 
            [_socket writeData:probeData withTimeout:20 tag:kMGSSocketWriteProbe];
        }
    }
    
    // write the packet data.
    // we don't timeout the write.
    // instead we timeout the entire request.
    // note that we segment the data if required and send in individual write requests
    // in order to have control over the write timeouts.
	[_socket writeData:data withTimeout:-1 tag:kMGSSocketWriteMessage];
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
		
		// send the attachment data.
        // we don't timeout the write, rather we timeout the entire request.
		[_socket writeData:data withTimeout:-1 tag:kMGSSocketWriteAttachmentData];
		
	} 
	@catch (NSException *e) {
		error = [NSString stringWithFormat: @"Exception sending attachment data: %@", e];
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
 
 - readAttachments:withTag:
 
 */
- (void)readAttachments:(NSData *)data withTag:(long)tag
{
    
    MGSNetMessage *netMessage = [self messageToBeRead];
    
    // if no attachments then the message is complete
    if (netMessage.header.attachmentTransferEncoding == nil) {
        _netRequest.status = kMGSStatusMessageReceived;
        
        return;
        
    // chunked attachments
    } else if ([netMessage.header.attachmentTransferEncoding isEqualToString:MGSNetHeaderAttachmentTransferEncodingChunked]) {
        
        [self readAttachmentChunkedData:data withTag:tag];
    
    // identity attachments
    } else if ([netMessage.header.attachmentTransferEncoding isEqualToString:MGSNetHeaderAttachmentTransferEncodingIdentity]) {
        
        if (![self readAttachmentIdentityData:data withTag:tag]) {
            [NSException raise:MGSNetSocketException format:@"Error reading attachment data", nil];
        }
        
    // anything else  is invalid
    } else {
        [NSException raise:MGSNetSocketException format:@"Invalid attachment transfer encoding : %@", netMessage.header.attachmentTransferEncoding];
    }
}

/*
 
 - readAttachmentChunckedData:withTag: 
 */
- (void)readAttachmentChunkedData:(NSData *)data withTag:(long)tag
{
    // chunk terminator
    static NSData *chunkTerminatorData = nil;
    if (!chunkTerminatorData) {
        chunkTerminatorData = [MGSNetChunkTerminator dataUsingEncoding:NSUTF8StringEncoding];
    }

    // if we are done reading the message body start reading the chunks
    if (!data && _netRequest.status == kMGSStatusReadingMessageBody) {
        
        // we are now reading the attachments
        _netRequest.status = kMGSStatusReadingMessageAttachments;
        
        // read the first chunk size.
        // we timeout the request as a whole not the read.
        [_socket readDataToData:chunkTerminatorData withTimeout:-1 tag:kMGSSocketReadAttachmentChunkSize];

        return;
    }
    
    //
    // validate the data chunk
    //

    // it must at the very least consist of a terminator
    if ([data length] < [chunkTerminatorData length]) {
        [NSException raise:MGSNetSocketException format:@"Invalid attachment chunk data size: %lu", (long)[data length]];
    }
    
    // validate that the chunk ends with the terminator
    NSData *dataTerminator = [data subdataWithRange:NSMakeRange([data length] - [chunkTerminatorData length], [chunkTerminatorData length])];
    if (![dataTerminator isEqualToData:chunkTerminatorData]) {
        [NSException raise:MGSNetSocketException format:@"Chunk terminator not found"];
    }
    
    MGSNetMessage *netMessage = [self messageToBeRead];
    
    //
    // validate the transfer encoding
    //
    if (![netMessage.header.attachmentTransferEncoding isEqualToString:MGSNetHeaderAttachmentTransferEncodingChunked]) {
        NSAssert(NO, @"Invalid attachment transfer encoding: %@", netMessage.header.attachmentTransferEncoding);
    }

    //
    // validate the attachment encoding
    //
    NSMutableString *dataString = nil;
    if ([netMessage.header.attachmentEncoding isEqualToString:MGSNetHeaderAttachmentEncodingUTF8]) {

        // data is UTF-8 so we can convert it to a string regardless
        // of whether it is the chunk size or the data.
        // if we start chunking non UTF-8 data then this will need to be modified.
        dataString = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    } else {    
        NSAssert(NO, @"Invalid attachment encoding: %@", netMessage.header.attachmentEncoding);
    }
    
    if (_netRequest.status == kMGSStatusReadingMessageAttachments) {
        
        NSScanner *scanner = nil;
        
        switch (tag) {
            case kMGSSocketReadAttachmentChunkSize:;
                                            
                // get the chunk size
                // scan from hex to decimal
                unsigned length = 0;
                scanner = [NSScanner scannerWithString:dataString];
                [scanner scanHexInt:&length];
                NSUInteger chunkSize = length;
                
                // a zero sized chunk marks the end of the data
                if (chunkSize == 0) {
                    MLogDebug(@"Zero chunk size found");
                }
                
                // we want to read the chunk data + the terminator
                chunkSize += [MGSNetChunkTerminator length];
                
                // read the chunk data up to given length.
                // we timeout the request as a whole not the read.
                [_socket readDataToLength:chunkSize withTimeout:-1 tag:kMGSSocketReadAttachmentChunk];
                
                break;
                
            case kMGSSocketReadAttachmentChunk:;
                
                // get the data string minus the terminator
                [dataString deleteCharactersInRange:NSMakeRange([dataString length] - [MGSNetChunkTerminator length], [MGSNetChunkTerminator length])];
                                                                   
                // a zero sized chunk marks the end of the attachment stream
                if ([dataString length] == 0) {
                    
                     MLogDebug(@"Chunked attachments received");
                    
                    _netRequest.status = kMGSStatusMessageReceived;
                    
                } else {
                    
                    [_netRequest chunkStringReceived:dataString];
                    
                    // read the next chunk size
                    // // we timeout the request as a whole not the read.
                    [_socket readDataToData:chunkTerminatorData withTimeout:-1 tag:kMGSSocketReadAttachmentChunkSize];
                }
                
                break;
                
            default:
                [NSException raise:MGSNetSocketException format:@"Invalid attachment chunked data read tag: %ld", tag];
                break;
                
        }
    } else {
        [NSException raise:MGSNetSocketException format:@"Invalid request status in chunked read: %ld", (long)_netRequest.status];
    }

} 

/*
 
 - readAttachmentIdentityData:withTag: 
 */
- (BOOL)readAttachmentIdentityData:(NSData *)data withTag:(long)tag
{
    #pragma unused(tag)
    
	NSString *error = nil;
	MGSNetAttachment *attachment = nil;
	
	@try {
		MGSNetMessage *netMessage = [self messageToBeRead];
		
        NSAssert([netMessage.header.attachmentTransferEncoding isEqualToString:MGSNetHeaderAttachmentTransferEncodingIdentity], 
                 @"Invalid attachment transfer encoding: %@", netMessage.header.attachmentTransferEncoding);

        NSAssert([netMessage.header.attachmentEncoding isEqualToString:MGSNetHeaderAttachmentEncodingBinary], 
                 @"Invalid attachment encoding: %@", netMessage.header.attachmentEncoding);

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
        // we timeout the request as a whole not the read.
		[_socket readDataToLength:(NSUInteger)readLength withTimeout:-1 tag:kMGSSocketReadAttachmentData];
		
	} 
	@catch (NSException *e) {
		error = [NSString stringWithFormat: @"Exception reading attachment data: %@", e];
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
