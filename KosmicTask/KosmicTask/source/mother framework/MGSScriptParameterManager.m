//
//  MGSScriptParameterManager.m
//  Mother
//
//  Created by Jonathan on 09/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSScriptParameterManager.h"
#import "MGSMother.h"
#import "MGSScriptPlist.h"
#import "NSString_Mugginsoft.h"
#import "MGSAppController.h"
#import "MGSParameterPluginController.h"
#import "MGSParameterPlugin.h"

#define MAX_SHORT_STRING_VALUE_LENGTH 100

@interface MGSScriptParameterManager()
- (MGSScriptParameter *)scriptParameterWithUUID:(NSString *)value;
@end

@implementation MGSScriptParameterManager

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
	
	[self setRepresentation:MGSScriptParameterRepresentationStandard];
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


/*
 
 - setVariableNameUpdating:
 
 */
- (void)setVariableNameUpdating:(MGSScriptParameterVariableNameUpdating)value
{
	for (NSInteger i = 0; i < [self count]; i++) {
		MGSScriptParameter *parameter = [self itemAtIndex:i];
		[parameter setVariableNameUpdating:value];
        
        switch (value) {
            case MGSScriptParameterVariableNameUpdatingAuto:
            default:
                break;
                
            case MGSScriptParameterVariableNameUpdatingManual:
                [parameter setVariableStatus:MGSScriptParameterVariableStatusUsed];
                break;
        }
	}
}

#pragma mark Representation

/*
 
 - removeRepresentation
 
 */
- (void)removeRepresentation
{
	for (NSInteger i = 0; i < [self count]; i++) {
		MGSScriptParameter *parameter = [self itemAtIndex:i];
		[parameter removeRepresentation];
	}
}

/*
 
 - setRepresentation:
 
 */
- (void)setRepresentation:(MGSScriptParameterRepresentation)value
{
	for (NSInteger i = 0; i < [self count]; i++) {
		MGSScriptParameter *parameter = [self itemAtIndex:i];
		[parameter setRepresentation:value];
	}
}

/*
 
 - representation
 
 */
- (MGSScriptParameterRepresentation)representation
{
	MGSScriptParameterRepresentation rep = MGSScriptParameterRepresentationStandard;
	if ([self count] > 0) {
		MGSScriptParameter *parameter = [self itemAtIndex:0];
		rep = [parameter representation];
	}
	
	return rep;
}

/*
 
 - conformToRepresentation:
 
 */
- (BOOL)conformToRepresentation:(MGSScriptParameterRepresentation)representation
{
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], @"conform",
							 nil];
	
	return [self conformToRepresentation:representation options:options];
}

/*
 
 - conformToRepresentation:options:
 
 */
- (BOOL)conformToRepresentation:(MGSScriptParameterRepresentation)representation options:(NSDictionary *)options
{
	
	BOOL success = YES;
	
	// ask each parameter to conform to the representation
	for (NSInteger i = 0; i < [self count]; i++) {
		
		// get value
		MGSScriptParameter *parameter = [self itemAtIndex:i];
		success = [parameter conformToRepresentation:representation options:options];
		if (!success) {
			break;
		}
	}
	return success;
}

/*
 
 - copyValidValuesWithMatchingUUID:
 
 */
- (void)copyValidValuesWithMatchingUUID:(MGSScriptParameterManager *)srcManager
{
    for (NSInteger i = 0; i < [srcManager count]; i++) {
        MGSScriptParameter *srcParameter = [srcManager itemAtIndex:i];
        
        // get parameter with matching UUID
        MGSScriptParameter *parameter = [self scriptParameterWithUUID:srcParameter.UUID];
        
        // match parameter type
        if (parameter && [parameter.typeName isEqualToString:srcParameter.typeName]) {
            
            // we cannot simply set the value as it may be invalid or out of range
            // on the target parameter. hence we need to validate it using the plugin
            MGSParameterPluginController *parameterPluginController = [[NSApp delegate] parameterPluginController];
            MGSParameterPlugin *plugin = [parameterPluginController pluginWithClassName:parameter.typeName];
            
            if (plugin) {
                parameter.value = srcParameter.value;
            }
        }
    }

}

/*
 
 - scriptParameterWithUUID:
 
 */
- (MGSScriptParameter *)scriptParameterWithUUID:(NSString *)value
{
	for (NSInteger i = 0; i < [self count]; i++) {
		
		MGSScriptParameter *parameter = [self itemAtIndex:i];
        if ([parameter.UUID isEqualToString:value]) {
            return parameter;
        }
	}
    
    return nil;
}
@end
