//
//  MGSDictionary.m
//  Mother
//
//  Created by Jonathan on 08/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
// This class wraps an NSMutableDictionary and can be subclassed
// to provide an class interface to a dictionary.
//

#import "MGSMother.h"
#import "MGSDictionary.h"
#import "MGSScriptPlist.h"
#import "NSMutableDictionary_Mugginsoft.h"

@implementation MGSDictionary
/* note on factory methods and self from
 
 Inside a + class method self refers to the class not an instance
 
 http://developer.apple.com/documentation/Cocoa/Conceptual/ObjectiveC/Articles/chapter_8_section_5.html#//apple_ref/doc/uid/TP30001163-CH14-BAJHDGAC
 
 Redefining self
 super is simply a flag to the compiler telling it where to begin searching for the method to perform; 
 it’s used only as the receiver of a message. But self is a variable name that can be used in any number of ways, even assigned a new value.
 
 There’s a tendency to do just that in definitions of class methods. Class methods are often concerned not with the class object, 
 but with instances of the class. For example, many class methods combine allocation and initialization of an instance, 
 often setting up instance variable values at the same time. In such a method, it might be tempting to send messages to the
 newly allocated instance and to call the instance self, just as in an instance method. But that would be an error. 
 self and super both refer to the receiving object—the object that gets a message telling it to perform the method. 
 Inside an instance method, self refers to the instance; but inside a class method, self refers to the class object. 
 This is an example of what not to do:
 
 + (Rectangle *)rectangleOfColor:(NSColor *) color
 {
 self = [[Rectangle alloc] init]; // BAD
 [self setColor:color];
 return [self autorelease];
 }
 To avoid confusion, it’s usually better to use a variable other than self to refer to an instance inside a class method:
 
 + (id)rectangleOfColor:(NSColor *)color
 {
 id newInstance = [[Rectangle alloc] init]; // GOOD
 [newInstance setColor:color];
 return [newInstance autorelease];
 }
 In fact, rather than sending the alloc message to the class in a class method, it’s often better to send alloc to self. 
 This way, if the class is subclassed, and the rectangleOfColor: message is received by a subclass, 
 the instance returned will be the same type as the subclass (for example, the array method of NSArray is inherited by NSMutableArray).
 
 + (id)rectangleOfColor:(NSColor *)color
 {
 id newInstance = [[self alloc] init]; // EXCELLENT
 [newInstance setColor:color];
 return [newInstance autorelease];
 
 } 
 */
+ (id) newDict
{
	MGSDictionary *this = [[self alloc] init];
	
	[this setName:NSLocalizedString(@"new", @"default name for new item")];
	[this setDescription:NSLocalizedString(@"new item", @"default description for new item")];
	
	return this;
}

+ (id) dictWithDict:(NSMutableDictionary *)dict
{
	id this = [[[self class] alloc] init];
	[this setDict:dict];
	return this;
}

- (id)init
{
	if ([super init]) {
		_dict = [NSMutableDictionary dictionaryWithCapacity:25];
		
		//
		// note that it might be better to look at the main bundle's list of support localizations
		//
		NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
		NSArray* languages = [defs objectForKey:@"AppleLanguages"];
		NSString* preferredLang = [languages objectAtIndex:0];
		
		// english is the default language
		if ([preferredLang isEqualToString:@"en"]) {
			_preferredLang = @"";
		} else {
			_preferredLang = [@"-" stringByAppendingString:preferredLang];
		}
	}
	return self;		 
}

// this object is merely a wrapper for the dictionary object.
// hence we only need a ref to the dictionary not a copy
- (void)setDict:(NSMutableDictionary *)dict
{
	NSAssert(dict, @"dict is nil"); 
	// testing for mutability like this doesn't work beacuse the class cluster returns
	// an NSCFDictionary that implements mutability internally./
	// 
	//NSAssert([dict isKindOfClass:[NSMutableDictionary class]], @"dict is not mutable");
	_dict = dict;
}

- (NSMutableDictionary *)dict
{
	return _dict;
}

- (NSString *)name
{
	return [self objectForLocalizedKey:MGSScriptKeyName];
}

- (void)setName:(NSString *)aString
{
	[self setObject:aString forLocalizedKey:MGSScriptKeyName];
}

- (NSString *)description
{
	return [self objectForLocalizedKey:MGSScriptKeyDescription];
}
- (void)setDescription:(NSString *)aString
{
	[self setObject:aString forLocalizedKey:MGSScriptKeyDescription];
}

- (id)objectForLocalizedKey:(NSString *)key
{
	NSAssert(_dict, @"script dict is nil");
	
	// objectForKey:appending is a category on NSDictionary
	id value = [self objectForKey:key appending:_preferredLang];
	return value;
}

// if key not defined return NO
- (BOOL)boolForKey:(NSString *)key
{
	NSAssert(_dict, @"script dict is nil");
	
	NSNumber *value = [_dict objectForKey:(NSString *)key];
	if (value) {
		return [value boolValue];
	} else {
		return NO;
	}
}


/*
 
 set bool
 
 */
- (void)setBool:(BOOL)value forKey:(NSString *)key
{
	[self setObject:[NSNumber numberWithBool:value] forKey:key];
}

/*
 
 integer for key
 
 */
- (NSInteger)integerForKey:(NSString *)key
{
	NSAssert(_dict, @"script dict is nil");
	
	NSNumber *value = [_dict objectForKey:(NSString *)key];
	return [value integerValue];
}


/* 
 
 set integer
 
 */
- (void)setInteger:(NSInteger)value forKey:(NSString *)key
{
	[self setObject:[NSNumber numberWithInteger:value] forKey:key];
}

