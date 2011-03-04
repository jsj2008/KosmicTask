//
//  MGSLanguagePropertyManager.m
//  KosmicTask
//
//  Created by Jonathan on 29/08/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import "MGSLanguagePropertyManager.h"
#import "MGSLanguage.h"
#import "MLog.h"


NSString * const MGSNoteLanguagePropertyDidChangeValue = @"languagePropertyDidChangeValue";
NSString * const MGSNoteKeyLanguageProperty = @"languageProperty";

// class extension
@interface MGSLanguagePropertyManager ()
- (NSString *)stringForProcessType:(eMGSProcessType)processType;
- (NSString *)stringForExecutableFormat:(eMGSExecutableFormat)executableFormat;
- (void)updateLanguagePropertiesFromFile:(NSString *)filePath;
- (NSString *)stringForBool:(BOOL)value;
- (NSString *)localizedString:(NSString *)key;
- (NSString *)stringForLanguageType:(eMGSLanguageType)format;
- (NSString *)stringForOnRunTask:(eMGSOnRunTask)value;
- (NSDictionary *)languageProperties;
- (void)initialisePropertiesWithManager:(MGSLanguagePropertyManager *)manager;

@property (copy) MGSLanguage *language;
@end

@implementation MGSLanguagePropertyManager

@synthesize language;

/*
 
 - initWithLanguage:
 
 designated initialiser
 
 */
- (id)initWithLanguage:(MGSLanguage *)aLanguage
{
	NSAssert(aLanguage, @"language is nil");
	
	self = [super init];
	if (self) {
		language = aLanguage;
	}
	return self;
}

/*
 
 init:
 
 */
- (id)init
{
	return [self initWithLanguage:nil];
}

#pragma mark -
#pragma mark NSCopying
/*
 
 - copyWithZone:
 
 */
- (id)copyWithZone:(NSZone *)zone
{
	#pragma unused(zone)

	MGSLanguage *languageCopy = [self.language copy];
	MGSLanguagePropertyManager *copy = [[[self class] alloc] initWithLanguage:languageCopy];
	
	// don't copy the delegate

	
	// initialise the properties collection
	[copy initialisePropertiesWithManager:self];
	
	// disable editability of defaults
	[[copy propertyForKey:MGS_LP_DefaultClass] setEditable:NO];
	[[copy propertyForKey:MGS_LP_DefaultScriptFunction] setEditable:NO];
	[[copy propertyForKey:MGS_LP_DefaultClassFunction] setEditable:NO];
	
	return copy;
}



#pragma mark -
#pragma mark Language properties

/*
 
 - allPropertyKeys
 
 */
- (NSArray *)allPropertyKeys
{
	return [[self languageProperties] allKeys];
}

/*
 
 - allPropertyKeys
 
 */
- (NSArray *)allProperties
{
	return [[self languageProperties] allValues];
}

/*
 
 - propertyForKey
 
 */
- (MGSLanguageProperty *)propertyForKey:(id)key
{
	return [[self languageProperties] objectForKey:key];
}

/*
 
 - languageProperties
 
 */
- (NSDictionary *)languageProperties
{
	NSAssert(languageProperties, @"language properties have not been configured");
	
	return languageProperties;
}

/*
 
 - initialisePropertiesWithManager:(MGSLanguagePropertyManager)
 
 */
- (void)initialisePropertiesWithManager:(MGSLanguagePropertyManager *)manager
{
	NSMutableDictionary *langProperties = [NSMutableDictionary dictionaryWithCapacity:20];

	for (id key in [manager allPropertyKeys]) {
		MGSLanguageProperty *langProp = [[manager propertyForKey:key] copy];
		langProp.delegate = self;
		[langProperties setObject:langProp forKey:key];
	}
	
	languageProperties = langProperties;
}

/*
 
 - initialiseProperties
 
 */
