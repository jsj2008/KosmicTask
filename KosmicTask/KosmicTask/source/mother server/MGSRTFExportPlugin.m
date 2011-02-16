//
//  MGSRTFExportPlugin.m
//  Mother
//
//  Created by Jonathan on 19/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSRTFExportPlugin.h"

@implementation MGSRTFExportPlugin

/*
 
 is default
 
 */
- (BOOL)isDefault
{
	return YES;
}

/* 
 
 file extension
 
 */
- (NSString *)fileExtension
{
	return @"rtf";
}

/*
 
 export attributed string
 
 */
- (NSString *)exportAttributedString:(NSAttributedString *)aString toPath:(NSString *)path
{
	BOOL success = NO;
	
	@try {
		
		// make sure path is complete, including extension
		path = [self completePath:path];
		
		volatile NSRange range = NSMakeRange(0, [aString length]);
		
		// use NSText -RTFFromRange to strip attachment characters
		NSData *dataRTF = [aString RTFFromRange:range documentAttributes:nil];
		
		// write it
		success = [dataRTF writeToFile:path atomically:YES];
		
	} @catch (NSException *e) {
		[self onException:e path:path];
	}
	
	return success ? path : nil;
}

/* 
 
 menu item string
 
 */
- (NSString *)menuItemString
{
	return NSLocalizedString(@"Rich Text Format (RTF)", @"Export plugin menu item string");
}

/* 
 
 display menu item string
 
 */
- (NSString *)displayMenuItemString
{
	return NSLocalizedString(@"text", @"Export plugin menu item string");
}

/*
 
 is display default
 
 */
- (BOOL)isDisplayDefault
{
	return YES;
}
@end
