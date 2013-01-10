//
//  MGSLanguage.h
//  KosmicTask
//
//  Created by Jonathan on 10/11/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *MGSInputStyle;

enum _eMGSLanguageType {
	kMGSInterpretedLanguage = 0,
	kMGSCompiledLanguage,
};
typedef NSInteger eMGSLanguageType;

enum _eMGSProcessType {
	kMGSInProcess = 0,
	kMGSOutOfProcess,
};
typedef NSInteger eMGSProcessType;

enum _eMGSExecutableFormat {
	kMGSSource = 0,
	kMGSCompiled,
};
typedef NSInteger eMGSExecutableFormat;

 enum _eMGSOnRunTask {
	kMGSOnRunCallNone = 0,
	kMGSOnRunCallScript,
	kMGSOnRunCallScriptFunction,
	kMGSOnRunCallClassFunction
 };
typedef NSInteger eMGSOnRunTask;

// build result flags
enum _MGSBuildResultFlags
{
	kMGSCompiledScript      = 1 <<  1,  // If set, build result includes compiled script
	kMGSScriptSourceRTF     = 1 <<  2,  // If set, build result includes script source RTF
	kMGSScriptSource		= 1 <<  3,  // If set, build result includes script source
};
typedef NSInteger MGSBuildResultFlags;

@interface MGSLanguage : NSObject <NSCopying> {

	@private
	eMGSLanguageType initLanguageType;
	eMGSProcessType initExecutorProcessType;
	eMGSProcessType initBuildProcessType;
	
	// script type
	NSString *initScriptType;
	NSString *initScriptTypeFamily;		// defaults to initScriptType
	NSString *initDisplayName;			// defaults to initScriptType
	NSString *initSyntaxDefinition;		// defaults to initScriptType
	
	BOOL initCanBuild;
	BOOL initSeparateSyntaxChecker;
	eMGSExecutableFormat initExecutableFormat;
	BOOL initExecutorAcceptsOptions;
	BOOL initBuildAcceptsOptions;
	BOOL initIsOsaLanguage;

	NSString *initTaskProcessName;
	BOOL initValidForOSVersion;
	BOOL initCanIgnoreBuildWarnings;
	BOOL initLanguageShipsWithOS;

	// interface properties
	BOOL initSupportsScriptFunctions;
	BOOL initSupportsDirectParameters;
	BOOL initSupportsClasses;
	BOOL initSupportsClassFunctions;
	NSString *initDefaultClass;
	NSString *initDefaultScriptFunction;
	NSString *initDefaultClassFunction;
	NSString *initRequiredClass;
	NSString *initRequiredScriptFunction;
	NSString *initRequiredClassFunction;
	BOOL initRequiredClassFunctionIsStatic;
	
	// run properties
	eMGSOnRunTask initOnRunTask;
	NSString *initRunFunction;
	NSString *initRunClass;
	
	// Cocoa properties
	BOOL initIsCocoaBridge;
	BOOL initNativeObjectsAsResults;
	BOOL initNativeObjectsAsYamlSupport;
	
	// options
	NSString *initExternalExecutorPath;
	NSString *initExternalBuildPath;
	NSString *initExecutorOptions;
	NSString *initBuildOptions;
	
	NSArray *initSourceFileExtensions;
	
	NSString *initTaskRunnerClassName;
	MGSBuildResultFlags initBuildResultFlags;	
}

@property eMGSLanguageType initLanguageType;
@property eMGSProcessType initExecutorProcessType;
@property eMGSProcessType initBuildProcessType;

@property BOOL initCanBuild;
@property BOOL initSeparateSyntaxChecker;
@property eMGSExecutableFormat initExecutableFormat;
@property BOOL initExecutorAcceptsOptions;
@property BOOL initBuildAcceptsOptions;

@property (copy) NSString *initExternalExecutorPath;
@property (copy) NSString *initExternalBuildPath;

@property (copy) NSString *initExecutorOptions;
@property (copy) NSString *initBuildOptions;

@property BOOL initIsOsaLanguage;

// script type
@property (copy) NSString *initScriptType;
@property (copy) NSString *initScriptTypeFamily;
@property (copy) NSString *initDisplayName;
@property (copy) NSString *initSyntaxDefinition;

@property (copy) NSString *initTaskProcessName;
@property BOOL initValidForOSVersion;
@property BOOL initCanIgnoreBuildWarnings;
@property BOOL initLanguageShipsWithOS;

@property BOOL initIsCocoaBridge;
@property BOOL initNativeObjectsAsResults;
@property BOOL initNativeObjectsAsYamlSupport;

// direct parameters are passed directly to the task, not to a named function
@property BOOL initSupportsDirectParameters;
@property BOOL initSupportsScriptFunctions;
@property BOOL initSupportsClasses;
@property BOOL initSupportsClassFunctions;
@property (copy) NSString *initDefaultClass;
@property (copy) NSString *initDefaultScriptFunction;
@property (copy) NSString *initDefaultClassFunction;
@property (copy) NSString *initRequiredClass;
@property (copy) NSString *initRequiredScriptFunction;
@property (copy) NSString *initRequiredClassFunction;
@property BOOL initRequiredClassFunctionIsStatic;

@property eMGSOnRunTask initOnRunTask;
@property (copy) NSString *initRunFunction;
@property (copy) NSString *initRunClass;

@property (copy) NSArray *initSourceFileExtensions;


@property (copy) NSString *initTaskRunnerClassName;

@property MGSBuildResultFlags initBuildResultFlags;

+ (NSString *)missingProperty;
- (NSString *)missingProperty;
+ (NSMutableArray *)tokeniseString:(NSString *)optionString;

- (BOOL)isMissingProperty:(id)value;
- (BOOL)validateOSVersion:(unsigned)major minor:(unsigned)minor bugFix:(unsigned)bugFix;
- (NSString *)taskInputsCodeTemplate:(NSDictionary *)taskInfo;
- (NSString *)taskInputCodeTemplate:(NSDictionary *)taskInfo;
- (NSString *)taskBodyCodeTemplate:(NSDictionary *)taskInfo;
- (NSString *)taskInputSeparatorCodeTemplate:(NSDictionary *)taskInfo;
- (NSDictionary *)codeProperties;
- (NSString *)codeTemplateBundleResourceWithName:(NSString *)resourceName extension:(NSString *)extension;
- (NSString *)taskInputDuplicateCodeTemplate:(NSDictionary *)taskInfo;
@end
