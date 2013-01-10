//
//  MGSScript.h
//  Mother
//
//  Created by Jonathan on 08/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSDictionary.h"
#import "MGSScriptPlist.h"
#import "MGSPreferences.h"

extern NSString *MGSScriptOriginMugginsoft;

 enum _MGSScriptStatus {
	MGSScriptStatusNone = 0x0,
	MGSScriptStatusNew = 0x01,	// new script
	MGSScriptStatusExistsOnServer = 0x02,	// script created from file
 };
typedef NSInteger MGSScriptStatus;

enum _MGSScriptRepresentation {
	MGSScriptRepresentationUndefined = 0,	// empty representation
	MGSScriptRepresentationComplete = 1,	// complete representation - all dict keys defined
	MGSScriptRepresentationDisplay = 2,		// display representation - sufficient dict keys defined for display
	MGSScriptRepresentationSearch = 3,		// search representation - sufficient dict keys defined for search display
	MGSScriptRepresentationBuild = 4,		// compile representation - keys + source reqd for compilation
	MGSScriptRepresentationSave = 5,		// save representation - a complete rep minus any ephemeral keys
	MGSScriptRepresentationExecute = 6,		// execute representation - sufficient keys to execute the script
	MGSScriptRepresentationPreview = 7,		// preview representation - sufficient keys to preview the script
	MGSScriptRepresentationNegotiate = 8,	// negotiate representation - sufficient keys to negotiate the script
};

typedef NSInteger MGSScriptRepresentation;

@class MGSScriptParameterManager;
@class MGSScriptCode;
@class MGSError;
@class MGSNetRequest;
@class MGSNetAttachments;
@class MGSLanguagePlugin;
@class MGSLanguagePropertyManager;
@class MGSLanguageFunctionDescriptor;

@interface MGSScript : MGSDictionary {
	//
	// NOTE: if need to add new fields to the script do so by creating
	// new plist item within the base object dictionary. this will ensure that the
	// items are copied correctly. Remember that when accessing the dict as an MGSScript
	// the object is created on the fly.
	//
	// This object is to be treated strictly as a dictionary wrapper.
	// Don't modify this object, modify the dicitonary.
	//
	MGSScriptParameterManager *_parameterManager;
	MGSScriptCode *_scriptCode;
	
	NSString *templateName;
	BOOL _modelDataKVCModified;
	MGSLanguagePropertyManager *languagePropertyManager;
	BOOL syncingWithLanguageProperties;
}

+ (id)scriptWithContentsOfFile:(NSString *)filePath error:(MGSError **)mgsError;
+ (NSString *)fileUUID:(NSString *)UUID withPath:(NSString *)path;
+ (id)scriptWithDictionary:(NSMutableDictionary *)dict;
+ (BOOL)validateDictionary:(NSDictionary *)dict atPath:(NSString *)filePath;
+ (BOOL)validateDictionary:(NSDictionary *)dict;
+ (NSString *)defaultAuthor;
+ (NSArray *)validScriptTypes;
+ (BOOL)validateScriptType:(NSString *)scriptType;
+ (NSString *)defaultScriptType;
+ (NSString *)scriptTypeForFile:(NSString *)filename;
+ (BOOL)clientRepresentationRequiresAuthentication:(MGSScriptRepresentation)representation;
+ (NSInteger)timeoutSecondsForTimeout:(float)timeout timeoutUnits:(MGSTimeoutUnits)timeoutUnits;

- (NSString *)FileVersion;
- (NSString *)identifier;
- (NSArray *)scriptTypes;

- (NSDictionary *)executeTaskDictWithOptions:(NSDictionary *)options error:(MGSError **)error;
- (NSDictionary *)buildTaskDictWithOptions:(NSDictionary *)options error:(MGSError **)error;

// language
- (MGSLanguagePlugin *)languagePlugin;

// language property proxies
- (NSString *)externalBuildPath;
- (NSString *)buildOptions;
- (NSString *)externalExecutorPath;
- (NSString *)executorOptions;

- (id)duplicate;
- (NSString *)defaultPath;
- (NSString *)author;
- (void)setAuthor:(NSString *)aString;
- (NSString *)authorNote;
- (void)setAuthorNote:(NSString *)aString;
- (NSData *)longDescription;
- (void)setLongDescription:(NSData *)aString;
- (NSString *)group;
- (void)setGroup:(NSString *)aString;
- (id)mutableCopyWithZone:(NSZone *)zone;
- (BOOL)published;
- (void)setPublished:(BOOL)value;
- (BOOL)isValidGroupMember;
- (void)appendStringToName:(NSString *)appendage;

// script type
- (NSString *)scriptType;
- (void)setScriptType:(NSString *)aString;

// user interaction mode
- (MGSScriptUserModeInteraction)userInteractionMode;
- (void)setUserInteractionMode:(MGSScriptUserModeInteraction)value;

