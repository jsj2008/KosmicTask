//
//  MGSExcelSendPlugin.m
//  Mother
//
//  Created by Jonathan on 21/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSExcelSendPlugin.h"

@implementation MGSExcelSendPlugin

/*
 
 target app name
 
 */
- (NSString *)targetAppName
{
	return @"Excel.app";
}

/* 
 
 menu item string
 
 */
- (NSString *)menuItemString
{
	return NSLocalizedString(@"Excel", @"Send plugin menu item string");
}

/*
 
 bundle identifier
 
 */
- (NSString *)bundleIdentifier
{
	return @"com.microsoft.Excel";
}

/*
 
 execute send
 
 will be executed in a separate thread via NSOperationQueue
 
 */
- (BOOL)executeSend:(NSAttributedString *)aString
{	
	BOOL success = NO;
	
	@try {	 
		// copy string to pasteboard
		[self copyToPasteboardAsRTF:aString];
		
		// use AppleScript to paste in formatted text
		NSString *script = @"\
		tell application \"Microsoft Excel\"\n\
			activate\n\
			set newDoc to make new document\n\
			activate object sheet \"Sheet1\"\n\
			activate object column 1\n\
			paste worksheet active sheet destination active cell\n\
		end tell";
		
		success = [self executeAppleScript:script];
		
	} @catch (NSException *e) {
		[self onException:e];
	}
	
	return success;
	
}
@end
