//
//  MGSResultFileScriptCommand.m
//  KosmicTask
//
//  Created by Jonathan on 10/06/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSResultFileScriptCommand.h"
#import "NSString_Mugginsoft.h"
#import "MGSTempStorage.h"

@implementation MGSResultFileScriptCommand

/*
 
 - performDefaultImplementation
 
 */
- (id)performDefaultImplementation
{
	// get path to temp file suitable for usage as a result file
	
	// get suffix parameter as argument
	NSString *suffix = [[self evaluatedArguments] objectForKey:@"file name"];
	if (!suffix) {
		suffix = @"";
	}
	
	// validate the suffix
	if (![suffix isKindOfClass:[NSString class]]) {
		// better to raise an error ?
		suffix = @"";
	}
		
	// get path
	NSString *filename = [NSString stringWithFormat:@"%@.%@", MGSKosmicTempFileNamePrefix, suffix];
	
	// this function is for cerating temp storage for server tasks hence ensure
	// that we use the server URL
	MGSTempStorage* tempStorage = [[MGSTempStorage alloc] initWithReverseURL:@"com.mugginsoft.kosmictaskserver.files"];	
	NSString *path = [tempStorage storageFileWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:
																	  filename, MGSTempFileSuffix,
																	  nil]];
	
	// return value is a URL.
	// this will be corce to an AS file object
	NSURL *url = [NSURL fileURLWithPath:path];
	
	return url;
}

@end