- (void)initialiseProperties
{
	if (languageProperties) return;
	
	NSMutableDictionary *langProperties = [NSMutableDictionary dictionaryWithCapacity:20];
	MGSLanguageProperty *langProp = nil;
	NSMutableDictionary *propOptions = nil;
	
	/*====================================
	 
	 build properties
	 
	 =====================================*/
	// Can build
	langProp = [[MGSLanguageProperty alloc] 
				initWithKey: MGS_LP_CanBuild 
				name:[self localizedString:@"MGSCanBuildName"]
				value:[self stringForBool:language.initCanBuild]];
	[langProp setRequestType:kMGSBuildRequest];
	[langProp setInfoText: [self localizedString:@"MGSCanBuildInfo"]];
	[langProperties setObject:langProp forKey:langProp.key];
	
	if (language.initCanBuild) {
		
		// Build Process Type
		langProp = [[MGSLanguageProperty alloc] 
					initWithKey: MGS_LP_BuildProcessType 
					name:[self localizedString:@"MGSBuildProcessTypeName"]
					value:[self stringForProcessType:language.initBuildProcessType]];
		[langProp setInfoText: [self localizedString:@"MGSBuildProcessTypeInfo"]];
		[langProp setRequestType:kMGSBuildRequest];
		[langProperties setObject:langProp forKey:langProp.key];

		// Separate syntax checker
		langProp = [[MGSLanguageProperty alloc] 
					initWithKey: MGS_LP_SeparateSyntaxChecker 
					name: [self localizedString:@"MGSSeparateSyntaxCheckerName"]
					value: [self stringForBool:language.initSeparateSyntaxChecker]];
		[langProp setRequestType:kMGSBuildRequest];
		[langProp setInfoText:[self localizedString:@"MGSSeparateSyntaxCheckerInfo"]];
		[langProperties setObject:langProp forKey:langProp.key];

		// Build accepts options
		langProp = [[MGSLanguageProperty alloc] 
					initWithKey: MGS_LP_BuildAcceptsOptions 
					name: [self localizedString:@"MGSBuildAcceptsOptionsName"]
					value:[self stringForBool:language.initBuildAcceptsOptions]];
		[langProp setRequestType:kMGSBuildRequest];
		[langProp setInfoText:[self localizedString:@"MGSBuildAcceptsOptionsInfo"]];
		[langProperties setObject:langProp forKey:langProp.key];

		
		// External Build Path
		if (language.initBuildProcessType == kMGSOutOfProcess && ![MGSLanguageProperty isMissingProperty:language.initExternalBuildPath]) {
			langProp = [[MGSLanguageProperty alloc] 
						initWithKey: MGS_LP_ExternalBuildPath 
						name: [self localizedString:@"MGSExternalBuildPathName"]
						value:language.initExternalBuildPath];
			[langProp setRequestType:kMGSBuildRequest];
			langProp.editable = YES;
			langProp.allowReset = YES;
			[langProp setInfoText:[self localizedString:@"MGSExternalBuildPathInfo"]];
			[langProperties setObject:langProp forKey:langProp.key];
		}
		
		// Build options
		if (language.initBuildAcceptsOptions) {
			langProp = [[MGSLanguageProperty alloc] 
						initWithKey: MGS_LP_BuildOptions 
						name: [self localizedString:@"MGSBuildOptionsName"]
						value:language.initBuildOptions];
			[langProp setRequestType:kMGSBuildRequest];
			langProp.editable = YES;
			langProp.allowReset = YES;
			[langProp setInfoText: [self localizedString:@"MGSBuildOptionsInfo"]];
			[langProperties setObject:langProp forKey:langProp.key];
		}
		
		// can ignore build warnings
		langProp = [[MGSLanguageProperty alloc] 
					initWithKey: MGS_LP_CanIgnoreBuildWarnings 
					name: [self localizedString:@"MGSCanIgnoreWarningsName"]
					value:[self stringForBool:language.initCanIgnoreBuildWarnings]];
		[langProp setRequestType:kMGSBuildRequest];
		[langProp setInfoText: [self localizedString:@"MGSCanIgnoreWarningsInfo"]];
		[langProperties setObject:langProp forKey:langProp.key];
	
	}
	
	/*====================================
	 
	 execute properties
	 
	 =====================================*/
	
	// Executor Process Type
	langProp = [[MGSLanguageProperty alloc] 
					initWithKey: MGS_LP_ExecutorProcessType 
					name: [self localizedString:@"MGSExecutorProcessTypeName"]
				value:[self stringForProcessType:language.initExecutorProcessType]];
	[langProp setRequestType:kMGSExecuteRequest];
	[langProp setInfoText: [self localizedString:@"MGSExecutorProcessTypeInfo"]];
	[langProperties setObject:langProp forKey:langProp.key];

	// Executable format
	langProp = [[MGSLanguageProperty alloc] 
				initWithKey: MGS_LP_ExecutableFormat 
				name: [self localizedString:@"MGSExecutableFormatName"]
				value:[self stringForExecutableFormat:language.initExecutableFormat]];
	[langProp setRequestType:kMGSExecuteRequest];
	[langProp setInfoText: [self localizedString:@"MGSExecutableFormatInfo"]];
	[langProperties setObject:langProp forKey:langProp.key];

	// Executor accepts options
	langProp = [[MGSLanguageProperty alloc] 
				initWithKey: MGS_LP_ExecutorAcceptsOptions 
				name: [self localizedString:@"MGSExecutorAcceptsOptionsName"]
				value:[self stringForBool:language.initExecutorAcceptsOptions]];
	[langProp setRequestType:kMGSExecuteRequest];
	[langProp setInfoText: [self localizedString:@"MGSExecutorAcceptsOptionsInfo"]];
	[langProperties setObject:langProp forKey:langProp.key];
	
	// External Executor Path
	if (language.initExecutorProcessType == kMGSOutOfProcess && ![MGSLanguageProperty isMissingProperty:language.initExternalExecutorPath]) {
		langProp = [[MGSLanguageProperty alloc] 
					initWithKey: MGS_LP_ExternalExecutorPath 
					name: [self localizedString:@"MGSExternalExecutablePathName"]
					value:language.initExternalExecutorPath];
		[langProp setRequestType:kMGSExecuteRequest];
		langProp.editable = YES;
		langProp.allowReset = YES;
		[langProp setInfoText: [self localizedString:@"MGSExternalExecutablePathInfo"]];
		[langProperties setObject:langProp forKey:langProp.key];
	}
	
	// Executor options
	if (language.initExecutorAcceptsOptions) {
		langProp = [[MGSLanguageProperty alloc] 
					initWithKey: MGS_LP_ExecutorOptions 
					name: [self localizedString:@"MGSExecutorOptionsName"]
					value:language.initExecutorOptions];
		[langProp setRequestType:kMGSExecuteRequest];
		langProp.editable = YES;
		langProp.allowReset = YES;
		[langProp setInfoText: [self localizedString:@"MGSExecutorOptionsInfo"]];
		[langProperties setObject:langProp forKey:langProp.key];
	}
	
	/*====================================
	 
	 language properties
	 
	 =====================================*/
	
	// language type
	langProp = [[MGSLanguageProperty alloc] 
				initWithKey: MGS_LP_LanguageType
				name: [self localizedString:@"MGSLanguageTypeName"]
				value:[self stringForLanguageType:language.initLanguageType]];
	[langProp setInfoText: [self localizedString:@"MGSLanguageTypeInfo"]];
	[langProperties setObject:langProp forKey:langProp.key];
	
	// is OSA language
	langProp = [[MGSLanguageProperty alloc] 
				initWithKey: MGS_LP_IsOSA 
				name: [self localizedString:@"MGSIsOSALanguageName"]
				value:[self stringForBool:language.initIsOsaLanguage]];
	[langProp setInfoText: [self localizedString:@"MGSIsOSALanguageInfo"]];
	[langProperties setObject:langProp forKey:langProp.key];
	

	// script type
	langProp = [[MGSLanguageProperty alloc] 
				initWithKey: MGS_LP_ScriptType 
				name: [self localizedString:@"MGSScriptTypeName"]
				value:language.initScriptType];
	[langProp setInfoText: [self localizedString:@"MGSScriptTypeInfo"]];
	[langProperties setObject:langProp forKey:langProp.key];
	
	// script type family
	langProp = [[MGSLanguageProperty alloc] 
				initWithKey: MGS_LP_ScriptTypeFamily 
				name: [self localizedString:@"MGSScriptTypeFamilyName"]
				value:language.initScriptTypeFamily];
	[langProp setInfoText:[self localizedString:@"MGSScriptTypeFamilyInfo"]];
	[langProperties setObject:langProp forKey:langProp.key];

	// task process name
	langProp = [[MGSLanguageProperty alloc] 
				initWithKey: MGS_LP_TaskProcessName 
				name: [self localizedString:@"MGSTaskRunnerProcessNameName"]
				value:language.initTaskProcessName];
	[langProp setInfoText:[self localizedString:@"MGSTaskRunnerProcessNameInfo"]];
	[langProperties setObject:langProp forKey:langProp.key];

	// valid for OS version
	langProp = [[MGSLanguageProperty alloc] 
				initWithKey: MGS_LP_ValidForOSVersion 
				name: [self localizedString:@"MGSValidForOSVersionName"]
				value:[self stringForBool:language.initValidForOSVersion]];
	[langProp setInfoText: [self localizedString:@"MGSValidForOSVersionInfo"]];
	[langProperties setObject:langProp forKey:langProp.key];
	
	// Is OS X supplied
	langProp = [[MGSLanguageProperty alloc] 
				initWithKey: MGS_LP_IsSuppliedByOSX 
				name: [self localizedString:@"MGSSuppliedByOSXName"]
				value:[self stringForBool:language.initLanguageShipsWithOS]];
	[langProp setInfoText: [self localizedString:@"MGSSuppliedByOSXInfo"]];
	[langProperties setObject:langProp forKey:langProp.key];
	
	// Is KosmicTask supplied
	langProp = [[MGSLanguageProperty alloc] 
				initWithKey: MGS_LP_IsSuppliedByKosmicTask 
				name: [self localizedString:@"MGSSuppliedByKosmicTaskName"]
				value:[self stringForBool:!language.initLanguageShipsWithOS]];
	[langProp setInfoText: [self localizedString:@"MGSSuppliedByKosmicTaskInfo"]];
	[langProperties setObject:langProp forKey:langProp.key];
	
	// source file extensions
	langProp = [[MGSLanguageProperty alloc] 
				initWithKey: MGS_LP_SourceFileExtensions
				name: [self localizedString:@"MGSSourceFileExtensionsName"]
				value:language.initSourceFileExtensions];
	//langProp.editable = YES;
	[langProp setInfoText: [self localizedString:@"MGSSourceFileExtensionsInfo"]];
	[langProperties setObject:langProp forKey:langProp.key];
	
	
	/*====================================
	 
	 Bridging
	 
	 =====================================*/
	// script is bridged to Cocoa
	langProp = [[MGSLanguageProperty alloc] 
				initWithKey: MGS_LP_IsCocoaBridge 
				name: [self localizedString:@"MGSIsCocoaBridgeName"]
				value:[self stringForBool:language.initIsCocoaBridge]];
	[langProp setInfoText: [self localizedString:@"MGSIsCocoaBridgeInfo"]];
	[langProp setRequestType:kMGSCocoaRequest];
	[langProperties setObject:langProp forKey:langProp.key];

	/*====================================
	 
	 Result representation
	 
	 =====================================*/

	// Native objects as results
	langProp = [[MGSLanguageProperty alloc] 
				initWithKey: MGS_LP_NativeObjectsAsResults 
				name: [self localizedString:@"MGSNativeObjectsAsResultsName"]
				value:[self stringForBool:language.initNativeObjectsAsResults]];
	[langProp setInfoText: [self localizedString:@"MGSNativeObjectsAsResultsInfo"]];
	[langProp setRequestType:kMGSResultRepresentationRequest];
	[langProperties setObject:langProp forKey:langProp.key];

	// Native objects as results
	langProp = [[MGSLanguageProperty alloc] 
				initWithKey: MGS_LP_NativeObjectsAsYamlSupport
				name: [self localizedString:@"MGSNativeObjectsAsYamlSupportName"]
				value:[self stringForBool:language.initNativeObjectsAsYamlSupport]];
	[langProp setInfoText: [self localizedString:@"MGSNativeObjectsAsYamlSupportInfo"]];
	[langProp setRequestType:kMGSResultRepresentationRequest];
	[langProperties setObject:langProp forKey:langProp.key];
	
	/*====================================
	 
	 task invocation properties
	 
	 =====================================*/
	
	// supports direct parameters (passed directly to the task, not through a named function)
	langProp = [[MGSLanguageProperty alloc] 
				initWithKey: MGS_LP_SupportsDirectParameters 
				name: [self localizedString:@"MGSSupportsDirectParametersName"]
				value:[self stringForBool:language.initSupportsDirectParameters]];
	[langProp setRequestType:kMGSInterfaceRequest];
	[langProp setInfoText: [self localizedString:@"MGSSupportsDirectParametersInfo"]];
	[langProperties setObject:langProp forKey:langProp.key];

	// supports script functions
	langProp = [[MGSLanguageProperty alloc] 
				initWithKey: MGS_LP_SupportsScriptFunctions 
				name: [self localizedString:@"MGSSupportsScriptFunctionsName"]
				value:[self stringForBool:language.initSupportsScriptFunctions]];
	[langProp setRequestType:kMGSInterfaceRequest];
	[langProp setInfoText: [self localizedString:@"MGSSupportsScriptFunctionsInfo"]];
	[langProperties setObject:langProp forKey:langProp.key];
	
	// supports classes
	langProp = [[MGSLanguageProperty alloc] 
				initWithKey: MGS_LP_SupportsClasses 
				name: [self localizedString:@"MGSSupportsClassesName"]
				value:[self stringForBool:language.initSupportsClasses]];
	[langProp setRequestType:kMGSInterfaceRequest];
	[langProp setInfoText: [self localizedString:@"MGSSupportsClassesInfo"]];
	[langProperties setObject:langProp forKey:langProp.key];

	// supports class functions
	langProp = [[MGSLanguageProperty alloc] 
				initWithKey: MGS_LP_SupportsClassFunctions
				name: [self localizedString:@"MGSSupportsClassFunctionsName"]
				value:[self stringForBool:language.initSupportsClassFunctions]];
	[langProp setRequestType:kMGSInterfaceRequest];
	[langProp setInfoText: [self localizedString:@"MGSSupportsClassFunctionsInfo"]];
	[langProperties setObject:langProp forKey:langProp.key];

	// default script function name
	if (language.initSupportsScriptFunctions && !language.initRequiredScriptFunction) {
		langProp = [[MGSLanguageProperty alloc] 
					initWithKey: MGS_LP_DefaultScriptFunction
					name: [self localizedString:@"MGSDefaultScriptFunctionName"]
					value:language.initDefaultScriptFunction];
		[langProp setRequestType:kMGSInterfaceRequest];
		[langProp setInfoText: [self localizedString:@"MGSDefaultScriptFunctionInfo"]];
		langProp.editable = YES;
		[langProperties setObject:langProp forKey:langProp.key];
	}
	
	// default class name
	if (language.initSupportsClasses && !language.initRequiredClass) {
		langProp = [[MGSLanguageProperty alloc] 
					initWithKey: MGS_LP_DefaultClass
					name: [self localizedString:@"MGSDefaultClassName"]
					value:language.initDefaultClass];
		[langProp setRequestType:kMGSInterfaceRequest];
		[langProp setInfoText: [self localizedString:@"MGSDefaultClassInfo"]];
		langProp.editable = YES;
		[langProperties setObject:langProp forKey:langProp.key];
	}

	// default class function
	if (language.initSupportsClassFunctions && !language.initRequiredClassFunction) {
		langProp = [[MGSLanguageProperty alloc] 
					initWithKey: MGS_LP_DefaultClassFunction
					name: [self localizedString:@"MGSDefaultClassFunctionName"]
					value:language.initDefaultClassFunction];
		[langProp setRequestType:kMGSInterfaceRequest];
		[langProp setInfoText: [self localizedString:@"MGSDefaultClassFunctionInfo"]];
		langProp.editable = YES;
		[langProperties setObject:langProp forKey:langProp.key];
	}
	
	// required script function name
	if (language.initRequiredScriptFunction) {
		langProp = [[MGSLanguageProperty alloc] 
					initWithKey: MGS_LP_RequiredScriptFunction
					name: [self localizedString:@"MGSRequiredScriptFunctionName"]
					value:language.initRequiredScriptFunction];
		[langProp setRequestType:kMGSInterfaceRequest];
		[langProp setInfoText: [self localizedString:@"MGSRequiredScriptFunctionInfo"]];
		[langProperties setObject:langProp forKey:langProp.key];
	}

	// required class name
	if (language.initRequiredClass) {
		langProp = [[MGSLanguageProperty alloc] 
					initWithKey: MGS_LP_RequiredClass
					name: [self localizedString:@"MGSRequiredClassName"]
					value:language.initRequiredClass];
		[langProp setRequestType:kMGSInterfaceRequest];
		[langProp setInfoText: [self localizedString:@"MGSRequiredClassInfo"]];
		[langProperties setObject:langProp forKey:langProp.key];
	}

	// required class function
	if (language.initRequiredClassFunction) {
		langProp = [[MGSLanguageProperty alloc] 
					initWithKey: MGS_LP_RequiredClassFunction
					name: [self localizedString:@"MGSRequiredClassFunctionName"]
					value:language.initRequiredClassFunction];
		[langProp setRequestType:kMGSInterfaceRequest];
		[langProp setInfoText: [self localizedString:@"MGSRequiredClassFunctionInfo"]];
		[langProperties setObject:langProp forKey:langProp.key];
		
		// required class function is static
		langProp = [[MGSLanguageProperty alloc] 
					initWithKey: MGS_LP_RequiredClassFunctionIsStatic
					name: [self localizedString:@"MGSRequiredClassFunctionIsStaticName"]
					value:[self stringForBool:language.initRequiredClassFunctionIsStatic]];
		[langProp setRequestType:kMGSInterfaceRequest];
		[langProp setInfoText: [self localizedString:@"MGSRequiredClassFunctionIsStaticInfo"]];
		[langProperties setObject:langProp forKey:langProp.key];		
		
	}
	
	
	
	/*====================================
	 
	 run configuration properties
	 
	 =====================================*/
	propOptions = [NSMutableDictionary dictionaryWithCapacity:5];
	if (language.initSupportsDirectParameters) {
		language.initOnRunTask = kMGSOnRunCallScript;
		[propOptions setObject:[self stringForOnRunTask:language.initOnRunTask] forKey:[NSNumber numberWithInteger:language.initOnRunTask]];
	}
	if (language.initSupportsScriptFunctions) {
		language.initOnRunTask = kMGSOnRunCallScriptFunction;
		[propOptions setObject:[self stringForOnRunTask:language.initOnRunTask] forKey:[NSNumber numberWithInteger:language.initOnRunTask]];
	}
	if (language.initSupportsClassFunctions) {
		language.initOnRunTask = kMGSOnRunCallClassFunction;
		[propOptions setObject:[self stringForOnRunTask:language.initOnRunTask] forKey:[NSNumber numberWithInteger:language.initOnRunTask]];
	}
	
	switch (language.initOnRunTask) {
		case kMGSOnRunCallScript:
		default:
			language.initRunFunction = @"";
			language.initRunClass = @"";
			break;
			
		case kMGSOnRunCallScriptFunction:
			language.initRunFunction = language.initDefaultScriptFunction;
			language.initRunClass = @"";
			break;
			
		case kMGSOnRunCallClassFunction:
			language.initRunFunction = language.initDefaultClassFunction;
			language.initRunClass = language.initDefaultClass;
			break;
	}
	
	// on run task
	langProp = [[MGSLanguageProperty alloc] 
				initWithKey: MGS_LP_OnRunTask 
				name: [self localizedString:@"MGSOnRunTaskName"]
				value:[self stringForOnRunTask:language.initOnRunTask]];
	[langProp setRequestType:kMGSRunRequest];
	[langProp setOptionValues:propOptions];
	[langProp setInfoText: [self localizedString:@"MGSOnRunTaskInfo"]];
	[langProperties setObject:langProp forKey:langProp.key];

	// run function
	if (language.initSupportsScriptFunctions || language.initSupportsClassFunctions) {
		langProp = [[MGSLanguageProperty alloc] 
					initWithKey: MGS_LP_RunFunction
					name: [self localizedString:@"MGSRunFunctionName"]
					value:language.initRunFunction];
		[langProp setRequestType:kMGSRunRequest];
		langProp.editable = YES;
		[langProp setInfoText: [self localizedString:@"MGSRunFunctionInfo"]];
		[langProperties setObject:langProp forKey:langProp.key];
	}
	
	// run class
	if (language.initSupportsClassFunctions) {
		langProp = [[MGSLanguageProperty alloc] 
					initWithKey: MGS_LP_RunClass
					name: [self localizedString:@"MGSRunClassName"]
					value:language.initRunClass];
		[langProp setRequestType:kMGSRunRequest];
		langProp.editable = YES;
		[langProp setInfoText: [self localizedString:@"MGSRunClassInfo"]];
		[langProperties setObject:langProp forKey:langProp.key];
	}
		
	// set delegate
	for (langProp in [langProperties allValues]) {
		langProp.delegate = self;
	}
	
	// assign the ivar
	languageProperties = langProperties;
	
	// validate the assigned property values
	// some values depend upon the value of others.
	// the delegate was not available when the values were set initially.
	// now we can call the didChange method to allow validation
	for (langProp in [langProperties allValues]) {
		[langProp.delegate languagePropertyDidChangeValue:langProp];
	}	
	
	return;
}


