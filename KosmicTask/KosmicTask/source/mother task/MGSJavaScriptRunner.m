//
//  MGSJavaScriptRunner.m
//  KosmicTask
//
//  Created by Jonathan on 01/08/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSJavaScriptRunner.h"
#import "TaskRunner.h"
#import "MGSJavaScriptLanguage.h"

#import <JavaScriptCore/JavaScriptCore.h>
#import <TargetConditionals.h>

NSString* MGSStringCreateWithJSString(JSStringRef jsString);
JSStringRef MGSJSStringRefCreateWithNSString(NSString *aString);

@implementation MGSJavaScriptRunner

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
	return [MGSJavaScriptLanguage class];
}

/*
 
 - execute
 
 */
- (BOOL) execute
{
	// apple framework docs
	// http://developer.apple.com/mac/library/documentation/Carbon/Reference/WebKit_JavaScriptCore_Ref/javascriptcore_fw-functions.html
	
	// parsing see
	// http://old.nabble.com/about-parse-javascript-function-td22215406.html
	
	// functions are properties. see
	// http://old.nabble.com/JavaScriptCore:-Accessing-things-created-in-C-from-script-td20952937.html
	
	
	// JSCocoa has all this wrapped!
	
	NSString *taskFunction = self.runFunctionName;
	NSString *resultString = @"";
	JSStringRef scriptJS = NULL;
	
	// get script parameter array
	NSArray *paramArray = [self ScriptParametersWithError:YES];
	if (!paramArray) return NO;

	// get the executable source
	NSString *source = [self scriptExecutableSourceWithError:YES];
	if (!source) {
		return NO;
	}
	
	// setup JS
	JSGlobalContextRef ctx = JSGlobalContextCreate(NULL);
	JSObjectRef globalJS = JSContextGetGlobalObject(ctx);
	JSValueRef exception = NULL;
	JSObjectRef fn = NULL;

	// load the KosmicTaskController source
	NSString *controllerPath = [self pathToResource:@"JavaScript/KosmicTaskController.js"];
	NSString *controllerSource = [NSString stringWithContentsOfFile:controllerPath encoding:NSUTF8StringEncoding error:NULL];
	if (!controllerSource) {
		self.error = [NSString stringWithFormat:@"Cannot load KosmicTaskController : %@", controllerPath];
		return NO;
	}
	
	// evaluate the controller within the global context
	JSStringRef controllerJS = MGSJSStringRefCreateWithNSString(controllerSource);
	JSStringRef controllerURLJS = MGSJSStringRefCreateWithNSString(@"KosmicTaskController");
	JSEvaluateScript(ctx, controllerJS, NULL, controllerURLJS, 1, &exception);
	if (exception) goto handleException;
	

	// load the task script
	scriptJS = MGSJSStringRefCreateWithNSString(source);
	JSStringRef sourceURLJS = MGSJSStringRefCreateWithNSString(@"KosmicTask");
	
	// evaluate our script for the global object.
	// if we define a task function then that task function will become available
	// as a property on the global object.
	// we can then execute an anonymous function with arguments to call our
	// task function.
	// or we can get the property for our function and execute it
	JSValueRef resultJS = JSEvaluateScript(ctx, scriptJS, NULL, sourceURLJS, 1, &exception);
	if (exception) goto handleException;

	// property approach.
	// functions are stored as properties of, in this case, the global object.
	
	// get property
	JSStringRef propertyName = MGSJSStringRefCreateWithNSString(taskFunction);
	fn = (JSObjectRef)JSObjectGetProperty(ctx, globalJS, propertyName, &exception);
	if (exception) goto handleException;
	
	// validate
	if (!JSObjectIsFunction(ctx, fn)) {
		self.error = [NSString stringWithFormat:@"Function not found: %@", taskFunction];
		goto handleException;
	}
	
	// form argument list
	size_t argumentCount = [paramArray count];
	JSValueRef *arguments = NULL;
	if (argumentCount > 0) {
		arguments = NSAllocateCollectable(sizeof(JSValueRef) * argumentCount, 0);
		for (NSUInteger i = 0; i < argumentCount; i++ ) {
			
			JSValueRef arg = NULL;
			
			// get parameter and form appropriate JS type
			id param = [paramArray objectAtIndex:i];
			
			// number
			if ([param isKindOfClass:[NSNumber class]]) {
				arg = JSValueMakeNumber(ctx, [param doubleValue]);
			} else {
				JSStringRef stringRep = MGSJSStringRefCreateWithNSString([param description]);
				arg = JSValueMakeString(ctx, stringRep);
			}
			
			arguments[i] = arg;
		}
	}
	
	if (fn) {
		
		// call the function
		resultJS = JSObjectCallAsFunction(ctx, fn, NULL, argumentCount, arguments, &exception);
		if (exception) goto handleException;
		
		// get result as string
		JSStringRef resultStringJS = JSValueToStringCopy(ctx, resultJS, &exception);
		if (exception) goto handleException;
		resultString = MGSStringCreateWithJSString(resultStringJS);
		
	} else {
		self.error = [NSString stringWithFormat:@"Function missing: %@", taskFunction];
	}

handleException:
	
	// handle exception
	if (exception) {
		JSStringRef exceptionString = JSValueToStringCopy(ctx, exception, NULL);
		self.error = MGSStringCreateWithJSString(exceptionString);
		JSStringRelease(exceptionString);	
	}
	
	// clean up
	if (scriptJS) {
		JSStringRelease(scriptJS);	
	}
	JSGlobalContextRelease(ctx);	
	
	return [self processExecuteResult:resultString];
}

