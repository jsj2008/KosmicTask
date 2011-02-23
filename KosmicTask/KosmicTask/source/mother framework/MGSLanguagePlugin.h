//
//  MGSLanguagePlugin.h
//  KosmicTask
//
//  Created by Jonathan on 26/04/2010.
//  Copyright 2010 mugginsoft.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSPlugin.h"
#import "MGSScript.h"
#import "MGSScriptCode.h"
#import "MGSScriptParameter.h"
#import "MGSScriptParameterManager.h"
#import "mlog.h"
#import "MGSNetRequest.h"
#import "MGSNetMessage.h"
#import "MGSNetAttachments.h"
#import "MGSError.h"
#import "NSString_Mugginsoft.h"
#import "MGSPreferences.h"
#import "MGSTaskPlist.h"
#import "MGSLanguageResourcesManager.h"
#import "MGSResourceBrowserNode.h"
#import "MGSApplicationLanguageResourcesManager.h"
#import "MGSUserLanguageResourcesManager.h"
#import "MGSLanguagePropertyManager.h"
#import "MGSLanguage.h"

@class MGSLanguagePropertyManager;

extern NSString *MGSLanguagePluginDefaultClassName;
extern NSString *MGSLangPluginExecutePath ;
extern NSString *MGSLangPluginNetRequest;
extern NSString *MGSLangPluginTempPath;


@protocol MGSLanguagePlugin

@optional;

@end

@interface MGSLanguagePlugin : MGSPlugin <MGSLanguagePlugin, MGSResourcesManagerDelegate> {
	MGSApplicationLanguageResourcesManager *applicationResourcesManager;
	MGSUserLanguageResourcesManager *userResourcesManager;
	NSString *userResourcePath;
	NSString *userResourceName;
	NSString *applicationResourcePath;
	NSString *applicationResourceName;
	MGSLanguagePropertyManager *languagePropertyManager;
	MGSLanguage *language;
}

@property (readonly) MGSLanguageResourcesManager *applicationResourcesManager;
@property (readonly) MGSLanguageResourcesManager *userResourcesManager;
@property (readonly) MGSLanguagePropertyManager *languagePropertyManager;
@property (readonly, assign) MGSLanguage *language;


- (BOOL)validateOSVersion;
- (NSDictionary *)taskDictForScript:(MGSScript *)script options:(NSDictionary *)options error:(MGSError **)mgsError;
- (NSDictionary *)buildTaskDictForScript:(MGSScript *)script options:(NSDictionary *)options error:(MGSError **)mgsError;


- (void) loadApplicationResourcesAtPath:(NSString *)path name:(NSString *)name;
- (void) loadUserResourcesAtPath:(NSString *)path name:(NSString *)name;
- (MGSResourceBrowserNode *)resourceTreeAsCopy:(BOOL)copy;
- (MGSResourceItem *)defaultTemplateResource;
- (void)configureLanguageProperties:(MGSLanguagePropertyManager *)process;
- (BOOL)saveSettings;
- (Class)propertyManagerClass;
- (Class)languageClass;
- (BOOL)hasSourceFileExtension:(NSString *)extension;

- (BOOL)canIgnoreBuildWarnings;
- (NSString *)syntaxDefinition;
- (BOOL)isOSALanguage;
- (NSString *)scriptType;
- (NSString *)scriptTypeFamily;
- (void)getSystemVersionMajor:(unsigned *)major
                        minor:(unsigned *)minor
                       bugFix:(unsigned *)bugFix;
- (MGSBuildResultFlags)buildResultFlags;
- (NSString *)taskRunnerPath;
- (NSString *)taskRunnerClassName;
- (NSString *)taskProcessName;

@end
