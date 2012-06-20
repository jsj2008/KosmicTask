//
//  MGSJavaScriptCocoaRunner.m
//  KosmicTask
//
//  Created by Jonathan on 10/12/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSJavaScriptCocoaRunner.h"
#import "MGSJSCocoaLanguage.h"
#import "MGSJSCocoaScriptManager.h"
#import <JSCocoa/JSCocoa.h>

@implementation MGSJavaScriptCocoaRunner

/*
 
 - initWithDictionary
 
 designated initialiser
 
 */
- (id)initWithDictionary:(NSDictionary *)dictionary
{
	if ((self = [super initWithDictionary:dictionary])) {
		self.scriptExecutableExtension = @"js";
		self.scriptSourceExtension = @"js";
		
	}
	return self;
}

/*
 
 - languageClass
 
 */
- (Class)languageClass
{
	return [MGSJSCocoaLanguage class];
}

/*
 
 - execute
 
 */
- (BOOL)execute
{
	// execute
	return [self executeWithManager:[MGSJSCocoaScriptManager sharedManager]];
}

/*
 
 - build
 
 */
- (BOOL)build
{
	// establish connection
	JSCocoa *jsCocoa = [JSCocoa new];
	
	// get script source
	NSString *source = [self scriptSourceWithError:YES];
	if (!source) return NO;
	
	// evaluate the syntax
	NSString *error = nil;
	if (![jsCocoa isSyntaxValid:source error:&error]) {
		self.error = [error copy];
		return NO;
	}
	
	return YES;
	
}
@end
