//
//  MGSAppleScriptCocoaRunner.m
//  KosmicTask
//
//  Created by Jonathan on 27/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//
#import "MGSAppleScriptCocoaRunner.h"
#import "MGSASObjCScriptManager.h"
#import <AppleScriptObjC/AppleScriptObjC.h>
#import <OSAKit/OSAKit.h>
#import "TaskRunner.h"
#import "MGSAppleScriptCocoaLanguage.h"
/*
 
 ASObjC requires GC
 
 */
@implementation MGSAppleScriptCocoaRunner


#pragma mark -
#pragma mark Operations

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSAppleScriptCocoaLanguage class];
}

/*
 
 - execute
 
 */

- (BOOL) execute
{
	return [self executeWithManager:[MGSASObjCScriptManager sharedManager]];
}

/*
 
 - buildOptions
 
 */
- (NSMutableArray *)buildOptions
{
	NSMutableArray *options = [super buildOptions];
	/*
	 
	 returns on stderr:
	 	 
	 filename : error description
	 
	 */
	outputFilePath = [self workingFilePathWithExtension:self.scriptExecutableExtension];
	[options addObjectsFromArray: [NSArray arrayWithObjects:@"-o", outputFilePath, nil]];
	return options; 
}

/*
 
 - parseCompileResult:
 
 */
- (BOOL) processBuildResult:(NSString *)resultString
{
	BOOL tempFileExists = NO;
	
	// non zero compile result is an error
	if ([resultString length] > 0) {
		self.error = resultString;
		goto exitHandler;
	} 
	
	// look at stderr
	if (self.stderrData) {
		NSString *stdErrString = [[NSString alloc] initWithData:self.stderrData encoding:NSUTF8StringEncoding];
		
		if (stdErrString && [stdErrString length] > 0) {
			self.error = stdErrString;
			goto exitHandler;
		}
	}
	
	// look for compiled file at outputFilePath
	if (![[NSFileManager defaultManager] fileExistsAtPath:outputFilePath]) {
		self.error = [NSString stringWithFormat: @"compiled script file not found at %@", outputFilePath];
		goto exitHandler;
	}
	
	tempFileExists = YES;
	
	// get data
	NSURL *url = [NSURL fileURLWithPath:outputFilePath];
	NSData *scriptData = [NSData dataWithContentsOfURL:url];
	if (!scriptData) {
		self.error = NSLocalizedString(@"Compiled script source data is invalid", @"Compiled script source data is nil");
		goto exitHandler;
	}
	
	// get attributed source for compiled data
	NSDictionary *error = nil;
	OSAScript *script = [[OSAScript alloc] initWithContentsOfURL:url error:&error];
	if (error) {
		self.error = [NSString stringWithFormat: @"invalid compiled script file at %@", outputFilePath];
		goto exitHandler;
	}
	
	// get script attributed source
	NSAttributedString *attributedSource = [script richTextSource];

#define MGS_RETURN_SOURCE_AS_RTF
#ifdef MGS_RETURN_SOURCE_AS_RTF
	
	// get RTF
	NSRange range = NSMakeRange(0, [attributedSource length]);
	NSData *rtfSource = [attributedSource RTFFromRange:range documentAttributes:nil];
	if (!rtfSource) {
		self.error = NSLocalizedString(@"Compiled script source is invalid", @"Compiled script source is nil");
		goto exitHandler;
	} 

	// return the rtf source
	[self.replyDict setObject:rtfSource forKey:MGSScriptKeyCompiledScriptSourceRTF];

#else
	
	NSString *source = [attributedSource string];
	if (nil == source) {
		self.error = NSLocalizedString(@"Compiled script source is invalid", @"Compiled script source is nil");
		return NO;
	}
	
	// return the string source
	[self.replyDict setObject:source forKey:MGSScriptKeyScriptSource];
	
#endif
	
	// compiled data
	[self.replyDict setObject:scriptData forKey:MGSScriptKeyCompiledScript];
	
exitHandler:

	// delete the compiled data file
	if (tempFileExists) {
		[[NSFileManager defaultManager] removeItemAtPath:outputFilePath error:nil];
	}
	
	// pass stderr data back to caller
	//[(NSFileHandle *)[NSFileHandle fileHandleWithStandardError] writeData:self.stderrData];
	
	return (self.error ? NO : YES);
	
}

@end


