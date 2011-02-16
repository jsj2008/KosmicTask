/*
 *  ScriptDataPassing.m
 *  NDScriptTest
 *
 *  Created by Nathan Day on 18/12/04.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "ScriptDataPassing.h"
#import "LoggingObject.h"

@implementation ScriptDataPassing

- (void)run
{
	NDScriptContext	* theContextA = [NDScriptContext scriptDataWithSource:@"on run\n\treturn { name: \"Albert\", item_b: \"Betty\"}\nend run\n"],
							* theContextB = [NDScriptContext scriptDataWithSource:@"property rec :  {name: \"null\",item_b: \"null\"}\non run\n\ttell application \"NDScriptTest\" to display logging message  \"item a equals \" & name of rec & return & \"item b equals \" & item_b of rec\nend run\n"],
							* theContextC = [NDScriptContext scriptDataWithSource:@"to oputToLog(aLog, aMessage)\n\tusing terms from application \"NDScriptTest\"\n\t\tdisplay aLog message aMessage\n\tend using terms from\nend oputToLog\n"];
	NDScriptData		* theData = [NDScriptData scriptDataWithObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Carl",[NSValue valueWithAEKeyword:keyAEName],@"Debbie",@"item_b", nil]],
							* theLogObject = [NDScriptContext compileExecuteSource:@"tell application \"NDScriptTest\"\n\treturn logging\nend tell\n"];
	
	if( [theContextA isCompiledScript] )
	{
	[log logMessage:@"Executing script which returns record"];
		if( [theContextA execute] )
		{
			NDScriptData	* theResult = [theContextA resultScriptData];
			if( [theResult isValue] )
			{
				[log logMessage:@"Setting property 'rec' of test script to result and executing"];
				if( [theContextB setPropertyNamed:@"rec" toScriptData:theResult] )
				{
					if( ![theContextB execute] )
						[log errorMessage:@"Execution of B failed"];
				}
				else
					[log errorMessage:@"Setting with result failed"];
			}
			else
				[log errorFormat:@"Script result %@, is not a value", theResult];
		}
		else
			[log errorMessage:@"Execution of A failed"];
		
		if( [theData isValue] )
		{
			[log logMessage:@"Setting property 'rec' of test script to script data created from NSDictionary and executing"];
			if( [theContextB setPropertyNamed:@"rec" toScriptData:theData] )
			{
				if( ![theContextB execute] )
				{
					[log errorFormat:@"Execution of B failed, %@", [[[theContextB componentInstance] error] descriptionInStringsFileFormat]];
				}
			}
			else
				[log errorMessage:@"Setting with data failed."];
		}
		else
			[log errorFormat:@"Script data %@, is not a value", theData];
	}
	else
		[log errorFormat:@"Script Context %@, is not a compiled AppleScript", theContextB];
	
	if( theLogObject )
	{
		[log logFormat:@"Passing data '%@' to script\n%@", theLogObject, [theLogObject appleEventDescriptorValue]];
		if( ![theContextC executeSubroutineNamed:@"oputToLog" arguments:theLogObject, @"output with reference", nil] )
			[log errorMessage:@"Failed to pass script data containing reference to log out instance"];
	}
	else
		[log errorMessage:@"Failed to create script to receive reference to log out instance"];		

	[self finished];
}

@end
