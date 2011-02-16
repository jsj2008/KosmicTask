/*
 *  ScriptHandlerPassing.m
 *  NDScriptTest
 *
 *  Created by Nathan Day on 19/12/04.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "ScriptHandlerPassing.h"
#import "LoggingObject.h"
#import "NDProgrammerUtilities.h"

@implementation ScriptHandlerPassing

- (void)run
{
	NDScriptContext		* theContextA = [NDScriptContext scriptDataWithSource:@"property testWord : \"Hello\"\nto testHandler()\n\ttell application \"NDScriptTest\" to display logging message testWord\nend testHandler\n"],
								* theContextB = [NDScriptContext scriptDataWithSource:@"property testWord : \"Good Bye\"\n"],
								* theHandlerB = [NDScriptHandler scriptDataWithSource:@"to testHandler()\n\ttell application \"NDScriptTest\" to display logging message testWord\nend testHandler\n"];
	if( [theContextA isCompiledScript] )
	{
		if( [theContextA respondsToSubroutineNamed:@"testHandler"] )
		{
			[log logMessage:@"Getting handler from context with testWord = \"Hello\""];
			NDScriptHandler	* theHandlerA = [theContextA scriptHandlerForSubroutineNamed:@"testHandler"];
			if( [theHandlerA isCompiledScript] )
			{
				if( [theHandlerA hasScriptContext] )
					[log errorFormat:@"Script  handler A %@ has a context", theHandlerA];

				[log logMessage:@"Executing handler within context with testWord = \"Hello\""];
				if( ![theContextA executeScriptHandler:theHandlerA] )
					[log errorFormat:@"Failed to execute script handler %@ in script %@", theHandlerA, theContextA];
				
				[log logMessage:@"Executing handler within context with testWord = \"Good Bye\""];
				if( ![theContextB executeScriptHandler:theHandlerA] )
					[log errorFormat:@"Failed to execute script handler %@ in script %@", theHandlerA, theContextB];
			
				if( [theHandlerB isCompiledScript] )
				{
					if( [theHandlerB hasScriptContext] )
						[log errorFormat:@"Script  handler B %@ has a context", theHandlerB];
					
					[log logMessage:@"Executing compiled handler within context with testWord = \"Good Bye\""];
					if( ![theContextB executeScriptHandler:theHandlerB] )
						[log errorFormat:@"Failed to execute script handler %@ in script %@", theHandlerA, theContextA];
				}
				else
					[log errorFormat:@"Failed to compile handler B"];
			}
			else
				[log errorFormat:@"Failed to get handler A from %@", theContextA];
		}
		else
			[log errorFormat:@"The script %@ does not respond to testHandler", theContextA];
		
	}
	else
		[log errorMessage:@"Failed to compile context A"];

	[self finished];
}

@end
