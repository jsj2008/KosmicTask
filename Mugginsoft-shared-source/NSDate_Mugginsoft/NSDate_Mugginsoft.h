//
//  NSDate_Mugginsoft.h
//  KosmicQuitter
//
//  Created by Jonathan on 20/03/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSDate (Mugginsoft)

+ (BOOL)isADayEqualToAnotherDay:(NSDate*)date anotherDate:(NSDate*)anotherDate;
+ (NSDate *)timeWithInterval:(NSInteger)timeInterval;

@end
