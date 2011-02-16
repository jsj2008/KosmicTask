//
//  MGSPowerManagement.h
//  Mother
//
//  Created by Jonathan on 30/09/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <IOKit/pwr_mgt/IOPMLib.h>
#include <IOKit/IOMessage.h>

@interface MGSPowerManagement : NSObject {
	//
	// USE I/O kit notifications
	//
	IONotificationPortRef  _notifyPortRef; // notification port allocated by IORegisterForSystemPower
	io_object_t            _notifierObject; // notifier object, used to deregister later
	void*                  _refCon; // this parameter is passed to the callback

	io_connect_t _rootPort; // a reference to the Root Power Domain IOService;
	void *_callbackMessageArgument;
}

@property void *callbackMessageArgument;

+ (id)sharedController;
- (BOOL)registerForIOKitSleepNotification:(IOServiceInterestCallback)callback;
- (BOOL)registerForIOKitSleepNotification;
- (void)allowPowerChangeNow;
- (void)cancelPowerChange;
@end
