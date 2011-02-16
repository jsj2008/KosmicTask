//
//  NSNetServices_Errors.m
//  Mother
//
//  Created by Jonathan on 19/11/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//
#import <Foundation/NSNetServices.h>
#import "NSNetService_Errors.h"

@implementation NSNetService (Errors)

+ (NSString *)errorDictString:(NSDictionary *)errors
{
	NSString *error;


	NSNetServicesError errorNumber = [[errors objectForKey:NSNetServicesErrorCode] intValue];
	// NSInteger errorDomain = [[errors objectForKey:NSNetServicesErrorDomain] intValue];
	
	switch (errorNumber) {
			
		case NSNetServicesCollisionError:    
			error = @"An NSNetService with the same domain, type and name was already present when the publication request was made.";
			break;
			
		case   NSNetServicesNotFoundError:  
			error = @"The NSNetService was not found when a resolution request was made.";
			break;
			
		case NSNetServicesActivityInProgress:    
			error = @"A publication or resolution request was sent to an NSNetService instance which was already published or a search request was made of an NSNetServiceBrowser instance which was already searching.";
			break;
			
		case NSNetServicesBadArgumentError:    
			error = @"An required argument was not provided when initializing the NSNetService instance.";
			break;
			
		case NSNetServicesCancelledError:	
			error = @"The operation being performed by the NSNetService or NSNetServiceBrowser instance was cancelled.";
			break;
			
		case NSNetServicesInvalidError:
			error = @"An invalid argument was provided when initializing the NSNetService instance or starting a search with an NSNetServiceBrowser instance.";
			break;
			
		case NSNetServicesTimeoutError:    
			error = @"Resolution of an NSNetService instance failed because the timeout was reached.";
			break;
			
		default:
			error = @"An unknown error occured during resolution or publication.";
			break;
	}
	
	return error;
}

@end
