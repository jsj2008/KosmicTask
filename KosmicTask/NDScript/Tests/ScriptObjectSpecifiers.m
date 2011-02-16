/*
 *  ScriptObjectSpecifiers.m
 *  NDScriptTest
 *
 *  Created by Nathan Day on 28/12/04.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "ScriptObjectSpecifiers.h"
#import "LoggingObject.h"

@implementation ScriptObjectSpecifiers

/*
 * -run
 */
- (void)run
{
	NDScriptContext	* theScriptA = [NDScriptContext scriptDataWithSource:@"to testProcedure(aSpecifier, aMessage)\n\tusing terms from application \"NDScriptTest\"\n\t\tdisplay aSpecifier message aMessage\n\tend using terms from\nend testProcedure\n"],
							* theAChildScript = [NDScriptContext scriptDataWithSource:@"using terms from application \"NDScriptTest\"\n\tto testProcedure(aMessage)\n\t\tdisplay message aMessage\n\tend testProcedure\nend using terms from\n"],
							* theScriptB = [NDScriptContext scriptDataWithSource:@"to testProcedure(anEntry)\n\ttell application \"NDScriptTest\"\n\t\tset theMessage to message of anEntry\n\t\tdisplay logging message \"Previous Message was '\" & theMessage & \"'\"\n\tend tell\nend testProcedure\n"],
							* theScriptC = [NDScriptContext scriptDataWithSource:@"tell application \"NDScriptTest\" to return logging"],
							* theScriptD = [NDScriptContext scriptDataWithSource:@"tell application \"NDScriptTest\" to return second entry of logging"],
							* theScriptE = [NDScriptContext scriptDataWithSource:@"using terms from application \"NDScriptTest\"\n\ton run\n\t\tmessageToMe(\"Message To Me\")\n\t\tmessageToLogging(\"Message To Logging\")\n\tend run\n\tto messageToMe(aMessage)\n\t\tdisplay message aMessage\n\tend messageToMe\n\tto messageToLogging(aMessage)\n\t\ttell application \"NDScriptTest\"\n\t\t\tdisplay logging message aMessage\n\t\tend tell\n\tend messageToLogging\n\ton display message aMessage\n\t\tcontinue display message \"Continued message '\" & aMessage & \"'\"\n\tend display\nend using terms from\n"];
	if( theScriptA )
	{
		[log logFormat:@"Passing log %@ to  %@", [NSAppleEventDescriptor descriptorWithObject:log], theScriptA];
		if( ![theScriptA executeSubroutineNamed:@"testProcedure" arguments:log, @"output to passed in script object specifier", nil] )
			[log errorFormat:@"Failed to execute hander in %@", theScriptA];
	}
	else
		[log errorMessage:@"Failed to create script context A"];
	
	if( theAChildScript )
	{
		[log logFormat:@"Setting parent of %@ to log %@", theAChildScript, [NSAppleEventDescriptor descriptorWithObject:log]];
		if( [theAChildScript setParentObject:log] )
		{
			[log logFormat:@"Passing log to %@", theAChildScript];
			if( ![theAChildScript executeSubroutineNamed:@"testProcedure" arguments:@"output to passed in script object specifier with log as parent", nil] )
				[log errorFormat:@"Failed to execute hander in %@", theAChildScript];
		}
		else
			[log errorFormat:@"Failed to set parent of %@", theAChildScript];
	}
	else
		[log errorMessage:@"Failed to create child script context"];
	
	if( theScriptB )
	{
		[log logFormat:@"Passing log entry %@ to %@", [NSAppleEventDescriptor descriptorWithObject:[[log orderedEntries] lastObject]], theScriptB];
		if( ![theScriptB executeSubroutineNamed:@"testProcedure" arguments:[[log orderedEntries] lastObject], nil] )
			[log errorFormat:@"Failed to execute hander in %@", theScriptB];
	}
	else
		[log errorMessage:@"Failed to create script context B"];
	
	if( theScriptC )
	{
		[log logFormat:@"Attempt to get logging object with '%@'", theScriptC];
		if( [theScriptC execute] )
		{
			id	theResult = [theScriptC resultObject];
			if( theResult )
				[log logFormat:@"Got result '%@'", theResult];
			else
				[log errorFormat:@"Failed to get result from %@", theScriptC];
		}
		else
			[log errorFormat:@"Failed to execute C %@", theScriptC];
	}
	else
		[log errorMessage:@"Failed to create script context C"];
	
	if( theScriptD )
	{
		[log logFormat:@"Attempt to get 2nd logging entry with '%@'", theScriptD];
		if( [theScriptD execute] )
		{
			id	theResult = [theScriptD resultObject];
			if( theResult )
				[log logFormat:@"Got result '%@'", theResult];
			else
				[log errorFormat:@"Failed to get result from %@", theScriptD];
		}
		else
			[log errorFormat:@"Failed to execute script context D %@", theScriptD];
	}
	else
		[log errorMessage:@"Failed to create script context D"];
	
	if( theScriptE )
	{
		[log logFormat:@"Setting parent of  '%@' to logging object", theScriptE];
		if( [theScriptE setParentObject:log] )
		{
			[log logMessage:@"executing run handler for script context E"];
			if( ![theScriptE execute] )
				[log errorMessage:@"Failed to execute run handler for script context E."];				
		}
		else
			[log errorMessage:@"Failed to set parent of script context E to log."];
	}
	else
		[log errorMessage:@"Failed to create script context E"];

	[self finished];
}

@end
