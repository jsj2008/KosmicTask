//
//  MGSIntegerTransformer.m
//  Mother
//
//  Created by Jonathan on 16/09/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import "MGSIntegerTransformer.h"


@implementation MGSIntegerTransformer

/*
 
 transformed value class
 
 */
+ (Class)transformedValueClass 
{ 
	return [NSNumber class]; 
}
/*
 
 allows reverse transform
 
 */
+ (BOOL)allowsReverseTransformation 
{ 
	return YES; 
}

/*
 
 transformed value
 
 */
- (id)transformedValue:(id)value {
	NSNumber *integer = nil;
	
	if ([value isKindOfClass:[NSNumber class]]) {
		integer = [NSNumber numberWithInteger:[(NSNumber *)value integerValue]];
	}
	
	if (!integer) {
		integer = [NSNumber numberWithInteger:0];
	}
	return integer;
}

@end
