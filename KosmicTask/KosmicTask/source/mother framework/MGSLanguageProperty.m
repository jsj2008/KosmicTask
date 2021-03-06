 //
//  MGSLanguageProperty.m
//  KosmicTask
//
//  Created by Jonathan on 30/08/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSLanguageProperty.h"
#import "MGSLanguagePropertyManager.h"
#import "MLog.h"
#import "MGSLanguage.h"

// class extension
@interface MGSLanguageProperty()

@property MGSLanguagePropertyType propertyType;
@property BOOL canReset;
@property BOOL hasInitialValue;
@property BOOL isList;
@end

@implementation MGSLanguageProperty

@synthesize key, name, value, propertyType, optionValues, requestType, editable, 
infoText, canReset, hasInitialValue, isList, defaultOptionKey, initialValue, delegate, allowReset;

/*
 
 + missingProperty
 
 */
+ (NSString *)missingProperty
{
	return [MGSLanguage missingProperty];
}

/*
 
 + isMissingProperty
 
 */
+ (BOOL)isMissingProperty:(NSString *)property
{
	return [property isEqualToString:[self missingProperty]];
}
/*
 
 - initWithKey:name:value:
 
 */
- (id)initWithKey:(NSString*)aKey name:(NSString *)aName value:(id)aValue
{
	self = [super init];
	if (self) {
		
		NSAssert(aKey, @"key is nil");
		NSAssert(aName, @"name is nil");
		NSAssert(aValue, @"value is nil");
		
		key = [aKey copy];
		name = [aName copy];
		
		if ([aValue conformsToProtocol:@protocol(NSCopying)]) {
			aValue = [aValue copy];
		}
		value = aValue;
		initialValue = aValue;
		propertyType = kMGSLanguageProperty;
		requestType = kMGSLanguageRequest;
		hasInitialValue = YES;
		allowReset = NO;
		canReset = NO;
		editable = NO;
		isList = NO;
	}
	
	return self;
}

/*
 
 - setOptionValues:
 
 */

- (void)setOptionValues:(NSDictionary *)values
{
	if (!values) {
		optionValues = nil;
		self.editable = NO;
		self.isList = NO;
		
		return;
	}
	
	// validate the options.
	// keys must respond to compare: and values must be strings
	if ([values count] > 0) {
		Class objectClass = [NSString class];
		Class keyClass = nil;
		
		for (id valueKey in [values allKeys]) {
			if (!keyClass) keyClass = [valueKey class];
			id object = [values objectForKey:valueKey];
			
			NSAssert([object isKindOfClass:objectClass], @"invalid object in dictionary");
			NSAssert([valueKey isKindOfClass:keyClass], @"invalid key in dictionary");
			NSAssert([valueKey respondsToSelector:@selector(compare:)], @"key does not respond to compare:");
		}
	}
	
	optionValues = [values copy];
	self.editable = YES;
	self.isList = YES;
	
	// select the item for the first key if the current value
	// is not a valid option
	
	self.defaultOptionKey = [self keyForOptionValue];
	
	if (!self.defaultOptionKey) {
		NSArray *keys = [self sortedOptionKeys];
		if ([keys count] > 0) {
			self.defaultOptionKey = [keys objectAtIndex:0];
			
			id newValue = [optionValues objectForKey:self.defaultOptionKey];
			self.initialValue = newValue;
		}
	}
}

/*
 
 - setInitialValue:
 
 */
- (void)setInitialValue:(id)newValue 
{
	self.value = newValue;
	initialValue = newValue;
	self.hasInitialValue = YES;
	self.canReset = NO;
}

/*
 
 - keyForOptionValue
 
 */
- (id)keyForOptionValue
{
    id optionKey = nil;
    
	NSArray *keys = [optionValues allKeysForObject:self.value];
	if ([keys count] > 0) {
        optionKey = [keys objectAtIndex:0];
    }
    
    if (!optionKey) {
        NSLog(@"keyForOptionValue is nil for property %@ value %@", self.name, self.value);
    }
    return optionKey;
}

/*
 
 - sortedOptionKeys
 
 */
- (NSArray *)sortedOptionKeys
{
	NSArray *propKeys = [[optionValues allKeys] sortedArrayUsingSelector:@selector(compare:)];
	
	return propKeys;
}

/*
 
 - setEditable:
 
 */
- (void)setEditable:(BOOL)aBOOL
{
	editable = aBOOL;
	if (aBOOL) {
		self.propertyType = kMGSLanguageEditableOption;
	} else {
		self.propertyType = kMGSLanguageProperty;
	}
}

/*   
 
 - setValue: 
 
 */
