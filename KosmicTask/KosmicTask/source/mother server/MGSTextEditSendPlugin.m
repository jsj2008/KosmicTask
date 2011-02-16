//
//  MGSTextEditSendPlugin.m
//  Mother
//
//  Created by Jonathan on 21/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSTextEditSendPlugin.h"
#import "TextEdit.h" // this is created dynamically by target build rule. Use file - open quickly... <name>.h to view.

@implementation MGSTextEditSendPlugin

/*
 
 target app name
 
 */
- (NSString *)targetAppName
{
	return @"TextEdit.app";
}

/*
 
 bundle identifier
 
 */
- (NSString *)bundleIdentifier
{
	return @"com.apple.TextEdit";
}

/*
 
 execute send
 
 will be executed in a separate thread via NSOperationQueue
 
 */
- (BOOL)executeSend:(NSAttributedString *)aString
{
	
	BOOL success = NO;
	
	@try {	 
		// activate app
		TextEditApplication *textEdit = [SBApplication applicationWithBundleIdentifier:[self bundleIdentifier]];
		[textEdit activate];
		
		// create document
		TextEditDocument *doc = [[[textEdit classForScriptingClass:@"document"] alloc] initWithProperties:
								 [NSDictionary dictionaryWithObjectsAndKeys: 
								  [aString string], @"text", nil]];
		[[textEdit documents] addObject:doc]; 
		
		// copy text to doc
		//TextEditText *text = [[doc classForScriptingClass:@""] init];
		//doc.text = text;
		success =  YES;
		
	} @catch (NSException *e) {
		[self onException:e];
	}
	
	return success;
}

/* 
 
 menu item string
 
 */
- (NSString *)menuItemString
{
	return NSLocalizedString(@"TextEdit", @"Send plugin menu item string");
}

@end
