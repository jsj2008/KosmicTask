/*
 *  SettingParent.m
 *  NDScriptTest
 *
 *  Created by Nathan Day on 20/12/04.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "SettingParent.h"
#import "LoggingObject.h"

@implementation SettingParent

- (id)init
{
	if( (self = [super init]) != nil )
	{
		componentInstance = [[NDComponentInstance alloc] init];
	}
	return self;
}

- (void)run
{
	NDScriptContext		* theBaseA = nil,
								* theParentA = nil,
								* theChildA = nil;
	[log logMessage:@"Creating base script with property 'rec' and handlers 'getRecOne' and 'getRecTwo'"];
	theBaseA = [self scriptWithSource:@"property rec : {one:1, two:2}\nto stringForNumber( aNumber )\n\treturn item aNumber of {\"one\",\"two\",\"three\",\"four\",\"five\",\"six\",\"seven\"}\nend\nto getRecOne()\n\treturn one of rec\nend getRecOne\nto getRecTwo()\n\treturn two of rec\nend getRecTwo\non run\n\tset theValueOne to getRecOne()\n\tset theValueTwo to getRecTwo()\n\ttell application \"NDScriptTest\" to display logging message \"The value of one is \" & theValueOne & \",\" & return & \"the value of two is \" & theValueTwo\nend run\n"];
	if( theBaseA )
	{
		[log logMessage:@"Creating parent script with handler 'getRecTwo' and setting its parent"];
		theParentA = [self scriptWithSource:@"to getRecTwo()\n\treturn \"number \" & stringForNumber( continue getRecTwo() )\nend getRecTwo\n"];
		if( theParentA )
		{
			[theParentA setParentScriptData:theBaseA];
			[log logMessage:@"Executing base"];
			if( ![theBaseA execute] )
				[log errorMessage:@"Failed to execute base"];
			
			[log logMessage:@"Executing parent with handler 'getRecTwo'"];
			if( ![theParentA execute] )
				[log errorMessage:@"Failed to execute parent"];

			[log logMessage:@"Creating child script with parent"];
			theChildA = [NDScriptContext scriptDataWithParentScriptData:theParentA];
			
			if( theChildA )
			{
				[log logMessage:@"Augmenting child script with handler 'getRecOne'"];
				if( [theChildA augmentWithSource:@"to getRecOne()\n\treturn \"number \" & stringForNumber( continue getRecOne() )\nend getRecOne\n"] )
				{
					[log logMessage:@"Executing child with handler 'getRecOne'"];
					if( ![theChildA execute] )
						[log errorMessage:@"Failed to execute child"];					
				}
				else
					[log errorMessage:@"Faild to augment child script context"];
			}
			else
				[log errorMessage:@"Failed to get child script"];
		}
		else
			[log errorMessage:@"Failed to create parent"];
	}
	else
		[log errorMessage:@"Failed to create base"];
	[self finished];
}

- (NDScriptContext *)scriptWithSource:(NSString *)aSource
{
	return [NDScriptContext scriptDataWithSource:aSource componentInstance:componentInstance];
}

@end
