//
//  ESSTimeTrialClass.m
//  Cave Canem
//
//  Created by Matthias Gansrigler on 5/12/07.
//  Copyright 2007 Eternal Storms Software. All rights reserved.
//

#import "ESSTimeTrialClass.h"

static ESSTimeTrialClass *myClass = nil;

// class extension
@interface ESSTimeTrialClass()
- (void)quit:(NSTimer *)aTimer;
@end

@implementation ESSTimeTrialClass

+ (ESSTimeTrialClass *)timeTrialWithEndDate:(NSDate *)date endMessage:(NSString *)aString
{
	if (date && aString)
	{
		if (!myClass)
		{
			myClass = [[ESSTimeTrialClass alloc] initWithEndDate:date endMessage:aString];
		}
		return myClass;
	}
	return nil;
}

- (id)initWithEndDate:(NSDate *)date endMessage:(NSString *)aString
{
	if (date && aString)
	{
		if ((self = [super init]))
		{
			[self setEndDate:date];
			[self setEndMessage:aString];
			timerIsRunning = NO;
			[self startTimer];
			return self;
		}
	}
	return nil;
}

- (void)setEndDate:(NSDate *)date
{
	[endDate release];
	endDate = [date retain];
}

- (void)setEndMessage:(NSString *)aString
{
	aString = [aString copy];
	[endMessage release];
	endMessage = aString;
}

- (void)startTimer
{
	if (![[[NSDate date] laterDate:endDate] isEqualToDate:endDate])
	{
		NSRunAlertPanel(@"This Software has expired",endMessage,@"OK",nil,nil);
		[NSApp terminate:nil];
	} else
	{
		if (!timerIsRunning)
		{
			timer = [[NSTimer scheduledTimerWithTimeInterval:[endDate timeIntervalSinceNow] target:self selector:@selector(quit:) userInfo:nil repeats:NO] retain];
			timerIsRunning = YES;
		}
	}
}

- (void)endTimer
{
	if (timerIsRunning)
	{
		[timer invalidate];
		[timer release];
		timer = nil;
		timerIsRunning = NO;
	}
}

- (void)quit:(NSTimer *)aTimer
{
	#pragma unused(aTimer)
	
	NSRunAlertPanel(@"This Software has expired",endMessage,@"OK",nil,nil);
	[NSApp terminate:nil];
}
// Mugginsoft 

- (NSDate *)endDate
{
	return endDate;
}

#ifdef __OBJC_GC__

- (void) finalize
{
	if (timerIsRunning)
	{
		[timer invalidate];
		timer = nil;
	}
	[super finalize];
}

#else

- (void)dealloc
{
	//NSLog(@"aha");
	[endMessage release];
	[endDate release];
	if (timerIsRunning)
	{
		[timer invalidate];
		[timer release];
	}
	[super dealloc];
}

#endif
// Mugginsoft 

@end
