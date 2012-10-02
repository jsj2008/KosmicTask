//
//  MGSNumberTransformer.m
//  Mother
//
//  Created by Jonathan on 13/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSNumberTransformer.h"


@implementation MGSNumberTransformer

+ (Class)transformedValueClass 
{ 
	return [NSNumber class]; 
}

+ (BOOL)allowsReverseTransformation 
{ 
	return YES;
}

- (id)transformedValue:(id)value {
	return [NSString stringWithFormat:@"%@", value];   // no formatting required
}

@end
