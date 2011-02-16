//
//  MGSPlainTextExportPlugin.m
//  Mother
//
//  Created by Jonathan on 20/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSPlainTextExportPlugin.h"


@implementation MGSPlainTextExportPlugin

/* 
 
 file extension
 
 */
- (NSString *)fileExtension
{
	return @"txt";
}

/* 
 
 menu item string
 
 */
- (NSString *)menuItemString
{
	return NSLocalizedString(@"Plain Text (txt)", @"Export plugin menu item string");
}

/*
 
 export string
 
 */
- (NSString *)exportString:(NSString *)aString toPath:(NSString *)path
{
	BOOL success = NO;
	NSError *error = nil;
	
	@try {
		
		// make sure path is complete, including extension
		path = [self completePath:path];
		
		// write it
		success = [aString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
		
	} @catch (NSException *e) {
		[self onException:e path:path];
	}
	
	if (error) {
		[self onError:error];
	}
	
	return success ? path : nil;
}
@end