/*
 
 - updateLanguagePropertiesFromFile:
 
 */
- (void)updateLanguagePropertiesFromFile:(NSString *)filePath
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:filePath];
	if (dict) {
		[self updatePropertiesFromDictionary:dict];
	}
}

/*
 
 - updatePropertiesfromDictionary:
 
 */
- (void)updatePropertiesFromDictionary:(NSDictionary *)dict
{
	if (!dict) {
		return;
	}
	
	for (id key in [dict allKeys]) {
		MGSLanguageProperty *langProp = [self propertyForKey:key];
		if (langProp) {
			langProp.value = [dict objectForKey:key];
		}
	}
}

/*
 
 - reinitialiseProperties:
 
 */
- (void)reinitialiseProperties
{
	for (MGSLanguageProperty *langProp in [languageProperties allValues]) {
		if (langProp.canReset) {
			langProp.initialValue = langProp.value;
		}
	}
}

#pragma mark -
#pragma mark Localisation

/*
 
 - localizedString:
 
 */
- (NSString *)localizedString:(NSString *)key
{
	static NSMutableDictionary *localizedStringDictionary = nil;
	if (!localizedStringDictionary) {
		localizedStringDictionary = [NSMutableDictionary dictionaryWithCapacity:25];
	}
	NSString *str = [localizedStringDictionary objectForKey:key];
	if (!str) {
		str = [[NSBundle mainBundle] localizedStringForKey:key value:@"-missing-" table:@"MGSLanguageProcess"];
		[localizedStringDictionary setObject:str forKey:key];
	}
	
	return str;
}

