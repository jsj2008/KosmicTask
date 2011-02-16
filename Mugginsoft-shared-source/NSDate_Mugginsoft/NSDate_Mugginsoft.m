//
//  NSDate_Mugginsoft.m
//  KosmicQuitter
//
//  Created by Jonathan on 20/03/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import "NSDate_Mugginsoft.h"


@implementation NSDate (Mugginsoft)

+ (BOOL)isADayEqualToAnotherDay:(NSDate*)date anotherDate:(NSDate*)anotherDate
{
	NSCalendar *cal;
	NSDateComponents *componentsFromDate, *componentsFromAnotherDate;
	NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |
	NSDayCalendarUnit;
	
	cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	
	componentsFromDate = [cal components:unitFlags fromDate:date];
	componentsFromAnotherDate = [cal components:unitFlags fromDate:anotherDate];
	
	return (
			[componentsFromDate year] == [componentsFromAnotherDate year] &&
			[componentsFromDate month] == [componentsFromAnotherDate month] &&
			[componentsFromDate day] == [componentsFromAnotherDate day]
			);
}

+ (NSDate *)timeWithInterval:(NSInteger)timeInterval
{
	NSDateComponents *comps = [[NSDateComponents alloc] init];
	NSCalendar *cal = [[[NSCalendar alloc]
						initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSDate *result;
	
	[comps setHour:(timeInterval / 3600)];
	[comps setMinute:(timeInterval / 60) - ((timeInterval / 3600) * 60)];
	[comps setSecond:(timeInterval % 60)];
	
	result = [cal dateFromComponents:comps];
	
	[comps release];
	
	return result;
}@end
