//
//  MGSServerPowerManagement.m
//  Mother
//
//  Created by Jonathan on 02/10/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import "MGSServerPowerManagement.h"
#import "MGSServerRequestManager.h"

static void MGSServerSleepCallback( void * refCon, io_service_t service, natural_t messageType, void * messageArgument );

@implementation MGSServerPowerManagement

/*
 
 registerForIOKitSleepNotification
 
 */
- (BOOL)registerForIOKitSleepNotification
{
	return [self registerForIOKitSleepNotification:MGSServerSleepCallback];
}

@end


/*
 
 sleep callback
 
 http://developer.apple.com/mac/library/qa/qa2004/qa1340.html#TNTAG3
 
 */
void MGSServerSleepCallback( void * refCon, io_service_t service, natural_t messageType, void * messageArgument )
{
	#pragma unused(refCon)
	#pragma unused(service)
	
	MGSServerPowerManagement *powerManagement = [MGSServerPowerManagement sharedController];
	powerManagement.callbackMessageArgument = messageArgument;
	
	switch ( messageType )
    {
			
        case kIOMessageCanSystemSleep:
            /* Idle sleep is about to kick in. This message will not be sent for forced sleep.
			 Applications have a chance to prevent sleep by calling IOCancelPowerChange.
			 Most applications should not prevent idle sleep.
			 
			 Power Management waits up to 30 seconds for you to either allow or deny idle sleep.
			 If you don't acknowledge this power change by calling either IOAllowPowerChange
			 or IOCancelPowerChange, the system will wait 30 seconds then go to sleep.
			 */
			// cancel power change if tasks active
			if ([[MGSServerRequestManager sharedController] requestCount] > 0) {
				[powerManagement cancelPowerChange];
				break;
			}
			
			// fall through
			
        case kIOMessageSystemWillSleep:
            /* The system WILL go to sleep. If you do not call IOAllowPowerChange or
			 IOCancelPowerChange to acknowledge this message, sleep will be
			 delayed by 30 seconds.
			 
			 NOTE: If you call IOCancelPowerChange to deny sleep it returns kIOReturnSuccess,
			 however the system WILL still go to sleep. 
			 */
			// disconnect requests
			if ([[MGSServerRequestManager sharedController] requestCount] > 0) {
				
				// disconnect all requests.
				// disconnected requests always ensure that any task associated with them is terminated
				[[MGSServerRequestManager sharedController] disconnectAllRequests];
				[powerManagement performSelector:@selector(allowPowerChangeNow) withObject:nil afterDelay:2.0];
			} else {
				[powerManagement allowPowerChangeNow];
			}
			break;
			
        case kIOMessageSystemWillPowerOn:
            //System has started the wake up process...
            break;
			
        case kIOMessageSystemHasPoweredOn:
            //System has finished waking up...
			break;
			
        default:
            break;
			
    }
}