#pragma mark -
#pragma mark Save and export
/*
 
 - exportLanguagePropertiesAtPath:
 
 */
- (void)exportLanguagePropertiesAtPath:(NSString *)thePath
{
	// settings are prepared dynamically
	exportPath = [thePath stringByAppendingPathComponent:@"Settings"];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	if (![fm fileExistsAtPath:exportPath]) {
		if (![fm createDirectoryAtPath:exportPath withIntermediateDirectories:YES attributes:nil error:NULL]) {
			NSLog(@"Failed to create properties path : %@", exportPath);
		}
	}
	
	// write resources.plist if missing
	NSString *resourcesFile = [exportPath stringByAppendingPathComponent:@"resources.plist"];	
	//if (![fm fileExistsAtPath:resourcesFile]) {
	NSMutableDictionary *resourcesDict = [NSMutableDictionary dictionaryWithCapacity:4];
	
	NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys:
								@"Mugginsoft", @"Author",
								[NSDate date], @"Date",
								[NSNumber numberWithInt:MGS_LP_PropertyResource_ID], @"ID",
								@"Language properties", @"Info",
								@"Properties", @"Name",
								nil];
	
	NSMutableArray *resourcesArray = [NSMutableArray arrayWithObjects: properties, nil];
	[resourcesDict setObject:resourcesArray forKey:@"Resources"];
	[resourcesDict setObject:[NSNumber numberWithInt:1] forKey:@"DefaultID"];
	
	if (![resourcesDict writeToFile:resourcesFile atomically:YES]) {
		NSLog(@"Failed to write resources file : %@", resourcesDict);
	}
	//}
	
	
	// save properties plist containing modified items
	NSString *file = [exportPath stringByAppendingPathComponent:@"1.plist"];
	[self updateLanguagePropertiesFromFile:file];		
}

