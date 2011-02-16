//
//  NDScriptData_Mugginsoft.m
//  Mother
//
//  Created by Jonathan on 10/05/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "NDScriptData.h"
#import "NDScriptData_Mugginsoft.h"


@implementation NDScriptData (Mugginsoft)
/*
 * JM 18-03-08
 * GC mod
 * avoid activity in finalize
 * call dispose manually.
 */
-(void)dispose
{
	//if (_disposed) return;
	/*
	if( compiledScriptID != kOSANullScript )
	{
		OSADispose( [self scriptingComponent], compiledScriptID );
	}
	
	if( resultingValueID != kOSANullScript )
	{
		OSADispose( [self scriptingComponent], resultingValueID );
	}
	
	[componentInstance release];
	[scriptSource release];
	*/
	[super dealloc];
	
	//_disposed = YES;
}

// JM 18-03-08
- (NSAttributedString *)attributedSource
{
	CFAttributedStringRef result = nil;
	OSAError		theErr = noErr;
	 theErr = OSACopySourceString(
		 [self instanceRecord],
		 compiledScriptID,
		 kOSAModeNull,
		 &result); 
	//CFRetain(result);	// copy is already retained
	
	// CFAttributedStringRef is toll free bridged to NSAttributeString
	return (NSAttributedString *)result;
}


@end
