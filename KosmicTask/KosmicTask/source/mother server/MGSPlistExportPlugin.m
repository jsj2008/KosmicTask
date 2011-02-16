//
//  MGSPlistExportPlugin.m
//  Mother
//
//  Created by Jonathan on 21/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSPlistExportPlugin.h"


@implementation MGSPlistExportPlugin

/* 
 
 file extension
 
 */
- (NSString *)fileExtension
{
	return @"plist";
}

/* 
 
 menu item string
 
 */
- (NSString *)menuItemString
{
	return NSLocalizedString(@"Property List (plist)", @"Export plugin menu item string");
}

/* 
 
 display menu item string
 
 */
- (NSString *)displayMenuItemString
{
	return NSLocalizedString(@"plist", @"Export plugin menu item string");
}

/*
 
 export plist
 
 */
- (NSString *)exportPlist:(id)aPlist toPath:(NSString *)path
{
	BOOL success = NO;
	
	@try {
				
		// make sure path is complete, including extension
		path = [self completePath:path];
		
		NSData *data = [self exportPlistAsData:aPlist];;
		
		// write it
		if (data ) {
			success = [data writeToFile:path atomically:YES];
			
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
		
		NSData *data = [NSPropertyListSerialization dataFromPropertyList:aPlist format:NSPropertyListXMLFormat_v1_0 errorDescription:&error];
		// return it
		if (data && !error) {
			return data;
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
