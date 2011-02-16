//
//  MGSXMLExportPlugin.m
//  Mother
//
//  Created by Jonathan on 21/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSXMLExportPlugin.h"
//#import "NSDictionary+XMLPersistence.h"
//#import "UKXMLPersistence.h"
#import "NSPropertyListSerialization_Mugginsoft.h"

@implementation MGSXMLExportPlugin

/* 
 
 file extension
 
 */
- (NSString *)fileExtension
{
	return @"xml";
}

/* 
 
 menu item string
 
 */
- (NSString *)menuItemString
{
	return NSLocalizedString(@"XML", @"Export plugin menu item string");
}

/* 
 
 display menu item string
 
 */
- (NSString *)displayMenuItemString
{
	return NSLocalizedString(@"xml", @"Export plugin menu item string");
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
			error = NSLocalizedString(@"Invalid XML data", @"XML data error");
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
		
		NSDictionary *dictionary = nil;
		if ([aPlist isKindOfClass:[NSDictionary class]]) {
			dictionary = aPlist;
		} else {
			dictionary = [NSDictionary dictionaryWithObjectsAndKeys: aPlist, @"item", nil];
		}
		
		// form xml document from plist
		NSXMLDocument *xmlDoc = [NSPropertyListSerialization XMLDocumentFromPropertyList:aPlist format:nil errorDescription:&error];
		if (xmlDoc && !error) {
			return [xmlDoc XMLDataWithOptions:NSXMLNodePrettyPrint];
		}
	} @catch (NSException *e) {
		[self onException:e];
	}
	
	if (error) {
		[self onErrorString:error];
	}
	
	return nil;
}

@end
