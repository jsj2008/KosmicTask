/*
 *  ProcedureCalling.m
 *  NDScriptTest
 *
 *  Created by Nathan Day on 21/12/04.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "ProcedureCalling.h"
#import "LoggingObject.h"

static NSString		* kTestScript = @"to positionalArguments(aFirstValue, aSecondValue)\n	tell application \"NDScriptTest\" to display logging message \"positionalArguments(\\\"\" & aFirstValue & \"\\\", \\\"\" & aSecondValue & \"\\\")\"\nend positionalArguments\n\nto labledArguments for anOfValue above anAboveValue aside from anAsideFromValue\n	tell application \"NDScriptTest\" to display logging message \"labledArguments of \\\"\" & anOfValue & \"\\\" above \\\"\" & anAboveValue & \"\\\" aside from \\\"\" & anAsideFromValue & \"\\\"\"\nend labledArguments\n";

@implementation ProcedureCalling

- (void)run
{
	NDScriptContext		* theTestScript = nil;
	[log logMessage:@"Creating script with a positional arguments procedure and a labled arguments procedure"];
	theTestScript = [NDScriptContext scriptDataWithSource:kTestScript];
	
	if( theTestScript )
	{
		[log logMessage:@"Calling procedure with positional arguments \"One\" and \"Two\""];
		if( ![theTestScript executeSubroutineNamed:@"positionalArguments" arguments:@"One",@"Two",nil] )
			[log errorMessage:@"Failed to call procedure with positional arguments"];
		
		[log logMessage:@"Calling procedure with labeled arguments for: \"One\", above: \"Two\" and aside from: \"Three\""];
		if( ![theTestScript executeSubroutineNamed:@"labledArguments" labelsAndArguments:keyASPrepositionFor,@"One",keyASPrepositionAbove,@"Two",keyASPrepositionAsideFrom,@"Three",nil] )
			[log errorMessage:@"Failed to call procedure with labled arguments"];
	}
	else
		[log errorMessage:@"Failed to create test script"];
	
	[self finished];
}

@end
