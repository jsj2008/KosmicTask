/*!
	@header NSApplication+AppleScript.h
	@abstract Header file for the project  NDScriptData.
	@discussion <#Discussion#>
 
	Created by Nathan Day on 17/12/04.
	Copyright &#169; 2002 Nathan Day. All rights reserved.
 */

#import <Cocoa/Cocoa.h>

@class		LoggingObject;

/*!
	@category NSApplication+AppleScript
	@abstract <#Abstract#>
	@discussion <#Discussion#>
 */
@interface NSApplication (AppleScript)

- (LoggingObject *)loggingObject;

@end
