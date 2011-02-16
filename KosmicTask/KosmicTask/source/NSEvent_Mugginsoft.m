//
//  NSEvent_Mugginsoft.m
//  KosmicTask
//
//  Created by Jonathan on 07/01/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "NSEvent_Mugginsoft.h"
#import <mach/mach.h>
#import <mach/clock.h>

@implementation NSEvent(Mugginsoft)

/*
 
 timestamp
 
 */
+ (NSTimeInterval)timestamp
{
	// see http://boredzo.org/blog/archives/2006-11-26/how-to-use-mach-clocks
	
	// get clock right
	clock_serv_t host_clock;
	kern_return_t status = host_get_clock_service(mach_host_self(), SYSTEM_CLOCK, &host_clock);
	if (!status) {
		return 0.f;
	}
	
	// get time
	mach_timespec_t now;
	clock_get_time(host_clock, &now);
	
	return (NSTimeInterval)now.tv_sec + ((NSTimeInterval)now.tv_nsec)/1000000000.0f;
}
@end
