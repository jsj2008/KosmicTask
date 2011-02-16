//
//  NSPropertyListSerialization_Mugginsoft.m
//  Mother
//
//  Created by Jonathan on 10/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "NSPropertyListSerialization_Mugginsoft.h"
#import "NSString_Mugginsoft.h"

@implementation NSPropertyListSerialization (Mugginsoft)

/*
 
 coerce property list
 
 */
+ (id)coercePropertyList:(id)plist
{
	return [self coerceObject:plist];
}

/*
 
	Coerce dictionary
 
*/
+ (NSDictionary *)coerceDictionary:(NSDictionary *)input
{
	NSMutableDictionary *output = [NSMutableDictionary dictionaryWithCapacity:[input count]];

	NSArray *keys =[input allKeys];
	for (id key in keys) {
		id item = [input objectForKey:key];
		
		id newKey = [self coerceObject:key];
		id newItem = [self coerceObject:item];
		
		[output setObject:newItem forKey:newKey];
	}
	return output;
}

/*
 
	Coerce array
 
 */
+ (NSArray *)coerceArray:(NSArray *)input
{
	NSMutableArray *output = [NSMutableArray arrayWithCapacity:[input count]];
	for (id item in input) {
		id newItem = [self coerceObject:item];
		[output addObject:[self coerceObject:newItem]];
	}
	
	return output;
}

/*
 
	Coerce object
 
 */
+ (id)coerceObject:(id)object
{
	// NSValue objects seem to be validated by propertyList:isValidForFormat and yet
	// serialisation of them always fails.
	// hence detect their presence.
	if ([object isKindOfClass:[NSValue class]]) {
		return [NSString stringWithFormat:@"%@", object];
	}
	
	if ([self propertyList:object isValidForFormat:NSPropertyListXMLFormat_v1_0]) {
		return object;
	}
	
	if ([object isKindOfClass:[NSArray class]]) {
		return [self coerceArray:object];
	} else if ([object isKindOfClass:[NSDictionary class]]) {
		return [self coerceDictionary:object];
	} 
	
	id newObject = nil;
	
	// coerce types here
	@try {
		if ([object respondsToSelector:@selector(stringValue)]) {
			newObject = [object stringValue];
		} else if ([object respondsToSelector:@selector(description)]) {
			newObject = [object description];
		} 
		
		if ([self propertyList:newObject isValidForFormat:NSPropertyListXMLFormat_v1_0]) {
			return newObject;
		}

		//if ([newObject isKindOfClass:[NSString class]]) {
		//	return newObject;
		//}
		
	} @catch (NSException *e) {
		NSLog(@"Exception coercing plist type: %@", e);
	}
	
	NSString *format = NSLocalizedString(@"instance of %@ - %@", @"format string for property list uncoerced object");
	NSString *objectString = [NSString stringWithFormat:format, [object className], [NSString mgs_stringWithNewUUID]];
	//NSLog(@"coerced object string is: %@", objectString);
	return objectString;
}

/*
 
 form XML Document from plist
 
 */
+ (NSXMLDocument *)XMLDocumentFromPropertyList:(id)aPlist format:(NSString *)format errorDescription:(NSString **)errorString
{
	#pragma unused(format)
	NSString *resultString = NSLocalizedString(@"results", @"xml results node");

	// make our XML document with given root
	NSXMLElement *root = (NSXMLElement *)[NSXMLNode elementWithName:resultString];
	NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithRootElement:root];
	if (xmlDoc) {
		[xmlDoc setVersion:@"1.0"];
		[xmlDoc setCharacterEncoding:@"UTF-8"];
	
		// add our plist to the root
		[self addPropertyList:aPlist toXMLElement:root withName:nil errorDescription:errorString];
	}
	
	return [xmlDoc autorelease];
}

/* 
 
 add property list to xml document at the given element
 
 */
+ (BOOL)addPropertyList:(id)aPlist toXMLElement:(NSXMLElement *)parent withName:(NSString *)name errorDescription:(NSString **)errorString
{
	BOOL simpleData = NO;
	NSString *nodeName = nil;
	NSXMLElement *element = nil;
	
	if (name && ![name isKindOfClass:[NSString class]]) {
		*errorString = @"element name must be of type NSString";
		return NO;
	}
	
	// look for simple data types
	if ([aPlist isKindOfClass:[NSString class]]) {
		simpleData = YES;
		nodeName = @"text";
	} else if ([aPlist isKindOfClass:[NSNumber class]]) {
		simpleData = YES;
		nodeName = @"number";
	} else if ([aPlist isKindOfClass:[NSDate class]]) {
		simpleData = YES;
		nodeName = @"date";
	} else if ([aPlist isKindOfClass:[NSData class]]) {
		simpleData = YES;
		nodeName = @"data";
	} else if ([aPlist isKindOfClass:[NSArray class]]) {
		nodeName = @"array";
	} else if ([aPlist isKindOfClass:[NSDictionary class]]) {
		nodeName = @"dictionary";
	} 
	
	if (name && ![name isEqualToString:@""]) {
		nodeName = name;
	}
	
	// add simple data as text node to parent node
	if (simpleData) {
		element = [[NSXMLElement alloc] initWithName:nodeName];
		[element setObjectValue:aPlist];
		[parent addChild:element];
	}
	
	// array
	else if ([aPlist isKindOfClass:[NSArray class]]) {
		
		// create element
		element = [[NSXMLElement alloc] initWithName:nodeName];
		[parent addChild:element];
		
		// add plist to element
		for (id item in aPlist) {
			if (![self addPropertyList:item toXMLElement:element withName:nil errorDescription:errorString]) {
				return NO;
			}
		}
	}
	
	// dictionary
	else if ([aPlist isKindOfClass:[NSDictionary class]]) {

		// create element
		element = [[NSXMLElement alloc] initWithName:nodeName];
		[parent addChild:element];
		
		NSArray *dictKeys = [aPlist allKeys];
		for (id key in dictKeys) {
			if (![self addPropertyList:[aPlist objectForKey:key] toXMLElement:element withName:key errorDescription:errorString]) {
				return NO;
			}			
		}
	} else {
		*errorString = [NSString stringWithFormat:@"Invalid plist data type: %@", [aPlist className]];
		return NO;
	}
	
	[element release];
	
	return YES;
}

@end
