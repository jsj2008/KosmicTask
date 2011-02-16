/*!
	@header SendAppleEventTest.h
	@abstract Header file from the project NDScriptData
	@discussion <#Discussion»
 
	Created by Nathan Day on 26/03/05.
	Copyright &#169; 2003 Nathan Day. All rights reserved.
 */
#import <Cocoa/Cocoa.h>
#import "BaseTestClass.h"
#import "NDScript.h"

@class	NDScriptContext;

@interface SendAppleEventTarget : NSObject <NDScriptDataSendEvent>
{
@protected
	NDScriptContext		* script;
	NSString					* message;
	BaseTestClass			* owner;
}
+ (id)sendAppleEventTargetWithMessage:(NSString *)message owner:(id)anOnwer;
- (id)initWithMessage:(NSString *)aMessage owner:(id)anOwner;
- (void)run;
- (void)threadEntry:(id)message;
- (NDScriptContext *)script;
@end

/*!
	@class SendAppleEventTest
	@abstract <#Abstract#>
	@discussion <#Discussion#>
 */
@interface SendAppleEventTest : BaseTestClass
{
	NSArray					* scriptRunner;
	SInt32					inProgressThreads;
}

- (SendAppleEventTarget *)sendAppleEventTargetWithMessage:(NSString *)aMessage;

@end
