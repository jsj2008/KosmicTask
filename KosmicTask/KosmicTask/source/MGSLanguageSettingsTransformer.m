//
//  MGSLanguageSettingsTransformer.m
//  KosmicTask
//
//  Created by Jonathan on 26/10/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSLanguageSettingsTransformer.h"


@implementation MGSLanguageSettingsTransformer

/*
 
 + transformedValueClass
 
 */
+ (Class)transformedValueClass 
{ 
	return [NSString class]; 
}

/*
 
 + allowsReverseTransformation
 
 */
+ (BOOL)allowsReverseTransformation 
{ 
	return YES; 
}

/*
 
 - transformedValue:
 
 */
- (id)transformedValue:(id)value {
	NSMutableString *newValue = [NSMutableString new];

	if ([value isKindOfClass:[NSString class]]) {
		return value;
	}
	
	if ([value isKindOfClass:[NSArray class]]) {
		for (id item in value) {
			[newValue appendFormat:@"%@ ", [item description]];
		}
		
		return newValue;
	}
	
	return [value description];
}

/*
 
 - reverseTransformedValue:
 
 */
- (id)reverseTransformedValue:(id)value
{
	return value;
}
@end