/*
 
 - saveLanguageProperties:
 
 */
- (BOOL)saveLanguageProperties
{
	NSDictionary *optionsDict = [self dictionaryOfModifiedProperties];
	
	// save properties plist containing modified items
	NSString *file = [exportPath stringByAppendingPathComponent:@"1.plist"];	
	if (![optionsDict writeToFile:file atomically:YES]) {
		NSLog(@"Failed to write options file : %@", file);
		return NO;
	}
	
	return YES;
}

/*
 
 - dictToSave
 
 */
-(NSDictionary *)dictionaryOfModifiedProperties
{
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:10];
	
	for (MGSLanguageProperty *langProp in [self allProperties]) {
		if (!langProp.editable) continue;
		if (langProp.hasInitialValue && langProp.allowReset) continue;
		
		if (langProp.value && langProp.key) {
			[dictionary setObject:langProp.value forKey:langProp.key];
		}
	}
	
	return dictionary;
}

/*
 
 - dictWithPropertyType:requestType:
 
 */
-(NSDictionary *)dictWithPropertyType:(MGSLanguagePropertyType)propertyType requestType:(MGSLanguageRequestType)requestType
{
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:10];
	
	for (MGSLanguageProperty *langProp in [[self languageProperties] allValues]) {
		BOOL propertyMatch = NO;
		BOOL requestMatch = NO;
		
		// match property type
		if (propertyType == kMGSLanguagePropertyTypeAll ||
			propertyType == [langProp propertyType]) {
			propertyMatch = YES;
		}
		
		if (requestType == kMGSLanguageRequest ||
			requestType == [langProp requestType]) {
			requestMatch = YES;
		}
		
		if (!(propertyMatch && requestMatch)) continue;
		
		if (langProp.value && langProp.key) {
			[dictionary setObject:langProp.value forKey:langProp.key];
		}
	}
	
	return dictionary;
}

