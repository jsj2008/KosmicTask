//
//  ESSTimeTrialClass.h
//  Cave Canem
//
//  Created by Matthias Gansrigler on 5/12/07.
//  Copyright 2007 Eternal Storms Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ESSTimeTrialClass : NSObject
{
	NSDate *endDate;
	NSString *endMessage;
	NSTimer *timer;
	BOOL timerIsRunning;
}
+ (ESSTimeTrialClass *)timeTrialWithEndDate:(NSDate *)date endMessage:(NSString *)aString;
- (id)initWithEndDate:(NSDate *)date endMessage:(NSString *)aString;
- (void)startTimer;
- (void)endTimer;
- (void)setEndDate:(NSDate *)date;
- (void)setEndMessage:(NSString *)aString;

// Mugginsoft
- (NSDate *)endDate;
//
@end