// runclass and subroutine to call in script
- (NSString *)runClass;
- (void)setRunClass:(NSString *)aString;
- (NSString *)subroutine;
- (void)setSubroutine:(NSString *)aString;
- (NSNumber *)onRun;
- (void)setOnRun:(NSNumber *)runMode;

// prohibit suspend
- (BOOL)prohibitSuspend;
- (void)setProhibitSuspend:(BOOL)value;

// prohibit terminate
- (BOOL)prohibitTerminate;
- (void)setProhibitTerminate:(BOOL)value;

// dates
- (NSDate *)created;
- (void)setCreated:(NSDate *)date;
- (NSDate *)modified;
- (void)setModified:(NSDate *)date;
- (void)setModifiedAuto:(BOOL)value;
- (BOOL)modifiedAuto;

// orgin
- (NSString *)origin;

// UUIDs
- (NSString *)UUID;
- (NSString *)UUIDWithPath:(NSString *)path;

// version numbers
//
// these may be modified by the user
- (void)setVersionMajor:(NSInteger)version;
- (NSInteger)versionMajor;
- (void)setVersionMinor:(NSInteger)version;
- (NSInteger)versionMinor;
- (void)setVersionRevision:(NSInteger)version;
- (NSInteger)versionRevision;
- (void)setVersionRevisionAuto:(BOOL)value;
- (BOOL)versionRevisionAuto;
- (void)incrementVersionRevision;

// version ID
//
// monotonically increasing ID
- (void)updateVersionID;
- (NSInteger)versionID;

- (void)setBundled:(BOOL)value;
- (BOOL)isBundled;
- (BOOL)canEdit;
- (BOOL)canExecute;

// options
- (float)timeout;
- (void)setTimeout:(float)timeout;
- (NSUInteger)timeoutUnits;
- (void)setTimeoutUnits:(NSUInteger)units;
- (void)setApplyTimeout:(BOOL)value;
- (BOOL)applyTimeout;
- (NSInteger)timeoutSeconds;
- (void)applyTimeoutDefaults;

- (MGSScriptStatus)scriptStatus;
- (void)setScriptStatus:(MGSScriptStatus)value;

- (BOOL)saveToPath:(NSString *)path error:(MGSError **)mgsError;
- (void)removeScriptCode;
- (NSString *)templateSource:(NSString *)insertion;
- (NSString *)templateSourcePrompt;
- (BOOL)syncWithScript:(MGSScript *)syncScript error:(MGSError **)mgsError;
- (NSData *)executableData;
- (NSString *)subroutineTemplate;

- (MGSNetAttachments *)attachmentsWithError:(MGSError **)mgsError;
- (NSString *)nameWithParameterValues ;

// label index 
- (void)setLabelIndex:(NSInteger)version;
- (NSInteger)labelIndex;

// rating index 
- (void)setRatingIndex:(NSInteger)version;
- (NSInteger)ratingIndex;

- (NSMutableDictionary *)localTaskDictionary;
- (void)updateFromTaskDictionary:(NSMutableDictionary *)localTaskDictionary;
- (void)updateFromCopy:(MGSScript *)script;
- (void)updateFromScript:(MGSScript *)script;
- (NSMutableDictionary *)searchRepresentationDictionary;
- (BOOL)conformToRepresentation:(MGSScriptRepresentation)representation;
- (MGSScriptRepresentation)representation;
- (BOOL)canConformToRepresentation:(MGSScriptRepresentation)representation;

- (NSImage *)bundledIcon;
- (NSImage *)publishedIcon;

// scheduling changes to property: published
- (void)setSchedulePublished:(BOOL)value;	// set value of scheduled change
- (BOOL)schedulePublished;					// returns YES if change scheduled
- (void)acceptSchedulePublished;			// accept the scheduled change
- (void)undoSchedulePublished;				// undo the scheduled change

// scheduling delete
- (void)undoScheduleDelete;
- (BOOL)scheduleDelete;
- (void)setScheduleDelete;

// scheduling save
- (BOOL)scheduleSave;
- (void)setScheduleSave;
- (void)acceptScheduleSave;

// templates
- (NSArray *)templateNames;

// validation
- (BOOL)validateOSVersion;

// KVC validation
- (BOOL)validateName:(id *)value error:(out NSError **)outError;
- (BOOL)validateGroup:(id *)value error:(out NSError **)outError;

- (void)updateLanguagePropertyManager:(MGSLanguagePropertyManager *)manager;

// key
- (NSString *)key;
- (NSString *)keyWithString:(NSString *)aString;
- (id)clone;

@property (readonly) MGSScriptParameterManager *parameterHandler;
@property (assign) MGSScriptCode *scriptCode;
@property BOOL modelDataKVCModified;
@property (copy) NSString *templateName;
@property (assign) MGSLanguagePropertyManager *languagePropertyManager;
@end