#pragma mark -
#pragma mark String representations
/*
 
 - stringForProcessType:
 
 */
- (NSString *)stringForProcessType:(eMGSProcessType)processType
{
	NSString *text = NSLocalizedString(@"unknown" , @"Unknown process type");
	switch (processType) {
			
		case kMGSInProcess:
			text = NSLocalizedString(@"In process" , @"In process type");
			break;
			
		case kMGSOutOfProcess:
			text = NSLocalizedString(@"External process" , @"External process type");
			break;
			
	}
	return text;
}

/*
 
 - stringForExecutableFormat:
 
 */
- (NSString *)stringForExecutableFormat:(eMGSExecutableFormat)format
{
	NSString *text = NSLocalizedString(@"unknown" , @"Unknown executable format");
	switch (format) {
			
		case kMGSSource:
			text = NSLocalizedString(@"Source text" , @"Source text");
			break;
			
		case kMGSCompiled:
			text = NSLocalizedString(@"Compiled code" , @"Compiled code");
			break;
			
	}
	return text;
}

/*
 
 - stringForOnRunTask:
 
 */
- (NSString *)stringForOnRunTask:(eMGSOnRunTask)value
{
	NSString *text = NSLocalizedString(@"unknown" , @"Unknown on run task value");
	switch (value) {
		
			/*
			 
			 note that thee string values below rather than eMGSOnRunTask are
			 persisted in the template.plist
			 
			 */
		case kMGSOnRunCallNone:
			text = NSLocalizedString(@"None" , @"On run task value");
			break;
			
		case kMGSOnRunCallScript:
			text = NSLocalizedString(@"Call script" , @"On run task value");
			break;

		case kMGSOnRunCallScriptFunction:
			text = NSLocalizedString(@"Call Run Function" , @"On run task value");
			break;

		case kMGSOnRunCallClassFunction:
			text = NSLocalizedString(@"Call Run Function on Run Class" , @"On run task value");
			break;
			
	}
	return text;
}

