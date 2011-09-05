//
//  MGSCodeSigning.m
//  Mother
//
//  Created by Jonathan on 27/10/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSCodeSigning.h"
#import "MGSPath.h"
#include <dlfcn.h>

@implementation MGSCodeSigning

@synthesize resultString = _resultString;

/*
 
 validate executable
 
 */
- (CodesignResult)validateExecutable
{
    // also see [MGSPath bundleExecutable]
    Dl_info info;	
	int errDlAddr = dladdr( (const void *)__func__, &info );
    if(errDlAddr == 0) {
		return CodesignError;
    }
	char *exec_path = (char *)(info.dli_fname);
	
	NSString *path = [NSString stringWithCString:exec_path encoding:NSUTF8StringEncoding];
	return [self validatePath:path];
}
/*
 
 validate this application
 
 */
- (CodesignResult)validateApplication
{
	return [self validatePath:[MGSPath bundlePath]];
}
/*
 
 validate path
 
 */
- (CodesignResult)validatePath:(NSString *)path
{
	self.resultString = nil;
	int status = CodesignError;
	
	@try {
		NSArray *arguments = [NSArray arrayWithObjects: @"--verify", path,  nil];
		NSTask *task = [[NSTask alloc] init];
		
		[task setArguments:arguments];
		[task setLaunchPath:@"/usr/bin/codesign"];
		[task setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];	
		[task setStandardError:[NSFileHandle fileHandleWithNullDevice]];	
		[task launch];
		[task waitUntilExit];
		status = [task terminationStatus];
		
		switch (status) {
			case CodesignOkay:
				self.resultString = NSLocalizedString(@"Valid", @"Codesign okay.");
				break;
				
			case CodesignFail:
				self.resultString = NSLocalizedString(@"Invalid", @"Codesign failed.");
				break;
				
			case CodesignInvalidArgs:
				self.resultString = NSLocalizedString(@"Invalid arguments", @"Codesign invalid arguments");
				break;
				
			case CodesignFailedRequirement:
				self.resultString = NSLocalizedString(@"Failed requirement", @"Codesign failed requirement.");
				break;
			
			default:
				self.resultString = NSLocalizedString(@"Unrecognised response", @"Codesign unrecognised response.");
				status = CodesignUnrecognised;
				break;
				
		}
		
		if (status != CodesignOkay) {
			NSLog(@"codesign failure: %@", self.resultString);
		}
		
		
	}@catch (NSException *e) {
		NSLog(@"Exception launching codesign: %@", [e reason]);
		return CodesignError;
	}
	
	return status;
}

@end
