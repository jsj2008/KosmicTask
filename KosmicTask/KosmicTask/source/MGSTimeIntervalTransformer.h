//
//  MGSTimeIntervalTransformer.h
//  Mother
//
//  Created by Jonathan on 05/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum _MGSTimeIntervalResolution {
	MGSTimeSecond = 0,
	MGSTime100msec,
	MGSTime10msec,
	MGSTime1msec,
};
typedef NSInteger MGSTimeIntervalResolution;

enum _MGSTimeIntervalStyle {
	MGSTimeStyleNumeric = 0,
	MGSTimeStyleTextual = 1
};
typedef NSInteger MGSTimeIntervalStyle;

@interface MGSTimeIntervalTransformer : NSValueTransformer {
	MGSTimeIntervalResolution _resolution;
	NSString *_prefix;
	MGSTimeIntervalStyle _style;
	BOOL _returnAttributedString;
}

@property MGSTimeIntervalResolution resolution;
@property (copy) NSString *prefix;
@property MGSTimeIntervalStyle style;
@property BOOL returnAttributedString;

+ (NSTimeInterval)nullTimeInterval;
+ (NSTimeInterval)timeInterval:(NSTimeInterval)interval withResolution:(MGSTimeIntervalResolution)resolution;
+ (NSString *)nullTimeString;
@end