/*
 
 - stringForLanguageType:
 
 */
- (NSString *)stringForLanguageType:(eMGSLanguageType)format
{
	NSString *text = NSLocalizedString(@"unknown" , @"Unknown language type");
	switch (format) {
			
		case kMGSInterpretedLanguage:
			text = NSLocalizedString(@"Interpreted" , @"Interpreted language type");
			break;
			
		case kMGSCompiledLanguage:
			text = NSLocalizedString(@"Compiled" , @"Compiled language type");
			break;
			
	}
	return text;
}
/*
 
 - stringForBool:
 
 */
- (NSString *)stringForBool:(BOOL)value
{
	NSString *text = (value) ? NSLocalizedString(@"Yes" , @"Yes") : NSLocalizedString(@"No" , @"Yes");
	
	return text;
}

#pragma mark -
#pragma mark Tree handling

/*
 
 - treeForPropertyType
 
 */
- (NSMutableArray *)treeForPropertyType:(MGSLanguagePropertyType)propertyType
{
	NSString *name = @"";
	switch (propertyType) {
		case kMGSLanguagePropertyTypeAll:
			name = NSLocalizedString(@"Properties", @"Language properties all");
			break;
			
		case kMGSLanguageProperty:
			name = NSLocalizedString(@"Information", @"Language properties information");
			break;
			
		case kMGSLanguageEditableOption:
			name = NSLocalizedString(@"Options", @"Language properties options");
			break;
			
		default:
			NSAssert(NO, @"invalid switch code");
	}
	
	// array holds tree roots
	NSMutableArray *tree = [NSMutableArray arrayWithCapacity:10];
	
	// execute root
	name = NSLocalizedString(@"Execution Environment", @"Language process tree name");
	NSTreeNode *executorRootNode = [NSTreeNode treeNodeWithRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:
																	  name, @"name",
																	  @"", @"value",
																	  [NSNumber numberWithBool:NO], @"editable",
																	  nil]];
	// build root
	name = NSLocalizedString(@"Build Environment", @"Language process tree name");
	NSTreeNode *compilerRootNode = [NSTreeNode treeNodeWithRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:
																			  name, @"name",
																			  @"", @"value",
																			  [NSNumber numberWithBool:NO], @"editable",
																			  nil]];

	// task interface root
	name = NSLocalizedString(@"Task Interface", @"Task interface process tree name");
	NSTreeNode *interfaceRootNode = [NSTreeNode treeNodeWithRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:
																		  name, @"name",
																		  @"", @"value",
																		  [NSNumber numberWithBool:NO], @"editable",
																		  nil]];
	
	// language root
	name = NSLocalizedString(@"Language", @"Language process tree name");
	NSTreeNode *langRootNode = [NSTreeNode treeNodeWithRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:
																			  name, @"name",
																			  @"", @"value",
																			  [NSNumber numberWithBool:NO], @"editable",
																			  nil]];
	// configuration root
	name = NSLocalizedString(@"Run Configuration", @"Run configuration process tree name");
	NSTreeNode *runRootNode = [NSTreeNode treeNodeWithRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:
																		  name, @"name",
																		  @"", @"value",
																		  [NSNumber numberWithBool:NO], @"editable",
																		  nil]];

	// bridging root
	name = NSLocalizedString(@"Bridging", @"Bridging process tree name");
	NSTreeNode *bridgingRootNode = [NSTreeNode treeNodeWithRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:
																		 name, @"name",
																		 @"", @"value",
																		 [NSNumber numberWithBool:NO], @"editable",
																		 nil]];

	// result representation root
	name = NSLocalizedString(@"Result Representation", @"Result representation process tree name");
	NSTreeNode *resultRepresentationRootNode = [NSTreeNode treeNodeWithRepresentedObject:[NSDictionary dictionaryWithObjectsAndKeys:
																			  name, @"name",
																			  @"", @"value",
																			  [NSNumber numberWithBool:NO], @"editable",
																			  nil]];
	NSTreeNode *rootNode = nil;
	
	NSMutableArray *properties = [NSMutableArray arrayWithArray:[self allProperties]];
	NSSortDescriptor *desc = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
	[properties sortUsingDescriptors:[NSArray arrayWithObjects:desc, nil]];
	
	for (MGSLanguageProperty *langProp in properties) {
		if (langProp.propertyType == propertyType || propertyType == kMGSLanguagePropertyTypeAll) {
			NSTreeNode *childNode = [NSTreeNode treeNodeWithRepresentedObject:langProp];
			
			switch (langProp.requestType) {
				case kMGSExecuteRequest:
					rootNode = executorRootNode;
					break;

				case kMGSBuildRequest:
					rootNode = compilerRootNode;
					break;

				case kMGSInterfaceRequest:
					rootNode = interfaceRootNode;
					break;

				case kMGSRunRequest:
					rootNode = runRootNode;
					break;

				case kMGSCocoaRequest:
					rootNode = bridgingRootNode;
					break;

				case kMGSResultRepresentationRequest:
					rootNode = resultRepresentationRootNode;
					break;
					
				default:
					rootNode = langRootNode;
					break;
					
			}
			[[rootNode mutableChildNodes] addObject:childNode];
		}
	}

	[tree addObject:bridgingRootNode];
	[tree addObject:compilerRootNode];
	[tree addObject:executorRootNode];
	[tree addObject:langRootNode];
	[tree addObject:resultRepresentationRootNode];
	[tree addObject:runRootNode];
	[tree addObject:interfaceRootNode];
	
	return tree;
	
}


