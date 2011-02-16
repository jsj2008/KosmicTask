//
//  MGSResultFormat.m
//  KosmicTask
//
//  Created by Jonathan on 04/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSResultFormat.h"

NSString *resultHeader = @"kosmic";

@implementation MGSResultFormat

/*
 
 + formatResultKey
 
 */
+ (NSString *)formatResultKey:(NSString *)key
{
	key = [key lowercaseString];
	NSRange range = [key rangeOfString:resultHeader];
	if (range.location != NSNotFound) {
		NSString *body = [key substringFromIndex:range.length];
		key = [resultHeader stringByAppendingString:[body capitalizedString]];
	}
	
	return key;
}
/*
 
 + fileDataKeys
 
 */
+ (NSArray *)fileDataKeys
{
	return [NSArray arrayWithObjects: @"kosmictask", @"kosmicfile", @"kosmicfiles", nil];
}

/*
 
 + dataKeys
 
 */
+ (NSArray *)dataKeys
{
	return [NSArray arrayWithObjects: @"kosmicdata", nil];
}

/*
 
 + errorKeys
 
 */
+ (NSArray *)errorKeys
{
	return [NSArray arrayWithObjects: @"kosmicerror", nil];
}

/*
 
 + infoKeys
 
 */
+ (NSArray *)infoKeys
{
	return [NSArray arrayWithObjects: @"kosmicinfo", nil];
}

/*
 
 + inlineStyleKeys
 
 */
+ (NSArray *)inlineStyleKeys
{
	return [NSArray arrayWithObjects: @"kosmicstyle", nil];
}
/*
 
 + styleNameKeys
 
 */
+ (NSArray *)styleNameKeys
{
	return [NSArray arrayWithObjects: @"kosmicstylename", nil];
}
/*
 
 + styleNamesKeys
 
 */
+ (NSArray *)styleNamesKeys
{
	return [NSArray arrayWithObjects: @"kosmicstylenames", nil];
}

/*
 
 + dictStyleFilterKeys
 
*/
+ (NSArray *)dictStyleFilterKeys
{
	// dictionary objects with matching keys will be removed from styled output
	NSMutableArray *filter = [NSMutableArray arrayWithArray:[self fileDataKeys]];
	[filter addObjectsFromArray:[self styleNameKeys]];
	[filter addObjectsFromArray:[self inlineStyleKeys]];
	[filter addObjectsFromArray:[self styleNamesKeys]];
	
	return filter;
}
/*
 
 + dictKeyStyleFilterKeys
 
 */
+ (NSArray *)dictKeyStyleFilterKeys
{
	// dictionary objects with matching keys will have key only removed from styled output
	NSMutableArray *filter = [NSMutableArray arrayWithArray:[self dataKeys]];
	[filter addObjectsFromArray:[self errorKeys]];
	[filter addObjectsFromArray:[self infoKeys]];
	
	return filter;
}

@end
