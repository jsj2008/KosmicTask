//
//  MGSRequestViewManager.m
//  Mother
//
//
//  A collection of all the currently allocated request view controllers.
//
//  Created by Jonathan on 24/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSRequestViewManager.h"
#import "MGSRequestViewController.h"
#import "MGSTaskSpecifier.h"

static MGSRequestViewManager *_sharedInstance = nil;

@implementation MGSRequestViewManager

/*
 
 shared controller singleton
 
 */
+ (id)sharedInstance
{
	if (!_sharedInstance) {
		(void)[[self alloc] init];	// assign in allocWithZone
	}
	return _sharedInstance;
}

/*
 
 alloc with zone
 
 */
+ (id)allocWithZone:(NSZone *)zone
{
	if (_sharedInstance == nil) {
		_sharedInstance = [super allocWithZone:zone];
		return _sharedInstance;  // assignment and return on first allocation
	}
	
    return nil; //on subsequent allocation attempts return nil
}

/*
 
 copy with zone
 
 */
- (id)copyWithZone:(NSZone *)zone
{
	#pragma unused(zone)
	
    return self;
}

/*
 
 init
 
 */
- (id) init
{
	if ((self = [super init])) {
		_controllers = [NSMutableArray arrayWithCapacity:2];
		
	}
	return self;
}

/*
 
 new object in array
 
 */
- (MGSRequestViewController *)newController
{
	MGSRequestViewController *controller = [[MGSRequestViewController alloc] init];
	[_controllers addObject:controller];	// add to array
	
	return controller;
}

/*
 
 remove object
 
 */
- (void)removeObject:(MGSRequestViewController *)controller
{
    // remove from our collection
	[_controllers removeObject:controller];
    
    // call dispose
    [controller dispose];
}

/*
 
 number of processing views
 
 */
- (NSInteger)processingCount
{
	NSInteger count = 0;
	
	for (MGSRequestViewController *controller in _controllers) {
		if ([controller.actionSpecifier isProcessing]) count++;
	}
	
	return count;
}

/*
 
 number of processing views in window
 
 */
- (NSInteger)processingCountInWindow:(NSWindow *)window
{
	NSInteger count = 0;
	
	for (MGSRequestViewController *controller in _controllers) {
		
		if ([[controller view] window] == window && [controller.actionSpecifier isProcessing]) count++;
	}
	
	return count;
}

/*
 
 stop all running actions
 
 */
- (NSInteger)stopAllRunningActions:(id)owner
{
	NSInteger count = 0;
	
	for (MGSRequestViewController *controller in _controllers) {
		if ([controller.actionSpecifier isProcessing]) {
			[controller.actionSpecifier terminate:owner];
			count++;
		}
	}
	
	return count;
}

/*
 
 disconnect all running actions
 
 */
- (NSInteger)disconnectAllRunningActions:(id)owner
{
	#pragma unused(owner)
	
	NSInteger count = 0;
	
	for (MGSRequestViewController *controller in _controllers) {
		if ([controller.actionSpecifier isProcessing]) {
			[controller.actionSpecifier disconnect];
			count++;
		}
	}
	
	return count;
}
@end
