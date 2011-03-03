//
//  MGSScriptExecutorManager.m
//  KosmicTask
//
//  Created by Jonathan on 15/05/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSScriptExecutorManager.h"

//#define TEST_EXECUTOR

@implementation MGSScriptExecutorManager

@synthesize error;

/*
 
 + sharedManager
 
 */
+ (id) sharedManager
{
	static id sharedManager = nil;
	if (!sharedManager) {
		sharedManager = [[self alloc] init];
	}
	
	return sharedManager;
}


/*
 
 - setupEnvironment:
 
 */
- (BOOL) setupEnvironment:(MGSScriptRunner *)scriptRunner
{
#pragma unused(scriptRunner)
	
	// subclasses must ocerride to return YES
	return NO;
}

/*
 
 - executorClassName
 
 */
- (NSString *)executorClassName
{
	return @"";
}

/*
 
 - executorClass
 
 */
- (Class)executorClass
{
	return NSClassFromString([self executorClassName]);
}

/*
 
 - executor
 
 */
- (id)executor
{
	Class klass =[self executorClass];
	if (!klass) return nil;
	
	return [klass new];
}

/*
 
 - loadScriptAtPath:runFunction:withArguments:
 
 http://www.redstoyland.com/projects/code/pythonandobjectivec.html
 http://www.friday.com/bbum/2007/11/25/can-ruby-python-an-objective-c-co-exist-in-a-single-application
 
 */
- (id) loadScriptAtPath:(NSString*)scriptPath runClass:(NSString*)className runFunction:(NSString*)functionName withArguments:(NSArray*)arguments 
{
	id object = nil;

	@try {
		Class klass = [self executorClass];
		if (!klass) {
			return [NSString stringWithFormat:@"Could not find executor class: %@", [self executorClassName]];
		}

		id <MGSScriptExecutor> executor = [self executor];
		if (!executor) {
			return [NSString stringWithFormat:@"Could not create executor class instance: %@", [self executorClassName]];
		}
		
		
	#ifdef TEST_EXECUTOR
			
		if (![klass respondsToSelector:@selector(echo:)]) {
			return @"Executor class does not respond to selector";
		}
		return [klass echo:@"executor call succeeded"];
		
	#else
		
		SEL sel = @selector(loadModuleAtPath:className:functionName:arguments:);
		SEL selErr = @selector(scriptError);
		id testError = nil;
		
		// try instance method
		if ([executor respondsToSelector:sel]) {
#warning DEBUG
			NSLog(@"Classname = %@ funcrioName = %@", className, functionName);
			object = [executor loadModuleAtPath:scriptPath
								   className:className
								   functionName:functionName
									  arguments:arguments];
			
			// get errors
			if ([executor respondsToSelector:selErr]) {
				testError = [executor scriptError];
				if (testError) {
					self.error = testError;
				}
			}
			
		// try class method
		} else if ([klass respondsToSelector:sel]) {
#warning DEBUG
			NSLog(@"Classname = %@ funcrioName = %@", className, functionName);			
			object = [klass loadModuleAtPath:scriptPath
									className:className
									  functionName:functionName
										arguments:arguments];			
			// get errors
			if ([klass respondsToSelector:selErr]) {
				testError = [klass scriptError];
				if (testError) {
					self.error = testError;
				}
			}
						
		} else {
			object = @"executor does not respond to selector ";
			self.error = object;
		}
	} @catch (NSException *e) {
		
		self.error = @"Could not execute. Check syntax and variables.";
		
		// raise it again
		[e raise];
	}
	
	return object;
	
#endif
	
}


@end
