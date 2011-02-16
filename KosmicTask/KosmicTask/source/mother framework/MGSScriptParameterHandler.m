//
//  MGSScriptParameterHandler.m
//  Mother
//
//  Created by Jonathan on 09/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSScriptParameterHandler.h"
#import "MGSMother.h"
#import "MGSScriptPlist.h"
#import "MGSScriptParameter.h"
#import "NSString_Mugginsoft.h"

#define MAX_SHORT_STRING_VALUE_LENGTH 100

@implementation MGSScriptParameterHandler

/*
 
 init
 
 */
- (id)init
{
	// must initialise super with class and factory selector used to wrap around array items
	if ((self = [super initWithItemClass:[MGSScriptParameter class] 
					withFactorySelector:@selector(dictWithDict:)
					withAddItemSelector:@selector(dict)])) {
		
	}
	return self;
}

/*
 
 set handler from dict
 
 */
- (void)setHandlerFromDict:(NSMutableDictionary *)dict
{
	// load array from dict with key MGSScriptKeyParameters
	id array = [dict objectForKey:MGSScriptKeyParameters];
	
	// create array if not found
	if (!array) {
		array = [NSMutableArray arrayWithCapacity:2];
		[dict setObject:array forKey:MGSScriptKeyParameters];
	}
	
	[self setArray:array];
}

/*
 
 short string value
 
 */
- (NSString *)shortStringValue
{
	NSUInteger count = [self count];
	NSString *stringValue = nil;
	
	if (count == 0) {
		return @"";
	}
	
	// get short string value for each parameter
	for (NSUInteger i = 0; i < count; i++) {
		
		// get value
		MGSScriptParameter *parameter = [self itemAtIndex:i];
		id parameterValue = [parameter value];
		NSString *shortStringValue = nil;
		
		// get short string representation
		if ([parameterValue isKindOfClass:[NSString class]]) {
			shortStringValue = parameterValue;
		} else if ([parameterValue isKindOfClass:[NSNumber class]]) {
			shortStringValue = [(NSNumber *)parameterValue stringValue];
		} else {
			shortStringValue = [parameterValue description];
		}
		
		//  truncate parameter value
		if ([shortStringValue length] > MAX_SHORT_STRING_VALUE_LENGTH) {
			shortStringValue = [NSString stringWithFormat:@"%@…%@", [shortStringValue substringToIndex:MAX_SHORT_STRING_VALUE_LENGTH/2], [shortStringValue substringFromIndex:[shortStringValue length] - MAX_SHORT_STRING_VALUE_LENGTH/2]];
		} 
		
		// don't want any wrapping to occur
		shortStringValue = [shortStringValue mgs_stringWithOccurrencesOfCrLfRemoved];
		
		if (!stringValue) {
			stringValue = [shortStringValue copy];
		} else {
			stringValue = [NSString stringWithFormat:@"%@, %@", stringValue, shortStringValue]; 
		}
	}
	
	return stringValue;
}
@end
