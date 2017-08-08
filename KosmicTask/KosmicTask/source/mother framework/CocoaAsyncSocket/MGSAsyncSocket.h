//
//  MGSAsyncSocket.h
//  Mother
//
//  Created by Jonathan on 05/08/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AsyncSocket.h"

@interface MGSAsyncSocket : AsyncSocket {
	BOOL readSuspended;
	BOOL writeSuspended;
}

@property (assign) BOOL disconnectCalled;

- (void)doSendBytes;
- (void)doBytesAvailable;

- (BOOL)isWriteSuspended;
- (void)setWriteSuspended:(BOOL)newValue;
- (BOOL)isReadSuspended;
- (void)setReadSuspended:(BOOL)newValue;
@end
