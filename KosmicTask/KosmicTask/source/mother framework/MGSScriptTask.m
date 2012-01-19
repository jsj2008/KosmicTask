//
//  MGSScriptTask.m
//  Mother
//
//  Created by Jonathan Mitchell on 29/12/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import "MGSScriptTask.h"
#import "MGSNetRequest.h"
#import "MGSNetMessage.h"
#import "MGSNetHeader.h"
#import "MLog.h"

// class extension
@interface MGSScriptTask() 
- (void)sendErrorDataChunk;
@end

@implementation MGSScriptTask 

@synthesize netRequest = _netRequest;
@synthesize logRequest = _logRequest;
/*
 
 init
 
 */
- (MGSScriptTask *)init
{
	return [self initWithNetRequest:nil];
}

/*
 
 init with net request
 
 */
- (MGSScriptTask *)initWithNetRequest:(MGSNetRequest *)netRequest
{
	if ((self = [super init])) {
		NSAssert(netRequest, @"net request is nil");
		_netRequest = netRequest;
	}
	return self;
}

/*
 
 finalize
 
 */
- (void) finalize
{
	MLog(DEBUGLOG, @"finalized");
	[super finalize];
}

/*
 
 - setLogRequest:
 
 */
- (void)setLogRequest:(MGSNetRequest *)request
{
    _logRequest = request;
    
    // register the log request as a child of the task request
    [self.netRequest addChildRequest:request];
    
    // our response will send the log as chunked attachment data
    [self.logRequest.responseMessage.header setAttachmentTransferEncoding:MGSNetHeaderAttachmentTransferEncodingChunked];
}

/*
 
 - fileHandleErrorDataAvailable:
 
 */
- (void)fileHandleErrorDataAvailable:(NSNotification*)notification
{
    // The super implementation appends the available error data
    // into taskErrorData
    [super fileHandleErrorDataAvailable:notification];
    
    // if we have a log request active then we want to write the
    // available error data as part of the log response.
    if (self.logRequest) {
        [self sendErrorDataChunk];
    }
}

/*
 
 - sendErrorDataChunk
 
 */
- (void)sendErrorDataChunk
{
    // get the error data
    NSMutableData *data = self.taskErrorData;
    if ([data length] > 0) {
        
        // We send the log as plain text with no defined content length header.
        // The client will simply continue to read the log until we close the socket.
        // write the log content
        [self.logRequest sendResponseChunkOnSocket:[data copy]];
        
        // we don't want to send the data again so clear the buffer
        [self.taskErrorData setLength:0];
    }
}
/*
 
 - readErrorPipeToEndOfFile
 
 */
- (void)readErrorPipeToEndOfFile
{
    [super readErrorPipeToEndOfFile];
    
    // if a logging request is active then we need to write
    // any error data followed by an empty data object
    // to indicate the end of the chunked response
    if (self.logRequest) {
        
        // send any remaining error data
        [self sendErrorDataChunk];
        
        // send an empty data chunk
        [self.logRequest sendResponseChunkOnSocket:[NSData new]];
    }
}
@end
