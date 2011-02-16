//
//  MGSTimeIntervalTransformer.m
//  Mother
//
//  Created by Jonathan on 05/02/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSTimeIntervalTransformer.h"


@implementation MGSTimeIntervalTransformer

@synthesize resolution = _resolution;
@synthesize prefix = _prefix;
@synthesize style = _style;
@synthesize returnAttributedString = _returnAttributedString;

/*
 
 transformed class
 
 */
+ (Class)transformedValueClass 
{ 
	return [NSNumber class]; 
}

/*
 
 allows reverse transformtion
 
 */
+ (BOOL)allowsReverseTransformation 
{ 
	return NO; 
}

/*
 
 null time interval
 
 */ 
+ (NSTimeInterval)nullTimeInterval
{
	return -9999999; 
}

/*
 
 null time string
 
 transformed string value of +nullTimeInterval
 
 */
+ (NSString *)nullTimeString
{
	return @"";
}
/*
 
 time interval with resolution
 
 */
+ (NSTimeInterval)timeInterval:(NSTimeInterval)interval withResolution:(MGSTimeIntervalResolution)resolution
{
	if (interval <= 0) return interval;
	
	double modulus;
	double frx = modf(interval, &modulus);
	NSInteger imsecs = (int)(round(frx * 1000));
	double msecs = (double)imsecs;
	
	switch (resolution) {
		// 1 msec resolution
		case MGSTime1msec:
			break;
			
		// 10 msec resolution
		case MGSTime10msec:
			msecs /= 10;
			msecs = round(msecs);
			msecs *= 10;
			break;
			
		// 100 msec resolution
		case MGSTime100msec:
			msecs /= 100;
			msecs = round(msecs);
			msecs *= 100;
			break;
			
		// second resolution
		case MGSTimeSecond:
			default:
			return round(interval);
			break;
	}
	
	return modulus + msecs/1000;
}


/*
 
 init
 
 */
- (id)init
{
	if ([super init]) {
		_resolution = MGSTimeSecond;
		_prefix = nil;
		_style = MGSTimeStyleNumeric;
		_returnAttributedString = YES;
	}
	return self;
}

/*
 
 transformed value
 
 */
