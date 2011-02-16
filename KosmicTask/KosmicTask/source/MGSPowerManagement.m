//
//  MGSPowerManagement.m
//  Mother
//
//  Created by Jonathan on 30/09/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import "MGSPowerManagement.h"
#import "MLog.h"


static MGSPowerManagement *_sharedController = nil;

@interface MGSPowerManagement (Private)
@end

@implementation MGSPowerManagement

@synthesize callbackMessageArgument = _callbackMessageArgument;

/*
 
 shared controller singleton
 
 */
+ (id)sharedController 
{
	@synchronized(self) {
		if (nil == _sharedController) {
			[[self alloc] init];  // assignment occurs below
		}
	}
	return _sharedController;
}

/*
 
 alloc with zone for singleton
 
 */
+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (_sharedController == nil) {
            _sharedController = [super allocWithZone:zone];
            return _sharedController;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
} 

#pragma mark instance methods

/*
 
 copy with zone for singleton
 
 */
- (id)copyWithZone:(NSZone *)zone
{
	#pragma unused(zone)
	
    return self;
}

/*
 
 init
 
 */
- (id)init
{
	if ((self = [super init])) {
		
	}
	
	return self;
}

/*
 
 registerForIOKitSleepNotification
 
 */
- (BOOL)registerForIOKitSleepNotification
{
	return [self registerForIOKitSleepNotification:NULL];
}

/*
 
 register for IO Kit sleep notification
 
 */
- (BOOL)registerForIOKitSleepNotification:(IOServiceInterestCallback) callback
{
	if (callback == NULL) {
		return NO;
	}
	
	// register to receive system sleep notifications
	_rootPort = IORegisterForSystemPower( _refCon, &_notifyPortRef, callback, &_notifierObject );
	if (_rootPort == 0 )
	{
		MLog(RELEASELOG, @"%@", @"IORegisterForSystemPower failed");
		return NO;
	}
	
	// add the notification port to the application runloop
	CFRunLoopAddSource( CFRunLoopGetCurrent(),
					   IONotificationPortGetRunLoopSource(_notifyPortRef), kCFRunLoopCommonModes ); 
	
	return YES;
}

/*
 
 allow power change now
 
 */
- (void)allowPowerChangeNow
{
	// now allow the power change
	IOAllowPowerChange( _rootPort, (long)_callbackMessageArgument );
	
}

/*
 
 cancel power change 
 
 */
- (void)cancelPowerChange
{
	// now cancel the power change
	IOCancelPowerChange( _rootPort, (long)_callbackMessageArgument );
	
}

@end


@implementation MGSPowerManagement (Private)

@end


