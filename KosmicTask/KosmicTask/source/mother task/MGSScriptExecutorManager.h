//
//  MGSScriptExecutorManager.h
//  KosmicTask
//
//  Created by Jonathan on 15/05/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MGSScriptRunner.h"

@protocol MGSScriptExecutor <NSObject>

- (id) loadModuleAtPath:(NSString *)scriptPath className:(NSString *)className functionName:(NSString *)functionName arguments:(NSArray *)arguments;
+ (id) loadModuleAtPath:(NSString *)scriptPath className:(NSString *)className functionName:(NSString *)functionName arguments:(NSArray *)arguments;
- (NSString *)echo:(NSString *)aString;
- (NSString *)scriptError;
@end

@interface MGSScriptExecutorManager : NSObject {
	NSString *error;

}

+ (id) sharedManager;
- (BOOL) setupEnvironment:(MGSScriptRunner *)scriptRunner;
- (id) loadScriptAtPath:(NSString*)scriptPath runClass:(NSString*)className runFunction:(NSString*)functionName withArguments:(NSArray*)arguments;
- (NSString *)executorClassName;
- (Class)executorClass;
- (id)executor;

@property (copy) NSString *error;

@end
