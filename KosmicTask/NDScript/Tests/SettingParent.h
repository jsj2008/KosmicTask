/*!
	@header SettingParent.h
	@abstract Header file from the project NDScriptData
	@discussion <#DiscussionÈ
 
	Created by Nathan Day on 20/12/04.
	Copyright &#169; 2003 Nathan Day. All rights reserved.
 */
#import <Cocoa/Cocoa.h>
#import "BaseTestClass.h"
#import "NDScript.h"

@class		NDScriptContext,
				NDComponentInstance;

/*!
	@class SettingParent
	@abstract <#Abstract#>
	@discussion <#Discussion#>
 */
@interface SettingParent : BaseTestClass
{
@private
	NDComponentInstance		* componentInstance;
}

- (NDScriptContext *)scriptWithSource:(NSString *)source;

@end