/*
 
 set object for localized key
 
 */
- (void)setObject:(id)obj forLocalizedKey:(NSString *)key
{
	if (nil == obj) {
		[self removeObjectForKey:key appending:_preferredLang];
	} else {
		[self setObject:[obj copy] forKey:key appending:_preferredLang];
	}
}


- (void)setObject:(id)object forKey:(NSString *)key appending:(NSString *)language
{
	[self setObject:object forKey:[self localizeKey:key appending:language]];
}


- (void) removeObjectForKey:(NSString *)key appending:(NSString *)language
{
	[self removeObjectForKey:[self localizeKey:key appending:language]];
}

- (id)objectForKey:(NSString *)key appending:(NSString *)language
{
	
	// search for key modified to identify say preferred language
	// eg:
	// Description - default key
	// Description-en explicit english version
	// Description-fr explicit french version
	if (language) {
		id value = [self objectForKey:[self localizeKey:key appending:language]];
		if (value) {
			return value;
		}
	}
	
	// return unlanguage modified object
	return [self objectForKey:key];
}

- (NSString *)localizeKey:(NSString *)key appending:(NSString *)language
{
	NSString *localizedKey;
	
	if (language) {
		localizedKey = [key stringByAppendingString: language];
	} else {
		localizedKey = key;
	}
	
	return localizedKey;
}

/*
 
 set object for key
 
 */
- (void)setObject:(id)obj forKey:(NSString *)key
{
	if (nil == obj) {
		[_dict removeObjectForKey:key];
	} else {
		id copyObj = [obj copy];
		[_dict setObject:copyObj forKey:key];
	}
}

/*
 
 assign object for key
 
 */
- (void)assignObject:(id)obj forKey:(NSString *)key
{
	[_dict setObject:obj forKey:key];
}

- (void)removeObjectForKey:(NSString *)key
{
	[_dict removeObjectForKey:key];
}

- (id)objectForKey:(NSString *)key
{
	return [_dict objectForKey:key];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	// produce copy of current class (ie: the subclass)
	// only a class object can call alloc to create another instance.
	// the self pointer will point to the receiver
	id copy = [[[self class] allocWithZone: zone] init];
	
	//[self setScriptDict:[NSMutableDictionary dictionaryWithDictionary: [self scriptDict]]];
	// make mutable copy of the dict
	[copy setDict:[_dict mutableCopyWithZone:zone]];

	return copy;
}
/*
 
 - mutableDeepCopy
 
 */
- (id)mutableDeepCopy
{
	// produce copy of current class (ie: the subclass)
	// only a class object can call alloc to create another instance.
	// the self pointer will point to the receiver
	id copy = [[[self class] alloc] init];

	// make a deep copy of the dictionary
	NSMutableDictionary *dictCopy = [self dictMutableDeepCopy];
	[copy setDict:dictCopy];
	
	return copy;
}

/*
 
 - dictMutableDeepCopy
 
 */
- (NSMutableDictionary *)dictMutableDeepCopy
{	// create deep copy of dict by archiving and unarchiving
	// everthing in the dict must conform to NSCoding
	// but as it is a plist this should be okay
	//
	// note:
	//id dictCopy = [NSUnarchiver unarchiveObjectWithData:[NSArchiver archivedDataWithRootObject: _dict]];
	// the above line functions except that bools wrapped in NSNumber emerge as integers, which
	// mucks up the property list types.
	//
	//MLog(DEBUGLOG, @"dict before deep copy: %@", [_dict propertyListStringValue]);
	NSMutableDictionary *dictCopy = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject: _dict]];
	//MLog(DEBUGLOG, @"dict after deep copy: %@", [dictCopy propertyListStringValue]);

	return dictCopy;
}

/*
 
 - copyDictFrom:
 
 */
- (void)copyDictFrom:(MGSDictionary *)aDict
{
	[self setDict:[aDict dictMutableDeepCopy]];
}

// serialise as property list data
- (NSData *)propertyListData
{
	// serialize the dict - note that this method provides more error feed back than
	// NSDictionary -writeToFile:atomically.
	//
	// note that we are serializing as XML here.
	// NSData objects are base-64 encoded by default
	NSString *xmlerror = nil;
	NSData *xmlData = [NSPropertyListSerialization dataFromPropertyList:_dict
																 format:NSPropertyListXMLFormat_v1_0
																 errorDescription:&xmlerror];
	if(!xmlData) {
		MLog(DEBUGLOG, @"error serializing MGSDictionary content: %@", xmlerror);
		return nil;
	}
		
	return xmlData;
}

// save to path
- (BOOL)saveToPath:(NSString *)path
{
	NSError *errorObj = nil;

	// serialise as property list
	NSData *xmlData = [self propertyListData];
	if (!xmlData) {
		return NO;
	}
	
	// save data
	if (![xmlData writeToFile:path options:NSAtomicWrite error:&errorObj]) {
		MLog(DEBUGLOG, @"error saving MGSDictionary content: %@", [errorObj localizedDescription]);
		return NO;
	}
													   													   
	return YES;
}

/*
 
 sync dict
 
 */
- (BOOL)syncWithDict:(NSDictionary *)syncDict 
{
	NSArray *keys = [syncDict allKeys];
	for (id key in keys) {
		id syncObject = [syncDict objectForKey:key];
		
		if (syncObject) {
			[_dict setObject:syncObject forKey:key];
		} else {
			MLog(RELEASELOG, @"Dictionary Sync object is nil");
		}

	}
	
	return YES;
}

@end
