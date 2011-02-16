//
//  MGSNetMessage+KosmicTask.m
//  KosmicTask
//
//  Created by Jonathan on 26/12/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSNetMessage+KosmicTask.h"
#import "MGSScriptPlist.h"
#import "MGSScript.h"

@implementation MGSNetMessage (KosmicTask)

/*
 
 validate
 
 */
- (BOOL)validate
{
	NSString *exceptionName = @"MGSNetRequestValidateException";
	
	// validate command
	NSString *command = [self command];
	if (!command) {
		[NSException raise:exceptionName format:@"Command missing."];
	}
	if (![[[self class] commands] containsObject:command]) {
		[NSException raise:exceptionName format:@"Invalid command: %@.", command];	
	}
	
	// validate the KosmicTask dict
	if ([command isEqualToString:MGSNetMessageCommandParseKosmicTask]) {
		
		// get the task dictionary from the request
		NSDictionary *taskDict = [self messageObjectForKey:MGSScriptKeyKosmicTask];
		if (!taskDict) {
			[NSException raise:exceptionName format:@"KosmicTask dictionary missing"];
		}
		
		// the command is mandatory
		NSString *scriptCommand = [taskDict objectForKey:MGSScriptKeyCommand];
		if (!scriptCommand) {
			[NSException raise:exceptionName format:@"KosmicTask dictionary command missing"];
		}
		
	}
	
	return YES;
}


@end
