//
//  MGSPagesSendPlugin.m
//  Mother
//
//  Created by Jonathan on 22/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSPagesSendPlugin.h"
#import "Pages.h"

@implementation MGSPagesSendPlugin

/*
 
 target app name
 
 */
- (NSString *)targetAppName
{
	return @"Pages.app";
}

/*
 
 bundle identifier
 
 */
- (NSString *)bundleIdentifier
{
	return @"com.apple.iWork.Pages";
}

/* 
 
 menu item string
 
 */
- (NSString *)menuItemString
{
	return NSLocalizedString(@"Pages", @"Send plugin menu item string");
}

/*
 
 send string
 
 will be executed in a separate thread via NSOperationQueue
 
 */
- (BOOL)executeSend:(NSAttributedString *)aString
{
	BOOL success = NO;
	
	@try {	 
		// activate app
		PagesApplication *pages = [SBApplication applicationWithBundleIdentifier:[self bundleIdentifier]];
		[pages activate];
		
		// create document
		PagesDocument *doc = [[[pages classForScriptingClass:@"document"] alloc] initWithProperties:
							  [NSDictionary dictionaryWithObjectsAndKeys:  nil]];
		[[pages documents] addObject:doc];  
		[doc setBodyText:(PagesText *)[aString string]];	// warning here with NSString

		success =  YES;
		
	} @catch (NSException *e) {
		[self onException:e];
	}
	
	return success;
}

@end
