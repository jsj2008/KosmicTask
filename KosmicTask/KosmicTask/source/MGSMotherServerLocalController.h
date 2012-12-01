//
//  MGSMotherServerLocalController.h
//  Mother
//
//  Created by Jonathan on 11/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *MGSKosmicTaskAgentName;

@interface MGSMotherServerLocalController : NSObject {
	NSTask *_serverTask;
	NSTimer *_timer;
    NSThread *_serverThread;
    BOOL _runAsProcess;
}

- (BOOL)launch;
- (void)kill;
- (BOOL)launchIfNotRunning;
@property BOOL runAsProcess;

@end
