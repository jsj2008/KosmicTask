//
//  NSObject_Mugginsoft.m
//  Mother
//
//  Created by Jonathan on 28/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "NSObject_Mugginsoft.h"


@implementation NSObject (Mugginsoft)

- (BOOL)boolValue
{
	if ([self isKindOfClass:[NSString class]]) {
		return [(NSString *)self isEqualToString:@"YES"];
	}
	
	if ([self isKindOfClass:[NSNumber class]]) {
		return [(NSNumber *)self boolValue];
	}
	
	return NO;
}
@end
