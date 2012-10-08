//
//  MGSClientPowerManagement.m
//  Mother
//
//  Created by Jonathan on 02/10/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import "MGSClientPowerManagement.h"
#import "MGSRequestViewManager.h"
#import "MGSClientNetRequest.h"

static void MGSClientSleepCallback( void * refCon, io_service_t service, natural_t messageType, void * messageArgument );

@implementation MGSClientPowerManagement

/*
 
 registerForIOKitSleepNotification
 
 */
- (BOOL)registerForIOKitSleepNotification
{
	return [self registerForIOKitSleepNotification:MGSClientSleepCallback];
}

#pragma mark MGSNetRequestOwner protocol methods

/*
 
 net request response
 
 */
-(void)netRequestResponse:(MGSClientNetRequest *)netRequest payload:(MGSNetRequestPayload *)payload
{
	#pragma unused(netRequest)
	#pragma unused(payload)
	
	if ([[MGSRequestViewManager sharedInstance] processingCount] == 0) {
		
		// now allow the power change
		[self allowPowerChangeNow];
	}
	
}

@end


/*
 
 sleep callback
 
 http://developer.apple.com/mac/library/qa/qa2004/qa1340.html#TNTAG3
 
 */
void MGSClientSleepCallback( void * refCon, io_service_t service, natural_t messageType, void * messageArgument )
{
	#pragma unused(refCon)
	#pragma unused(service)
	
	MGSClientPowerManagement *powerManagement = [MGSClientPowerManagement sharedController];
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
			
			/*
			 
			 cancel sleep if tasks active
			 
			 */
            if ([[MGSRequestViewManager sharedInstance] processingCount] > 0) {
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
			
			// disconnect running actions
            if ([[MGSRequestViewManager sharedInstance] processingCount] > 0) {
				[[MGSRequestViewManager sharedInstance] stopAllRunningActions:powerManagement];
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

