//
//  MGSPagesSendPlugin.m
//  Mother
//
//  Created by Jonathan on 22/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSPagesSendPlugin.h"
#warning broken - pages.h not available
//#import "Pages.h"

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
        #warning broken
/*
		// activate app
		PagesApplication *pages = [SBApplication applicationWithBundleIdentifier:[self bundleIdentifier]];
		[pages activate];
		
		// create document
		PagesDocument *doc = [[[pages classForScriptingClass:@"document"] alloc] initWithProperties:
							  [NSDictionary dictionaryWithObjectsAndKeys:  nil]];
		[[pages documents] addObject:doc];
        
        // iWork 13 removes a lot of scripting support
        SEL selSetBodyText = NSSelectorFromString(@"setBodyText");
        if ([doc respondsToSelector:selSetBodyText]) {
            [doc performSelector:selSetBodyText withObject:[aString string]];
            success =  YES;
        }
*/
		
	} @catch (NSException *e) {
		[self onException:e];
	}
	
	return success;
}

@end
