//
//  MGSRequestViewManager.h
//  Mother
//
//  Created by Jonathan on 24/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MGSRequestViewController;

@interface MGSRequestViewManager : NSObject {
	NSMutableArray *_controllers;
}

+ (id)sharedInstance;
- (MGSRequestViewController *)newController;
- (NSInteger)processingCount;
- (NSInteger)processingCountInWindow:(NSWindow *)window;
- (NSInteger)stopAllRunningActions:(id)owner;
- (NSInteger)disconnectAllRunningActions:(id)owner;

@end
