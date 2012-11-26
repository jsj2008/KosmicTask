//
//  MGSScriptRunner.h
//  Mother
//
//  Created by Jonathan on 01/09/2009.
//  Copyright 2009 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSLanguage.h"
#import "GTMSystemVersion.h"

@protocol MGSScriptRunner
@required
- (void)stopApp:(id)sender;
@end

@class MGSError;
@class MGSScriptExecutorManager;
@class MGSLanguage;

@interface MGSScriptRunner : NSObject <NSApplicationDelegate, MGSScriptRunner> {
	
@private	
	int argc;
	const char **argv;
	NSDictionary *taskDict;
	NSString *error;
	NSInteger errorCode;
	NSMutableDictionary *errorInfo;
	NSMutableDictionary *replyDict;
	int stdoutSaved;
	id resultObject;
	id scriptObject;
	NSString *scriptExecutableExtension;
	NSString *scriptSourceExtension;
	MGSScriptExecutorManager *scriptExecutorManager;
	NSString *scriptFilePath;
	NSString *workingDirectory;
	NSString *scriptFileNameTemplate;
	NSString *scriptAction;
	BOOL isExecuting;
	BOOL isCompiling;
	BOOL useExecutableData;
	NSString *onRun;
	NSString *runFunctionName;
	NSString *runClassName;
	MGSLanguage *language;
	
	/*
	 
	 note that I was bitten by fragile ivars here.
	 I added an ivar here but the derived classes did not get rebuilt
	 so they overwrote the last ivar in the list.
	 
	 need to rebuild dependent classes in this case.
	 
	 see:
	 
	 http://sealiesoftware.com/blog/archive/2009/01/27/objc_explain_Non-fragile_ivars.html
	 
	 the problem was caused because I did not import MGSScriptRunner.h directly into
	 my subclass but indirectly via taskmain.h
	 
	 for a superclass to get recompiled the subclass header must be included directly in the
	 superclass header.
	 
	 */
}


+ (BOOL)transformToForegroundApplication;
+ (BOOL)isForegroundApplication;
- (BOOL)execute;
- (BOOL)executeApp;
- (void)stopApp:(id)sender;
- (BOOL)build;
- (BOOL)runScript;
- (id)initWithDictionary:(NSDictionary *)dictionary;
- (void)addError:(NSString *)anError;
- (NSString *)resourcesPath;
- (NSString *)pathToResource:(NSString *)resourceName;
- (NSString *)pathToExecutable:(NSString *)name;
- (void)updateEnvironment:(NSMutableDictionary *)env pathkey:(NSString *)key paths:(NSArray *)paths;
- (void)updateEnvironment:(NSMutableDictionary *)env pathkey:(NSString *)key paths:(NSArray *)paths separator:(NSString *)separator;
- (NSMutableDictionary *) launchEnvironment;
- (NSMutableDictionary *) buildEnvironment;
- (NSString *)launchPath;
- (NSString *)buildPath;
- (NSString *)defaultLaunchPath;
- (NSString *)defaultBuildPath;
- (NSDictionary *)environment;;
- (NSArray *)ScriptParametersWithError:(BOOL)error;
- (NSData *)scriptExecutableDataWithError:(BOOL)error;
- (NSString *)writeScriptDataToWorkingFile:(NSData *)data withExtension:(NSString *)ext;
- (void)redirectStdOutToStdErr;
- (void)restoreStdOut;
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
- (BOOL)executeWithManager:(MGSScriptExecutorManager *)manager;
- (NSString *)workingFilePathWithExtension:(NSString *)ext;
- (void)stopTask:(id)result;
- (BOOL) processBuildResult:(NSString *)resultString;
- (BOOL) processExecuteResult:(id)resultString;
- (NSString *)scriptSourceWithError:(BOOL)genError;
- (NSString *)scriptExecutableSourceWithError:(BOOL)genError;
- (NSString *)scriptFileExtension;
- (NSString *)executablePath;
- (NSString *)beginScriptExecutableSource;
- (BOOL)createArchive:(NSString *)archivePath options:(NSDictionary *)options;
- (BOOL)extractArchive:(NSString *)archivePath options:(NSDictionary *)options;
- (NSString *)scriptExecutableFormat;
- (BOOL)executableIsArchive;
- (BOOL)prepareExecutable;
- (BOOL)validate;
- (Class)languageClass;
- (NSMutableArray *)buildOptions;
- (NSMutableArray *)executeOptions;
- (NSMutableArray *)filesAtPath:(NSString *)path withExtension:(NSString *)fileExtension;

//@property (copy) NSData *stderrData;
@property (readonly) NSDictionary *taskDict;
@property (copy) NSString *error;
@property NSInteger errorCode;
@property (readonly) NSMutableDictionary *replyDict;
@property (retain) NSMutableDictionary *errorInfo;
@property int argc;
@property const char **argv;
@property (assign) id resultObject;
@property (assign) id scriptObject;
@property (copy) NSString *scriptExecutableExtension;
@property (copy) NSString *scriptSourceExtension;
@property (readonly, copy) NSString *scriptFilePath;
@property (readonly) NSString *workingDirectory;
@property (copy) NSString *scriptFileNameTemplate;
@property (readonly, copy) NSString *scriptAction;
@property (readonly) BOOL isExecuting;
@property (readonly) BOOL isCompiling;
@property BOOL useExecutableData;
@property (readonly, copy) NSString *onRun;
@property (readonly, copy) NSString *runFunctionName;
@property (readonly, copy) NSString *runClassName;
@property (assign) MGSLanguage *language;
@end

@interface NSMutableData (MGSScriptRunner)
- (void) mgs_fileHandleDataAvailable:(NSNotification*)notification;
@end
