/*
 *  ReturningTypes.m
 *  NDScriptTest
 *
 *  Created by Nathan Day on 22/12/04.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "ReturningTypes.h"
#import "LoggingObject.h"


@implementation ReturningTypes

/*
 * -run
 */
- (void)run
{
	id		theResult = nil,
			theScript = nil;
	
	[log logMessage:@"Return a string"];
	theResult = [[NDScriptContext compileExecuteSource:@"return \"String Result\""] objectValue];
	[log logFormat:@"Executing return string script returned <%@>\"%@\"", [theResult class], theResult];

	[log logMessage:@"Return a number"];
	theResult = [[NDScriptContext compileExecuteSource:@"return 3.1415"] objectValue];
	[log logFormat:@"Executing return number script returned <%@>%@", [theResult class], theResult];
	
	[log logMessage:@"Return a list"];
	theResult = [[NDScriptContext compileExecuteSource:@"return { \"String Result\", 3.1415 }"] objectValue];
	[log logFormat:@"Executing return list script returned <%@>%@", [theResult class], theResult];
	
	[log logMessage:@"Return a record"];
	theResult = [[NDScriptContext compileExecuteSource:@"return { name:\"String Result\", aNumber:3.1415, anArray:( 1,2) }"] objectValue];
	[log logFormat:@"Executing return record script returned <%@>%@", [theResult class], theResult];

	[log logMessage:@"Return a script context"];
	theResult = [[NDScriptContext compileExecuteSource:@"script TestScript\n\ton run\n\t\ttell application \"NDScriptTest\" to display logging message \"script context result\"\n\tend run\nend script\nreturn TestScript\n"] objectValue];
	[log logFormat:@"Executing return 'script context' script returned <%@>%@", [theResult class], theResult];
	[theResult execute];

	[log logMessage:@"Return a script handler"];
	theScript = [NDScriptContext scriptDataWithSource:@"to testHandler()\n\ttell application \"NDScriptTest\" to display logging message \"script handler result\"\nend testHandler\non run\n\treturn testHandler\nend run\n"];
	if( [theScript execute] )
	{
		theResult = [theScript resultScriptData];
		[log logFormat:@"Executing return handler script returned <%@>%@", [theResult class], theResult];
		if( ![[NDScriptContext scriptData] executeScriptHandler:theResult] )
			[log errorMessage:@"Failed to execute returned script handler"];
	}
	else
		[log errorMessage:@"Failed to execute script to return script handler"];
	
	[log logMessage:@"Return a reference"];
	theResult = [[NDScriptContext compileExecuteSource:@"tell application \"NDScriptTest\" to return a reference to name\n"] objectValue];
	if( theResult )
		[log logFormat:@"Executing return reference script returned <%@>%@", [theResult class], theResult];
	else
		[log errorMessage:@"Failed to get result logging event"];

	[self finished];
}

@end
