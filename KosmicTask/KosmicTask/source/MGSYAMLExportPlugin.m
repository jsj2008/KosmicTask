//
//  MGSYAMLExportPlugin.m
//  KosmicTask
//
//  Created by Jonathan on 29/05/2011.
//  Copyright 2011 mugginsoft.com. All rights reserved.
//

#import "MGSYAMLExportPlugin.h"
#import <YAMLKit/YAMLKit.h>

@implementation MGSYAMLExportPlugin

/* 
 
 file extension
 
 */
- (NSString *)fileExtension
{
	return @"yml";
}

/* 
 
 menu item string
 
 */
- (NSString *)menuItemString
{
	return NSLocalizedString(@"YAML", @"Export plugin menu item string");
}

/* 
 
 display menu item string
 
 */
- (NSString *)displayMenuItemString
{
	return NSLocalizedString(@"yaml", @"Export plugin menu item string");
}

/*
 
 export plist
 
 */
- (NSString *)exportPlist:(id)aPlist toPath:(NSString *)path
{
	BOOL success = NO;
	NSString *error = nil;
	
	@try {
		
		// make sure path is complete, including extension
		path = [self completePath:path];
		
		NSData *data = [self exportPlistAsData:aPlist];
		
		// write it
		if (data) {
			success = [data writeToFile:path atomically:YES];
		} else {
			error = NSLocalizedString(@"Invalid YAML data", @"YAML data error");
		}
		
	} @catch (NSException *e) {
		[self onException:e path:path];
	}
	
	return success ? path : nil;	
}

/*
 
 export plist as data
 
 */
- (NSData *)exportPlistAsData:(id)aPlist
{
	NSString *error = nil;
	
	@try {
		
		// aPlist must be a plist type
		if (![NSPropertyListSerialization propertyList:aPlist isValidForFormat:NSPropertyListXMLFormat_v1_0]) {
			return nil;
		}		
		
		// ??
		if (NO) {
			NSDictionary *dictionary = nil;
			if ([aPlist isKindOfClass:[NSDictionary class]]) {
				dictionary = aPlist;
			} else {
				dictionary = [NSDictionary dictionaryWithObjectsAndKeys: aPlist, @"item", nil];
			}
		}
		
		
		// get our YAML emitter
		YKEmitter *emitter = [[YKEmitter alloc] init];
		[emitter setEncoding:NSUTF8StringEncoding];
		[emitter emitItem: aPlist];
		
		return [emitter emittedData];
		
	} @catch (NSException *e) {
		[self onException:e];
	}
	
	if (error) {
		[self onErrorString:error];
	}
	
	return nil;
}


@end
