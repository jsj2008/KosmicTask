//
//  MGSCallScript.m
//  Mother
//
//  Created by Jonathan Mitchell on 29/12/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSCallScript.h"

@implementation MGSCallScript

+ (id) withURLToCompiledScript:(NSURL*)scriptURL
{
	return [[self alloc] initWithURLToCompiledScript:scriptURL];
}

+ (id) withCompiledData:(NSData *)data
{
	return [[self alloc] initWithCompiledData:data];
}

//
// calls script with
//
- (NSAppleEventDescriptor *)executeAndReturnError
{
	NSDictionary *errors = nil;
	NSAppleEventDescriptor *eventDescriptor = [[self theScript] executeAndReturnError:&errors];
	if (errors) {
		return nil;
	}
	return eventDescriptor;
}
//
// call script handler with array of standard obj-c objects
// objects in array must be NSNumber, NSString or NSAppleEventDescriptor
//
- (NSAppleEventDescriptor*) callHandler:(NSString *)handlerName withArrayOfParameters: (NSArray *)array 
{
	int index = 1;
	NSAppleEventDescriptor* paramList = [NSAppleEventDescriptor listDescriptor];
	
	for (id param in array) {
		
		if ( [param isKindOfClass: [NSNumber class]] ) {
			
			[paramList insertDescriptor:
			 [NSAppleEventDescriptor descriptorWithInt32:[param longValue]] atIndex:(index++)];
			
		} else if ( [param isKindOfClass: [NSString class]] ) {
			
			[paramList insertDescriptor:
			 [NSAppleEventDescriptor descriptorWithString:param] atIndex:(index++)];
			
		} else if ( [param isKindOfClass: [NSAppleEventDescriptor class]] ) {
			
			[paramList insertDescriptor: param atIndex:(index++)];
			
		} else {
			
			MLog(DEBUGLOG, @"unrecognized parameter type for parameter %@ :", param);
			return nil; /* bad parameter */
			
		}
	}
	
	return [self callScript: handlerName withArrayOfParameters: paramList];
}

@end