- (id)transformedValue:(id)valueToBeTransFormed {

	NSString *defaultNumericTimeIntervalString = nil;
	NSString *defaultTextualTimeIntervalString = nil;
	NSString *format = nil;
	BOOL hasMsecs = YES;
    
	// get format strings
	switch (_resolution) {
			
		// 1 msec resolution
		case MGSTime1msec:
			defaultNumericTimeIntervalString = @"00:00.000";
			defaultTextualTimeIntervalString = @"0.000 sec";
			break;
			
		// 10 msec resolution
		case MGSTime10msec:
			defaultNumericTimeIntervalString =  @"00:00.00";
			defaultTextualTimeIntervalString = @"0.00 sec";
			break;
			
		// 100 msec resolution
		case MGSTime100msec:
			defaultNumericTimeIntervalString =  @"00:00.0";
			defaultTextualTimeIntervalString = @"0.0 sec";
			break;
		
		// second resolution
		case MGSTimeSecond:
		default:
			defaultNumericTimeIntervalString =  @"00:00";
			defaultTextualTimeIntervalString = @"0 sec";
			hasMsecs = NO;
			break;
	}

	// get our time interval
	NSTimeInterval timeInterval = 0;
	if ([valueToBeTransFormed isKindOfClass:[NSNumber class]]) {
		timeInterval = [valueToBeTransFormed doubleValue];
	} else {
		valueToBeTransFormed = nil;
	}
	
	// if no valid value or interval is zero then return default
	if (!valueToBeTransFormed || (NSInteger)timeInterval == 0) {
		return self.style == MGSTimeStyleNumeric ? defaultNumericTimeIntervalString : defaultTextualTimeIntervalString;
	}
	
	// if a null time interval is defined then return an empty string
	if ((NSInteger)timeInterval == (NSInteger)[[self class] nullTimeInterval]) {
		return [[self class] nullTimeString];
	}
		
	// perform time dissection of NSTimeInterval
	if (0 > timeInterval) timeInterval = 0;
	
	// adjust resolution
	timeInterval = [[self class] timeInterval:timeInterval withResolution: _resolution];
	
	// split into modulus and fractional part.
	// fraction part is milliseconds
	// it would have been better to use NSDecimalNumber here rather than all this
	double modulus;
	double frx = modf(timeInterval, &modulus);
	frx *= 1000.0;
	frx = round(frx);	// ms rounding errors were occurring here, hence the round
	NSUInteger msecs = (NSUInteger)frx;

	// compute h, m, s
	NSUInteger seconds = (int)modulus;
	NSUInteger hour = seconds / 3600;
	seconds %= 3600;
	NSUInteger min = seconds/60;
	seconds %= 60;
	
	// prepare formatted string
	switch (_resolution) {

		// 1 msec resolution
		case MGSTime1msec:
			if (0 == hour) {
				format = self.style == MGSTimeStyleNumeric ? [NSString stringWithFormat:@"%02u:%02u.%03u", min, seconds, msecs] : [NSString stringWithFormat:@"%u m %u.%03u sec", min, seconds, msecs];
			} else {
				format = self.style == MGSTimeStyleNumeric ? [NSString stringWithFormat:@"%02u:%02u:%02u.%03u", hour, min, seconds, msecs] : [NSString stringWithFormat:@"%u h %u m %u.%03u sec", hour, min, seconds, msecs];
			}			
			break;
			
		// 10 msec resolution
		case MGSTime10msec:
			msecs /= 10;
			if (0 == hour) {
				if (0 == min) {
					format = self.style == MGSTimeStyleNumeric ? [NSString stringWithFormat:@"%02u:%02u.%02u", min, seconds, msecs] : [NSString stringWithFormat:@"%u.%02u sec", seconds, msecs];
				} else {
					format = self.style == MGSTimeStyleNumeric ? [NSString stringWithFormat:@"%02u:%02u.%02u", min, seconds, msecs] : [NSString stringWithFormat:@"%u m %u.%02u sec", min, seconds, msecs];
				}
			} else {
				format = self.style == MGSTimeStyleNumeric ? [NSString stringWithFormat:@"%02u:%02u:%02u.%02u", hour, min, seconds, msecs] : [NSString stringWithFormat:@"%u h %u m %u.%02u sec", hour, min, seconds, msecs];
			}
			break;
			
		// 100 msec resolution
		case MGSTime100msec:
			msecs /= 100;
			if (0 == hour) {
				format = [NSString stringWithFormat:@"%02u:%02u.%01u", min, seconds, msecs];
			} else {
				format = [NSString stringWithFormat:@"%02u:%02u:%02u.%01u", hour, min, seconds, msecs];
				
			}			
			break;
			
		// second resolution
		case MGSTimeSecond:
		default:
			if (0 == hour) {
				if (0 == min) {
					format = self.style == MGSTimeStyleNumeric ? [NSString stringWithFormat:@"%02u:%02u", min, seconds] : [NSString stringWithFormat:@"%u sec", seconds];
				} else {
					format = self.style == MGSTimeStyleNumeric ? [NSString stringWithFormat:@"%02u:%02u", min, seconds] : [NSString stringWithFormat:@"%u m %u sec", min, seconds];
				}
			} else {
				format = self.style == MGSTimeStyleNumeric ? [NSString stringWithFormat:@"%02u:%02u:%02u", hour, min, seconds] : [NSString stringWithFormat:@"%u h %u m %u sec", hour, min, seconds, msecs];

				
			}
			break;
	}
	
	// return time string
	if (hasMsecs) {
		
		// attributed font drawing not as clean as it could be
		
		if (self.returnAttributedString) {
			
			// font name for string
			//NSFont *font = [NSFont fontWithName:@"Lucida Grande" size:11.0];
			NSFont *font = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
			NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:font,  NSFontAttributeName
											, nil];
			
			NSMutableAttributedString *timeString = [[NSMutableAttributedString alloc] initWithString:format attributes:attrsDictionary];
			NSRange range = [[timeString string] rangeOfString:@"."];
			range.location++;
			range.length = [[timeString string] length] - range.location;
			
			// modify attributes
			[timeString beginEditing];
			[timeString addAttribute:NSForegroundColorAttributeName
						   value:[NSColor grayColor]
						   range:range];
			NSRange rangeAll;
			rangeAll.location = 0;
			rangeAll.length = [[timeString string] length];
			[timeString applyFontTraits:NSUnboldFontMask range:rangeAll];
			[timeString setAlignment:NSRightTextAlignment range:rangeAll];
			[timeString endEditing];
			
			return timeString;
		} else {
			
			return format;
		}
	} else {
		
		if (_prefix) {
			format = [_prefix stringByAppendingString:format];
		}
		return format;
	}
}
@end