/*
 
 - buildPath
 
 javascriptlint available for intel only
 http://www.javascriptlint.com/
 much better that the JaveScriptCore syntax check
 
 
 */
- (NSString *)buildPath
{
	// path to javascriptlint binary
	// javascriptlint available for intel only
	// http://www.javascriptlint.com/
	// much better that the JaveScriptCore syntax check
	NSString *path = [self executablePath];	// path to executable
	path = [path stringByDeletingLastPathComponent]; 
	path = [path stringByAppendingPathComponent:@"jsl"];
	
	return path;
}

/*
 
 - buildOptions
 
 */
- (NSMutableArray *)buildOptions
{
	NSMutableArray *options = [super buildOptions];
	/*
	 ./jsl for options
	 
	 note that we are not making use of the config file jsl.default.conf
	 
	 */
	//NSArray *options = [NSArray arrayWithObjects:@"-nofilelisting",  @"-nologo", @"-nosummary", @"-process", nil];
	
	return options; 
}

/*
 
 compile the task
 
 */
- (BOOL)build 
{
#if ( TARGET_CPU_X86 | TARGET_CPU_X86_64 )

	// if intel then call the super compile to send to external process
	return [super build];
	
#else
	
	NSString *resultString = @"";
	
	// get the source
	NSString *source = [self scriptSourceWithError:YES];
	if (source == nil) {
		return NO;
	}
	
	
	// use the less capable JavaScriptCore checker
	
	// setup
	JSGlobalContextRef ctx = JSGlobalContextCreate(NULL);
	JSStringRef scriptJS = MGSJSStringRefCreateWithNSString(source);
	JSStringRef sourceURL = MGSJSStringRefCreateWithNSString(@"KosmicTask");
	JSValueRef exception = NULL;
	
	// compile
	BOOL success = JSCheckScriptSyntax(ctx, scriptJS, sourceURL, 1, &exception);
	
	// report error
	if (!success) {
		JSStringRef exceptionString = JSValueToStringCopy(ctx, exception, NULL);
		self.error = MGSStringCreateWithJSString(exceptionString);
		JSStringRelease(exceptionString);	
	}
	
	// clean up
	JSStringRelease(scriptJS);	
	JSGlobalContextRelease(ctx);	
	
	return [self parseCompileResult:resultString];
#endif
}

@end

/*
 
 MGSStringCreateWithJSString()
 
 */
NSString* MGSStringCreateWithJSString(JSStringRef jsString)
{
    size_t length = JSStringGetLength(jsString);
	
    char *buffer = malloc(length+1);
    JSStringGetUTF8CString(jsString, buffer, length+1);
    
    NSString *string = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
    
    free(buffer);
    
    return string;
}

/*
 
 MGSJSStringRefCreateWithNSString()
 
 */
JSStringRef MGSJSStringRefCreateWithNSString(NSString *aString) 
{
	const char *cString = [aString cStringUsingEncoding:NSUTF8StringEncoding];
	return JSStringCreateWithUTF8CString(cString);
}