#pragma mark -
#pragma mark MGSLanguageProperty delegate

/*
 
 - languagePropertyDidChangeValue:
 
 most of the language properties are not mutable.
 some of those which are must be represented in the the script object.
 
 */
- (void)languagePropertyDidChangeValue:(MGSLanguageProperty *)langProperty
{
	if (!langProperty.editable) {
		return;
	}
	
	NSString *propKey = langProperty.key;
	NSNumber *optionKey = nil;
	
	id propValue = langProperty.value;
	if (!propValue) {
		MLogDebug(@"nil value for property: %@", propKey);
		return;
	}
	
	NSAssert([self languageProperties], @"language properties not available");
			 
	// on run task - call script, function or class function
	if ([propKey isEqualToString:MGS_LP_OnRunTask]) {
		
		MGSLanguageProperty *runFunctionProp = [self propertyForKey:MGS_LP_RunFunction];
		MGSLanguageProperty *runClassProp = [self propertyForKey:MGS_LP_RunClass];
		MGSLanguageProperty *defaultScriptFunctionProp = [self propertyForKey:MGS_LP_DefaultScriptFunction];
		MGSLanguageProperty *defaultClassFunctionProp = [self propertyForKey:MGS_LP_DefaultClassFunction];
		MGSLanguageProperty *defaultClassProp = [self propertyForKey:MGS_LP_DefaultClass];
		MGSLanguageProperty *requiredScriptFunctionProp = [self propertyForKey:MGS_LP_RequiredScriptFunction];
		MGSLanguageProperty *requiredClassProp = [self propertyForKey:MGS_LP_RequiredClass];
		MGSLanguageProperty *requiredClassFunctionProp = [self propertyForKey:MGS_LP_RequiredClassFunction];
				
		BOOL enableFunction = NO;
		BOOL enableClass = NO;
		NSString *functionName = @"";
		NSString *className = @"";
		
		optionKey = [langProperty keyForOptionValue];
				
		switch ([optionKey integerValue]) {
				
			case kMGSOnRunCallScript:
				break;
				
			case kMGSOnRunCallScriptFunction:
				if (!requiredScriptFunctionProp) {
					enableFunction = YES;
					functionName = runFunctionProp.value;
					if (!functionName || [functionName isEqualToString:@""]) {
						functionName = defaultScriptFunctionProp.value;
					}
				} else {
					functionName = requiredScriptFunctionProp.value;
				}
				break;
				
			case kMGSOnRunCallClassFunction:
				if (!requiredClassProp) {
					enableClass = YES;
					className = runClassProp.value;
					if (!className || [className isEqualToString:@""]) {
						className = defaultClassProp.value;
					}
				} else {
					className = requiredClassProp.value;
				}
				
				if (!requiredClassFunctionProp) {
					enableFunction = YES;
					functionName = runFunctionProp.value;
					if (!functionName || [functionName isEqualToString:@""]) {
						functionName = defaultClassFunctionProp.value;
					}
				} else {
					functionName = requiredClassFunctionProp.value;
				}
				
				break;
				
			default:	
			case kMGSOnRunCallNone:
				break;
		}
		
		runFunctionProp.editable = enableFunction;
		runFunctionProp.initialValue = functionName;
		runClassProp.editable = enableClass;
		runClassProp.initialValue = className;
	} 

	// inform delegate of change
	//if (delegate && [delegate respondsToSelector:@selector(languagePropertyDidChangeValue:)]) {
	//	[delegate languagePropertyDidChangeValue:langProperty];
	//}
	
	// post notification of change
	[[NSNotificationCenter defaultCenter] postNotificationName:MGSNoteLanguagePropertyDidChangeValue
										object:self
										userInfo:[NSDictionary dictionaryWithObjectsAndKeys:langProperty, MGSNoteKeyLanguageProperty, nil]];
}

#pragma mark -
#pragma mark Logging

/*
 
 - logPropertiesAction:
 
 */
- (void)logPropertiesAction:(id)sender
{
	MLogInfo(@"\nlogPropertiesAction sender = %@", sender);
	for (id key in [self allPropertyKeys]) {
		MGSLanguageProperty *langProp = [self propertyForKey:key];
		[langProp log];
	}
}


/*
 
 - log
 
 */
- (void)log
{
	[self logPropertiesAction:self];
}

@end
