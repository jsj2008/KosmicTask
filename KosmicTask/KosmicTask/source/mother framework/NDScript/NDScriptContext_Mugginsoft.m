//
//  NDScriptContext_Mugginsoft.m
//  Mother
//
//  Created by Jonathan on 05/06/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "NDScriptContext_Mugginsoft.h"
#import "NSValue+NDFourCharCode.h"
#import <appscript/types.h>
#import <appscript/codecs.h>

@interface NDScriptContext (Mugginsoft_private)
- (NSDictionary *)resolveDictionary:(NSDictionary *)input;
- (NSArray *)resolveArray:(NSArray *)input;
- (id)resolveObject:(id)object;
@end



@implementation NDScriptContext (Mugginsoft)

/*
 - resultObject
 */
- (id)aemResultObject
{
	NDScriptData *scriptData = [self resultScriptData];
	
	NSAppleEventDescriptor *aed = [scriptData appleEventDescriptorValue];
	if (aed == nil) {
		return NSLocalizedString(@"Result is empty.", @"No result from task script.");;
	}
	
	//
	// call the AEMCodec .
	// more versatile than the NDScript codec. handles dates etc.
	// raises an exception if aed is nil
	// note that by default files, aliases etc are rendered differently.
	//
	return [[AEMCodecs defaultCodecs] unpack:aed];
}

/*
 
 try and resolve apple event codes into strings
 
 */
- (id)resolveEventCodes:(id)object
{
	return [self resolveObject:object];
}

@end

@implementation NDScriptContext (Mugginsoft_private)

/*
 
 resolve dictionary
 
 */
- (NSDictionary *)resolveDictionary:(NSDictionary *)input
{
	NSMutableDictionary *output = [NSMutableDictionary dictionaryWithCapacity:[input count]];
	
	NSArray *keys =[input allKeys];
	for (id key in keys) {
		id item = [input objectForKey:key];
		
		id newKey = [self resolveObject:key];
		id newItem = [self resolveObject:item];
		
		[output setObject:newItem forKey:newKey];
	}
	return output;
}

/*
 
 resolve array
 
 */
- (NSArray *)resolveArray:(NSArray *)input
{
	NSMutableArray *output = [NSMutableArray arrayWithCapacity:[input count]];
	for (id item in input) {
		id newItem = [self resolveObject:item];
		[output addObject:newItem];
	}
	
	return output;
}

/*
 
 resolve object
 
 */
- (id)resolveObject:(id)object
{
	NDFourCharCodeValue *eventCode = nil;
	
#pragma mark warning calling -isKindOfClass: is fraught with danger on class clusters - see the docs
	// resolve array
	if ([object isKindOfClass:[NSArray class]]) {
		return [self resolveArray:object];
		
	// resolve dictionary
	} else if ([object isKindOfClass:[NSDictionary class]]) {
		return [self resolveDictionary:object];
		
	// NDScript: resolve four char event code
	} else if ([object isKindOfClass:[NDFourCharCodeValue class]]) {
		eventCode = object;
		
		goto processEventCode;

	// coerce NSURL to path.
	// AS file objects will be coerced to NSURL
	} else if ([object isKindOfClass:[NSURL class]]) {
		return [(NSURL *)object path];

	// coerce ASFileBase to path.
	// AS alias and file ref objects will be coerced to ASFileBase
	} else if ([object isKindOfClass:[ASFileBase class]]) {
		return [(ASFileBase *)object path];
		
	// AEMType: resolve four char event code
	// appscript wraps unknown descriptors in an AEMType
	} else if ([object isKindOfClass:[AEMType class]]) {
		
		AEMType *aemObject = object;
		eventCode = [[NDFourCharCodeValue alloc] initWithFourCharCode:[aemObject fourCharCode]];

	processEventCode:;
		
		// form default event string
		NSString *eventString =  [@"Apple Event: " stringByAppendingString:[eventCode stringValue]];
		
		// form class string that we will send to AppleScript for compilation.
		// this will gives a textual respresentation of the class
		NSString *classString = [NSString stringWithFormat:@"«class %@»", [eventCode stringValue]];

		// we can get a textual rep of the class by feeding it back into the compiler
		NDScriptContext *appleScriptObject = [[NDScriptContext alloc] initWithSource:classString modeFlags:(kOSAModeNeverInteract | kOSAModeCompileIntoContext) componentInstance:nil];
		BOOL scriptCompiled = appleScriptObject ? YES : NO;
		
		if (scriptCompiled) {
			
			// get script compiled data
			NSData *scriptData = [appleScriptObject data];
			if (scriptData) {
				// get script source
				eventString = [[appleScriptObject attributedSource] string];
			}
		} 
		
		// cleanup
		[eventCode release];
		[appleScriptObject release];
		
		return eventString;
	} else {
		return object;
	}
}
@end
