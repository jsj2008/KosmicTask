//
//  MGSLanguage.h
//  KosmicTask
//
//  Created by Jonathan on 10/11/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *MGSInputStyle;

enum _eMGSInputArgumentName {
    kMGSInputArgumentName = 1 << 0,
    kMGSInputArgumentNameAndType = 1 << 1,
    kMGSInputArgumentType = 1 << 2,
    kMGSInputArgumentTypeAndName = 1 << 3,
};
typedef NSUInteger MGSInputArgumentName;

enum _eMGSInputArgumentCaseFlags {
    kMGSInputArgumentCamelCase= 1 << 0,
    kMGSInputArgumentLowerCase = 1 << 1,
    kMGSInputArgumentInputCase = 1 << 2,
    kMGSInputArgumentPascalCase = 1 << 3,
    kMGSInputArgumentUpperCase = 1 << 4,
};
typedef NSUInteger MGSInputArgumentCase;

enum _eMGSInputArgumentStyleFlags {
    kMGSInputArgumentUnderscoreSeparated = 1 << 0,
    kMGSInputArgumentWhitespaceRemoved = 1 << 1,
};
typedef NSUInteger MGSInputArgumentStyle;

enum _eMGSCodeDescriptorCodeStyle {
    kMGSCodeDescriptorTaskInputs = 0,
    kMGSCodeDescriptorTaskBody = 1,
    kMGSCodeDescriptorTaskEntry = 2,
};
typedef NSUInteger MGSCodeDescriptorCodeStyle;

enum _eMGSLanguageType {
	kMGSInterpretedLanguage = 0,
	kMGSCompiledLanguage = 1,
};
typedef NSInteger eMGSLanguageType;

enum _eMGSProcessType {
	kMGSInProcess = 0,
	kMGSOutOfProcess = 1,
};
typedef NSInteger eMGSProcessType;

enum _eMGSExecutableFormat {
	kMGSSource = 0,
	kMGSCompiled = 1,
};
typedef NSInteger eMGSExecutableFormat;

enum _eMGSOnRunTask {
	kMGSOnRunCallNone = 0,
	kMGSOnRunCallScript = 1,
	kMGSOnRunCallScriptFunction = 2,
	kMGSOnRunCallClassFunction = 3
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
	NSString *defScriptType;
	NSString *defScriptTypeFamily;		// defaults to defScriptType
	NSString *defDisplayName;			// defaults to defScriptType
	NSString *defSyntaxDefinition;		// defaults to defScriptType
	
	BOOL defCanBuild;
	BOOL initSeparateSyntaxChecker;
	eMGSExecutableFormat initExecutableFormat;
	BOOL initExecutorAcceptsOptions;
	BOOL initBuildAcceptsOptions;
	BOOL initIsOsaLanguage;

	NSString *defTaskProcessName;
	BOOL initValidForOSVersion;
	BOOL initCanIgnoreBuildWarnings;
	BOOL initLanguageShipsWithOS;

	// interface properties
	BOOL initSupportsScriptFunctions;
	BOOL initSupportsDirectParameters;
	BOOL initSupportsClasses;
	BOOL initSupportsClassFunctions;
	NSString *defDefaultClass;
	NSString *defDefaultScriptFunction;
	NSString *defDefaultClassFunction;
	NSString *defRequiredClass;
	NSString *defRequiredScriptFunction;
	NSString *defRequiredClassFunction;
	BOOL defRequiredClassFunctionIsStatic;
	
	// run properties
	eMGSOnRunTask initOnRunTask;
	NSString *defRunFunction;
	NSString *defRunClass;
	
	// Cocoa properties
	BOOL initIsCocoaBridge;
	BOOL initNativeObjectsAsResults;
	BOOL initNativeObjectsAsYamlSupport;
	
	// options
	NSString *defExternalExecutorPath;
	NSString *defExternalBuildPath;
	NSString *defExecutorOptions;
	NSString *defBuildOptions;
	
	NSArray *defSourceFileExtensions;
	
