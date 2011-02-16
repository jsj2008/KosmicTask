/*!
	@header BaseTestClass.h
	@abstract Header file from the project NDScriptData
	@discussion <#DiscussionÈ
 
	Created by Nathan Day on 19/12/04.
	Copyright &#169; 2003 Nathan Day. All rights reserved.
 */
#import <Cocoa/Cocoa.h>
#import "NDScript.h"

@class		LoggingObject;

/*!
	@class BaseTestClass
	@abstract <#Abstract#>
	@discussion <#Discussion#>
 */
@interface BaseTestClass : NSObject
{
@protected
	LoggingObject		* log;
}

- (id)initWithLoggingObject:(LoggingObject *)object;
- (void)run;
- (void)finished;

@end
