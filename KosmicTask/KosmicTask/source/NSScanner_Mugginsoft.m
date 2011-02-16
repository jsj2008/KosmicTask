//
//  NSScanner_Mugginsoft.m
//  Mother
//
//  Created by Jonathan on 05/08/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "NSScanner_Mugginsoft.h"


@implementation NSScanner (Mugginsoft)

/*
 
 scan up to and over string
 
 */
- (BOOL)scanUpToStringAndOver:(NSString *)aString
{
	[self scanUpToString:aString intoString:NULL];
	if ([self isAtEnd]) return NO;	// if scan to end then string not found
	if (![self scanString:aString intoString:NULL]) return NO;	
	
	// current loaction is end of aString
	return YES;
}
@end
