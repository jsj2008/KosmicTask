//
//  MGSWordSendPlugin.m
//  Mother
//
//  Created by Jonathan on 21/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSWordSendPlugin.h"
//#import "NDScript.h"

@implementation MGSWordSendPlugin

/*
 
 target app name
 
 */
- (NSString *)targetAppName
{
	return @"Word.app";
}

/*
 
 bundle identifier
 
 */
- (NSString *)bundleIdentifier
{
	return @"com.microsoft.Word";
}
/* 
 
 menu item string
 
 */
- (NSString *)menuItemString
{
	return NSLocalizedString(@"Word", @"Send plugin menu item string");
}

/*
 
 send string
 
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
							tell application \"Microsoft Word\"\n\
								activate\n\
								set newDoc to make new document\n\
								set docEnd to end of content of text object of active document\n\
								tell selection\n\
									set {selection start, selection end} to {docEnd, docEnd}\n\
									paste object\n\
								end tell\n\
							end tell";
		// note that there are issues running AppleScript in a GC app!
		// http://www.cocoabuilder.com/archive/message/cocoa/2008/4/22/204897
		// apparently resolved in 10.5.3
		// problems were encountered in the script runner but not here so far.
		// NDScript can no longer be used as it is now a RC library only (doesn't support GC).
		//[NDScriptContext compileExecuteSource:script componentInstance:nil];
		success = [self executeAppleScript:script];
				
	} @catch (NSException *e) {
		[self onException:e];
	}
	
	return success;
}
@end
