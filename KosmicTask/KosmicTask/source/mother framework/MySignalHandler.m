/*
 *  MySignalHandler.m
 *
 *  Created by John Clayton on 11/23/04.
 *  @copyright 2004 Fivesquare Software, LLC. All rights reserved.
 *  Redistribution and use in source and binary forms, with or without modification, 
 *  are permitted provided that the following conditions are met:
 *  	-   Redistributions of source code must retain the above copyright notice, 
 *  	    this list of conditions and the following disclaimer.
 *  	-   Redistributions in binary form must reproduce the above copyright notice, 
 *  	    this list of conditions and the following disclaimer in the documentation 
 *  	    and/or other materials provided with the distribution.
 *  	-   Neither the name of Fivesquare Software, LLC nor the names of its contributors 
 *  	    may be used to endorse or promote products derived from this software 
 *  	    without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 *  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
 *  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
 *  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 *  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 *  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 *  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 *  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
 *  THE POSSIBILITY OF SUCH DAMAGE.
 **/

/**
 * This is my adaptation of a similar class posted on CocoaDev by MLester, called
 * MSignalRunLoopSource.  I just moved the CoreFoundation stuff into Cocoa mostly.
 **/

#import "MySignalHandler.h"

NSString *MySignalNotification = @"MySignalNotification";

#import <mach/mach.h>

static mach_msg_header_t machMessageHeader;
static MySignalHandler *handler;

void _signalHandler(int sig) 
{
    mach_msg_return_t retCode = 0;
    
    machMessageHeader.msgh_id = sig;
    retCode = mach_msg_send(&machMessageHeader);
    if (retCode != 0) {
        NSLog(@"mach_msg_send failed in signal handler!");
    }
}

@implementation MySignalHandler

+ (void) installSignalHandler {

    handler = [[MySignalHandler alloc] init]; //leaks on purpose
    
    signal(SIGINT, _signalHandler);
    signal(SIGTERM, _signalHandler);
}


- (id) init {
    if((self = [super init])) {

        NSMachPort *receivePort = [[NSMachPort alloc] init];
        [receivePort setDelegate:self];
        [receivePort scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        // Construct the Mach message to be sent from
        // the signal handler function
        bzero(&machMessageHeader,sizeof(machMessageHeader));
        machMessageHeader.msgh_bits = MACH_MSGH_BITS(MACH_MSG_TYPE_COPY_SEND, 0);
        machMessageHeader.msgh_size = sizeof(machMessageHeader);
        machMessageHeader.msgh_remote_port = [receivePort machPort];
        machMessageHeader.msgh_local_port = MACH_PORT_NULL;
        machMessageHeader.msgh_id = 0;
        
    }
    return self;
}

/*
 
 handle mach message
 
 */
- (void) handleMachMessage:(void *)machMessage {
    mach_msg_header_t *msg = machMessage;
    int signo = msg->msgh_id;
    
#pragma mark warning if server is multi threaded where will this notification go?
    [[NSNotificationCenter defaultCenter] 
        postNotificationName:MySignalNotification
                      object:[NSNumber numberWithInt:signo]];
}


@end
