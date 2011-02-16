//
//  NSDictionary_Mugginsoft.m
//  Mother
//
//  Created by Jonathan on 03/07/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "NSDictionary_Mugginsoft.h"
#import "NSObject_Mugginsoft.h"

@implementation NSDictionary (Mugginsoft)

/*
 
 object for key with default
 
 */
- (id)objectForKey:(NSString *)key withDefault:(id)defValue
{
	
	id object = [self objectForKey:key];
	if (!object) {
		return defValue;
	}
	
	// object must match defValue type.
	// under 10.5 this was okay with defValue an instance of NSArray
	// under 10.6 object is __NSArray0
	// docs rightly say that calling isKindOfClass on a class cluster object is fraught
	if (NO) {
		if (defValue && ![object isKindOfClass:[defValue class]]) {
			return defValue;
		}
	}
	
	return object;
}


/*
 
 property list string value
 
 */
- (NSString *)propertyListStringValue
{
	NSString *error;
	NSData *xmlData = [NSPropertyListSerialization dataFromPropertyList:self
																 format:NSPropertyListXMLFormat_v1_0
													   errorDescription:&error];
	NSString *xmlString;
	if (xmlData) {
		xmlString = [[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding];
	} else {
		xmlString = @"not a valid property list";
	}
	
	return xmlString;
}

/*
 
 dictionary with all objects and keys represented as strings
 
 */
- (NSDictionary *)dictionaryWithObjectsAndKeysAsStrings
{
	
	NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithCapacity:[self count]];
	for (id key in [self allKeys]) {
		id object = [self objectForKey:key];
		NSString *stringKey = [key aStringRepresentation];
		NSString *stringObject = [object aStringRepresentation];
		[newDict setObject:stringObject forKey:stringKey];
	}
	return newDict;
}

/*
 
 string value with format
 
 */
- (NSString *)stringValueWithFormat:(NSString *)format
{
	NSDictionary *stringDict = [self dictionaryWithObjectsAndKeysAsStrings];
	NSMutableString *stringValue = [NSMutableString stringWithCapacity:100];
	for (id key in [stringDict allKeys]) {
		[stringValue appendFormat:format, key, [stringDict objectForKey:key]];
	}
	
	return stringValue;
}

/*
 
 -mgs_objectForKeys:caseSensitive:
 
 */
- (id) mgs_objectForKeys:(NSArray *)searchKeys caseSensitive:(BOOL)caseSensitive
{	
	id foundObject = nil;
	NSDictionary *mySelf = self;
	/*
	 
	 transform dictionary to use lower case keys 
	 
	 */
	if (!caseSensitive) {
		NSArray *myKeys = [self allKeys]; // get all keys
		
		NSMutableDictionary *transformedSelf = [NSMutableDictionary dictionaryWithCapacity:10];
		for (id key in myKeys) {
			id transformedKey = key;
			if ([key isKindOfClass:[NSString class]]) {
				transformedKey = [key lowercaseString];	
			}
			[transformedSelf setObject:[self objectForKey:key] forKey:transformedKey];
		}
		
		mySelf = transformedSelf;
	}
	
	/*
	 
	 transform the search keys lower case and search dict for match
	 
	 */
	for (id searchKey in searchKeys) {
		id transformedKey = searchKey;
		
		if (!caseSensitive && [searchKey isKindOfClass:[NSString class]]) {
			transformedKey = [searchKey lowercaseString];
		}
		
		foundObject = [mySelf objectForKey:transformedKey];
		if (foundObject) {
			break;
		}
	}
	
	return foundObject;
}
@end
