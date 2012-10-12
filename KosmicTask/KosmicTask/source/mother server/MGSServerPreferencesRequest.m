//
//  MGSServerPreferencesRequest.m
//  Mother
//
//  Created by Jonathan on 29/03/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSServerPreferencesRequest.h"
#import "MGSError.h"
#import "MGSNetMessage.h"
#import "MGSNetRequest.h"
#import "MGSPreferences.h"
#import "NSObject_Mugginsoft.h"
#import "MGSNetServerHandler.h"

@implementation MGSServerPreferencesRequest

/*
 
 parse preferences dictionary
 
 */
+ (BOOL)parseDictionary:(NSDictionary *)preferences
{
	MGSPreferences *defaults = [MGSPreferences standardUserDefaults];
	[defaults synchronize];	// make sure we are current
	
	BOOL updateDNSTxtRecord = NO;
	
	// keys are also preference keys.
	// test all key values for changes from current value
	NSArray *keys = [preferences allKeys];
	for (NSString *key in keys) {
		
		id object = [preferences objectForKey:key];
		
		// SSL security
		if ([key isEqualToString:MGSEnableServerSSLSecurity]) {
			
			BOOL useSSL = [object boolValue];
			if (useSSL != [defaults boolForKey:key]) {
				[defaults setObject:object forKey:key];
				updateDNSTxtRecord = YES;
			}
			
			continue;
		}
	
		// user name disclosure
		if ([key isEqualToString:MGSUsernameDisclosureMode]) {
			
			NSInteger usernameDisclosureMode = [object integerValue];
			if (usernameDisclosureMode != [defaults integerForKey:key]) {
				[defaults setObject:object forKey:key];
				updateDNSTxtRecord = YES;
			}
			
			continue;
		}
		
        // set the preference
        [defaults setObject:object forKey:key];
	}
				 
	[defaults synchronize];	// sync so that the client sees the same thing
	
	// update DNS txt record if required.
	// this will inform all clients of changes that
	// affect their interaction with the server, such as the server SSL status
	if (updateDNSTxtRecord) {
		[[MGSNetServerHandler sharedController] updateTXTRecord];
	}
	
	return YES;
}


@end
