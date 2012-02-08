//
//  MGSFScriptRunner.m
//  KosmicTask
//
//  Created by Jonathan on 31/07/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSFScriptRunner.h"
#import <FScript/FScript.h>
#import "BlockStackElem.h"	// on user search path
#import "NSError_Mugginsoft.h"
#import "MGSFScriptManager.h"
#import "MGSF_ScriptLanguage.h"

@implementation MGSFScriptRunner

/*
 
 - initWithDictionary
 
 designated initialiser
 
 */
- (id)initWithDictionary:(NSDictionary *)dictionary
{
	if ((self = [super initWithDictionary:dictionary])) {
		self.scriptExecutableExtension = @"fs";
		self.scriptSourceExtension = @"fs";
		
	}
	return self;
}

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSF_ScriptLanguage class];
}

/*
 
 - execute
 
 */
- (BOOL) execute
{
 
	// execute
	return [self executeWithManager:[MGSFScriptManager sharedManager]];
}

/*
 
 compile the task
 
 */
- (BOOL)build 
{
	// see the source for fscript shell 
	// http://pages.cs.wisc.edu/~weinrich/projects/fscript/#downloads
	// its GPL so we don't use it directly

	NSString *resultString = @"";

	// get script source
	NSString *source = [self scriptSourceWithError:YES];
	if (!source) return NO;
	
	@try {

		// make a block. raises on compilation or syntax error
		//
		// http://www.fscript.org/documentation/EmbeddingFScriptIntoCocoa/index.htm
		//
		/*
         From the F-script mailing list:
         
         An alternative, that avoid touching private APIs, is to use the method
         "asBlockOnError:" defined in the FSNSString category (or the method
         "blockFromString:onError:" in FSSystem).
         
         For example:
         
         [source asBlockOnError:[@"[:msg :start :end | {msg, start, end}]"
         asBlock]];
         
         This will either return an FSBlock instance (if there is no syntax
         error) or an array with error information (if there is a syntax
         error).
         
         A second alternative is to use FSInterpreter's execute method after
         patching the source code you want to validate in a way that will
         prevent it to execute, as shown here:
         
         FSInterpreterResult *result = [myInterpreter execute:[NSString
         stringWithFormat:@"[%@]", source]];
         
         If you then use the error range provided by FSInterpreterResult,
         remember to decrement the location by one.
         */
        
		FSBlock *block = [source asBlock];
		(void)block;
	}
	@catch (NSException* e) {
		NSDictionary *userInfo = [e userInfo];
		
		// the exception reason has the error string but no line number info
		// (this could perhaps be calculated form the character indicies in 
		// BlockStackElem
		NSArray *blockStack = [userInfo objectForKey:@"FScriptBlockStack"];
		
		// block stack elem is not part of the public API
		// hence we import it separately.
		// FSInterpreterResult does supply all error info
		// but it is returned only as result of execution
		BlockStackElem *blockStackElem = [blockStack objectAtIndex:0];

		// report error
		self.error = [NSString stringWithFormat:@"%@", [blockStackElem errorStr]];

		// get error range
		NSUInteger firstCharIndex = [blockStackElem firstCharIndex];
		NSUInteger lastCharIndex = [blockStackElem lastCharIndex];
		
		// volatile helps avoid compile warning
		volatile NSRange range =  NSMakeRange(firstCharIndex, lastCharIndex - firstCharIndex);
		self.errorInfo = [NSMutableDictionary dictionaryWithCapacity:2];
		[self.errorInfo setObject:NSStringFromRange(range) forKey:MGSRangeErrorKey];
		[self.errorInfo setObject:self.error forKey:NSLocalizedFailureReasonErrorKey];	// required
	}
				
	return [self processBuildResult:resultString];
}
@end
