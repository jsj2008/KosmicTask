//
//  NSObject_Mugginsoft.m
//  Mother
//
//  Created by Jonathan on 28/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "NSObject_Mugginsoft.h"
#import "NSString_Mugginsoft.h"
#import "NSArray_Mugginsoft.h"
#import <objc/runtime.h>

@implementation NSObject (Mugginsoft)

/*
 
 description with depth string
 
 */
- (NSString *)descriptionWithDepthString:(NSString *)depthString
{
	return [self descriptionWithDepth:0 depthString:depthString];
}

/*
 
 description with depth
 
 like description except supports depthStringPrefix
 
 */
- (NSString *)descriptionWithDepth:(NSUInteger)depth depthString:(NSString *)depthString
{

	// for the depth string prefix
	NSMutableString *depthPrefix = [NSMutableString stringWithCapacity:[depthString length] * depth];
	for (NSUInteger i = 0; i < depth; i++) {
		[depthPrefix appendString:depthString];
	}
	
	NSMutableString *mString = [NSMutableString stringWithCapacity:50];
	
	// array
	if ([self isKindOfClass:[NSArray class]]) {
		for (id item in (NSArray *)self) {
			[mString appendString:[item descriptionWithDepth:depth + 1 depthString:depthString]];
		}
	}
	
	// dictionary
	else if ([self isKindOfClass:[NSDictionary class]]) {
		for (id key in [(NSDictionary *)self allKeys]) {
			
			// key description at depth
			NSString *keyDesc = [key descriptionWithDepth:depth + 1 depthString:depthString];

			// if object is array or dict then accept new line and increase depth
			id objectForKey = [(NSDictionary *)self objectForKey:key]; 
			NSUInteger objectDepth = 0; 
			if ([objectForKey isKindOfClass:[NSArray class]] || [objectForKey isKindOfClass:[NSDictionary class]]) {
				objectDepth = depth + 2;
			} else {
				
				// strip newline from keydesc
				keyDesc = [keyDesc mgs_stringWithOccurrencesOfCrLfRemoved];
				
				// set depth relative to key
				objectDepth = 1;
			}
																
			NSString *valueDesc = [objectForKey descriptionWithDepth:objectDepth depthString:depthString];
			[mString appendString:keyDesc];
			[mString appendString:valueDesc];
		}
	}
	
	// default 
	else  {
		[mString appendFormat:@"%@%@", depthPrefix, [self description]];
	}
	
	[mString appendString:@"\n"];
	
	return mString;
}

/*
 
 - mgs_attributedDescriptionWithStyle
 
 returns an attributed description with a particular style 
 
 */
- (NSAttributedString *)mgs_attributedDescriptionWithStyle:(NSDictionary *)inputStyleDict
{
	MGSObjectStyler *styler = [MGSObjectStyler stylerWithObject:self];
	return [styler descriptionWithStyle:inputStyleDict];
}

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

/*
 
 a string representation
 
 */
- (NSString *)aStringRepresentation
{
	NSString *stringRep = @"object: no string rep";
	
	if ([self isKindOfClass:[NSString class]]) {
		stringRep = (NSString *)self;
	} else if ([self respondsToSelector:@selector(stringValue)]) {
		stringRep = [self performSelector:@selector(stringValue)];
	} else if ([self respondsToSelector:@selector(description)]) {
		stringRep = [self performSelector:@selector(description)];
	} 
	
	return stringRep;
}

/*
 
 - mgs_associateValue
 
 */
- (void)mgs_associateValue:(id)value withKey:(void *)key
{
	objc_setAssociatedObject(self, key, value, OBJC_ASSOCIATION_RETAIN);
}

/*
 
 - mgs_weaklyAssociateValue
 
 */
- (void)mgs_weaklyAssociateValue:(id)value withKey:(void *)key
{
	objc_setAssociatedObject(self, key, value, OBJC_ASSOCIATION_ASSIGN);
}

/*
 
 - mgs_associatedValueForKey
 
 */
- (id)mgs_associatedValueForKey:(void *)key
{
	return objc_getAssociatedObject(self, key);
}
@end