- (void)setValue:(id)newValue
{
	if (!newValue) {
		
		if ([initialValue isKindOfClass:[NSString class]]) {
			newValue = @"";
		} else {
			newValue = initialValue;
		}
	}
	
	if ([newValue isEqualTo:value]) {
		return;
	}
	
	// check that new value is one of our allowed options
	if (optionValues) {
		NSArray *keys = [optionValues allKeysForObject:newValue];
		if ([keys count] == 0) {
            
            BOOL allowCaseInsensitiveMatch = NO;
            BOOL newValueUpdated = NO;
            
            if (allowCaseInsensitiveMatch && [newValue isKindOfClass:[NSString class]]) {
                for (id optionValue in [optionValues allValues]) {
                    if ([optionValue isKindOfClass:[NSString class]]) {
                        if ([optionValue compare:newValue options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                            newValue = optionValue;
                            newValueUpdated = YES;
                            break;
                        }
                    }
                }
            }
            
            if (!newValueUpdated) {
                MLogInfo(@"new value is not a valid option: %@", newValue);
                return;
            }
		}
	}
	
        
	value = newValue;
	self.hasInitialValue = ([value isEqualTo:initialValue]) ? YES : NO;
	self.canReset = !self.hasInitialValue;
	
	// inform delegate of change
	if (delegate && [delegate respondsToSelector:@selector(languagePropertyDidChangeValue:)]) {
		[delegate languagePropertyDidChangeValue:self];
	}
	
}

/*   
 
 - updateValue: 
 
 */
- (void)updateValue:(id)newValue
{
	if (!newValue) {
		return;
	}

	[self setValue: newValue];
}

/*   
 
 - updateOptionKey:
 
 */
- (void)updateOptionKey:(id)newKey
{
	if (!newKey) {
		return;
	}
	id newValue = [optionValues objectForKey:newKey];
    if (newValue) {
        [self updateValue:newValue];
    } else {
        
        // this can be triggered when loading an old task history dict
        // that doesn't contain a particular key
        MLogInfo(@"%@ : Missing value for key %@", self.name, newKey);
    }
}

/*
 
 - resetToInitialValue:
 
 */
- (IBAction)resetToInitialValue:(id)sender
{
#pragma unused(sender)
	self.value = initialValue; 
}

#pragma mark -
#pragma mark NSCopying

/*
 
 - copyWithZone:
 
 */
-(id)copyWithZone:(NSZone *)zone
{
#pragma unused(zone)
	
	MGSLanguageProperty *copy = [[[self class] alloc] initWithKey:self.key name:self.name value:self.value];
	copy.optionValues = self.optionValues;
	copy.infoText = self.infoText;
	copy.requestType = self.requestType;
	copy.editable = self.editable;
	/*
	 
	 see see MGSResourceBrowserViewController line:288 - buildSettingsTree.
	 
	 perhaps the copy should perform 
	 hasInitialValue = YES, canReset = NO ?
	 
	 because we aren't explicitly copying initialValue.
	 
	 */
	//copy.canReset = self.canReset;
	//copy.hasInitialValue = self.hasInitialValue;

	copy.allowReset = self.allowReset;	// not dependent on hasInitialValue
	copy.defaultOptionKey = self.defaultOptionKey;
	copy.isList = self.isList;
	
	NSAssert([self.value isEqual:copy.value], @"language property value not copied correctly");
	
	return copy;
}

#pragma mark -
#pragma mark Logging
/*
 
 - description
 
 */
- (NSString *)description
{
	return name;
}

/*
 
 - log
 
 */
- (void)log
{
	NSMutableString *s = [NSMutableString new];
	[s appendFormat:@"key: %@\n", key];
	[s appendFormat:@"name: %@\n", key];
	[s appendFormat:@"value: %@\n", value];
	[s appendFormat:@"initialValue: %@\n", initialValue];
	[s appendFormat:@"optionValues: %@\n", optionValues];
	[s appendFormat:@"defaultOptionKey: %@\n", defaultOptionKey];
	[s appendFormat:@"propertyType: %ld\n", (long)propertyType];
	[s appendFormat:@"requestType: %ld\n", (long)requestType];
	[s appendFormat:@"editable: %i\n", editable];
	[s appendFormat:@"infoText: %@\n", infoText];

	[s appendFormat:@"canReset: %i\n", canReset];
	[s appendFormat:@"allowReset: %i\n", allowReset];
	[s appendFormat:@"hasInitialValue: %i\n", hasInitialValue];
	[s appendFormat:@"isList: %i\n", isList];
	[s appendFormat:@"languagePropertyManager: %@\n", delegate];

	MLogInfo(@"\nMGSLanguageProperty = \n%@", s);
}
@end
