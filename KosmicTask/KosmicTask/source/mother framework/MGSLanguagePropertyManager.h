//
//  MGSLanguagePropertyManager.h
//  KosmicTask
//
//  Created by Jonathan on 29/08/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSLanguageProperty.h"

@class MGSLanguage;

extern NSString * const MGSNoteLanguagePropertyDidChangeValue;
extern NSString * const MGSNoteKeyLanguageProperty;

@protocol MGSLanguagePropertyManagerDelegate
@required
-(void)languagePropertyDidChangeValue:(MGSLanguageProperty *)property;
@end

#define MGS_LP_ExecutorProcessType @"ExecutorProcessType"
#define MGS_LP_BuildProcessType @"BuildProcessType"
#define MGS_LP_ExecutorOptions @"ExecutorOptions"
#define MGS_LP_BuildOptions @"BuildOptions"

#define MGS_LP_ExternalExecutorPath @"ExternalExecutorPath"
#define MGS_LP_ExternalBuildPath @"ExternalBuildPath"

#define MGS_LP_CanBuild @"CanBuild"
#define MGS_LP_SeparateSyntaxChecker @"SeparateSyntaxChecker"
#define MGS_LP_ExecutableFormat @"ExecutableFormat"
#define MGS_LP_ExecutorAcceptsOptions @"ExecutorAcceptsOptions"
#define MGS_LP_BuildAcceptsOptions @"BuildAcceptsOptions"

#define MGS_LP_LanguageType @"LanguageType"
#define MGS_LP_IsOSA @"IsOSA"
#define MGS_LP_ScriptType @"ScriptType"
#define MGS_LP_ScriptTypeFamily @"ScriptTypeFamily"
#define MGS_LP_TaskProcessName @"TaskProcessName"
#define MGS_LP_ValidForOSVersion @"ValidForOSVersion"
#define MGS_LP_CanIgnoreBuildWarnings @"CanIgnoreBuildWarnings"
#define MGS_LP_IsSuppliedByOSX @"IsSuppliedByOSX"
#define MGS_LP_IsSuppliedByKosmicTask @"IsSuppliedByKosmicTask"

#define MGS_LP_SupportsDirectParameters @"SupportsDirectParameters"
#define MGS_LP_SupportsScriptFunctions @"SupportsScriptFunctions"
#define MGS_LP_SupportsClasses @"SupportsClasses"
#define MGS_LP_SupportsClassFunctions @"SupportsClassFunctions"
#define MGS_LP_RequiredClassFunctionIsStatic  @"RequiredClassFunctionIsStatic"
#define MGS_LP_DefaultClass @"DefaultClass"
#define MGS_LP_DefaultScriptFunction @"DefaultScriptFunction"
#define MGS_LP_DefaultClassFunction @"DefaultClassFunction"
#define MGS_LP_RequiredScriptFunction @"RequiredScriptFunction"
#define MGS_LP_RequiredClass @"RequiredClass"
#define MGS_LP_RequiredClassFunction @"RequiredClassFunction"

#define MGS_LP_OnRunTask @"OnRunTask"
#define MGS_LP_RunFunction @"RunFunction"
#define MGS_LP_RunClass @"RunClass"
#define MGS_LP_SourceFileExtensions @"SourceFileExtensions"

#define MGS_LP_IsCocoaBridge @"IsCocoaBridge"
#define MGS_LP_NativeObjectsAsResults @"NativeObjectsAsResults"
#define MGS_LP_NativeObjectsAsYamlSupport @"NativeObjectsAsYamlSupport"

#define MGS_LP_InputArgumentName @"InputArgumentName"
#define MGS_LP_InputArgumentCase @"InputArgumentCase"
#define MGS_LP_InputArgumentStyle @"InputArgumentStyle"

#define MGS_LP_Resource_ID 0
#define MGS_LP_PropertyResource_ID 1


@interface MGSLanguagePropertyManager : NSObject <NSCopying> {
	MGSLanguage *language;
	NSString *exportPath;
	NSMutableDictionary *languageProperties;
	
	//id delegate;
}

- (id)initWithLanguage:(MGSLanguage *)aLanguage;
- (void)initialiseProperties;
- (NSArray *)allProperties;
- (NSArray *)allPropertyKeys;
- (MGSLanguageProperty *)propertyForKey:(id)key;
- (NSDictionary *)dictWithPropertyType:(MGSLanguagePropertyType)propertyType requestType:(MGSLanguageRequestType)requestType;
- (void)exportLanguagePropertiesAtPath:(NSString *)thePath;
- (BOOL)saveLanguageProperties;
- (NSMutableArray *)treeForPropertyType:(MGSLanguagePropertyType)propertyType;
- (void)updatePropertiesFromDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryOfModifiedProperties;
- (void)languagePropertyDidChangeValue:(MGSLanguageProperty *)langProperty;
- (void)logPropertiesAction:(id)sender;
- (void)log;
- (void)reinitialiseProperties;

@property (readonly,copy) MGSLanguage *language;
@end