	NSString *defTaskRunnerClassName;
	MGSBuildResultFlags initBuildResultFlags;
    
    MGSInputArgumentName initInputArgumentName;
    MGSInputArgumentCase initInputArgumentCase;
    MGSInputArgumentStyle initInputArgumentStyle;
    MGSInputArgumentStyle initInputArgumentStyleAllowedFlags;
}

@property eMGSLanguageType initLanguageType;
@property eMGSProcessType initExecutorProcessType;
@property eMGSProcessType initBuildProcessType;

@property MGSInputArgumentName initInputArgumentName;
@property MGSInputArgumentCase initInputArgumentCase;
@property MGSInputArgumentStyle initInputArgumentStyle;
@property MGSInputArgumentStyle initInputArgumentStyleAllowedFlags;

@property BOOL defCanBuild;
@property BOOL initSeparateSyntaxChecker;
@property eMGSExecutableFormat initExecutableFormat;
@property BOOL initExecutorAcceptsOptions;
@property BOOL initBuildAcceptsOptions;

@property (copy) NSString *defExternalExecutorPath;
@property (copy) NSString *defExternalBuildPath;

@property (copy) NSString *defExecutorOptions;
@property (copy) NSString *defBuildOptions;

@property BOOL initIsOsaLanguage;

// script type
@property (copy) NSString *defScriptType;
@property (copy) NSString *defScriptTypeFamily;
@property (copy) NSString *defDisplayName;
@property (copy) NSString *defSyntaxDefinition;

@property (copy) NSString *defTaskProcessName;
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
@property (copy) NSString *defDefaultClass;
@property (copy) NSString *defDefaultScriptFunction;
@property (copy) NSString *defDefaultClassFunction;
@property (copy) NSString *defRequiredClass;
@property (copy) NSString *defRequiredScriptFunction;
@property (copy) NSString *defRequiredClassFunction;
@property BOOL defRequiredClassFunctionIsStatic;

@property eMGSOnRunTask initOnRunTask;
@property (copy) NSString *defRunFunction;
@property (copy) NSString *defRunClass;

@property (copy) NSArray *defSourceFileExtensions;


@property (copy) NSString *defTaskRunnerClassName;

@property MGSBuildResultFlags initBuildResultFlags;

+ (NSString *)missingProperty;
- (NSString *)missingProperty;
+ (NSMutableArray *)tokeniseString:(NSString *)optionString;

- (BOOL)isMissingProperty:(id)value;
- (BOOL)validateOSVersion:(unsigned)major minor:(unsigned)minor bugFix:(unsigned)bugFix;
- (NSString *)taskInputsCodeTemplateName:(NSDictionary *)taskInfo;
- (NSString *)taskInputCodeTemplateName:(NSDictionary *)taskInfo;
- (NSString *)taskBodyCodeTemplateName:(NSDictionary *)taskInfo;
- (NSDictionary *)codeProperties;
- (NSString *)codeTemplateResourcePath;
- (NSString *)taskFunctionCodeTemplateName:(NSDictionary *)taskInfo;
- (NSString *)taskInputVariablesCodeTemplateName:(NSDictionary *)taskInfo;
- (NSString *)taskInputNameCodeTemplateName:(NSDictionary *)taskInfo;
- (NSString *)taskInputResultCodeTemplateName:(NSDictionary *)taskInfo;
- (NSString *)taskHeaderCodeTemplateName:(NSDictionary *)taskInfo;
- (NSString *)taskInputConditionalCodeTemplateName:(NSDictionary *)taskInfo;
- (NSString *)taskClassFunctionCodeTemplateName:(NSDictionary *)taskInfo;
- (NSString *)taskFunctionPatternTemplateName:(NSDictionary *)taskInfo;
- (NSString *)taskInputsPatternTemplateName:(NSDictionary *)taskInfo;
- (NSString *)taskClassFunctionPatternTemplateName:(NSDictionary *)taskInfo;
- (NSString *)taskInputVariablesPatternTemplateName:(NSDictionary *)taskInfo;

@end
