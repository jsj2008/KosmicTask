//
//  MGSScript.m
//  Mother
//
//  Created by Jonathan on 08/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import "MGSMother.h"
#import "MGSScript.h"
#import "MGSScriptPlist.h"
#import "MGSScriptParameterManager.h"
#import "NSString_Mugginsoft.h"
#import "NSApplication_Mugginsoft.h"
#import "MGSScriptCode.h"
#import "MGSError.h"
#import "MGSNetRequest.h"
#import "MGSNetAttachments.h"
#import "MGSNetAttachment.h"
#import "MGSScriptParameter.h"
#import "MGSPath.h"
#import "MGSScriptManager.h"
#import "MGSImageManager.h"
#import "MGSPreferences.h"
#import "MGSResultFormat.h"
#import "MGSLanguagePluginController.h"
#import "MGSLanguageTemplateResourcesManager.h"
#import "MGSLanguageCodeDescriptor.h"

// script file versions
#define MGS_SCRIPT_FILE_VERSION_1_0 @"1.0"
#define MGS_SCRIPT_FILE_VERSION_1_1 @"1.1"
#define MGS_SCRIPT_FILE_VERSION_1_2 @"1.2"
#define MGS_SCRIPT_FILE_VERSION MGS_SCRIPT_FILE_VERSION_1_2

// script origin
NSString *MGSScriptOriginMugginsoft = @"Mugginsoft";
NSString *MGSScriptOriginUser = @"User";

static NSString *MGSScriptException = @"MGSScriptException";

MGS_INSTANCE_TRACKER_DEFINE;

const char MGSLangSettingsOnRunContext;

// class extension
@interface MGSScript()
- (BOOL)conformsToMinimalRepresentation;
- (BOOL)isValidForSave;
- (MGSLanguageTemplateResourcesManager *)templateManager;
+ (BOOL)versioniseDictionary:(NSMutableDictionary *)dict;
- (void)setExternalBuildPath:(NSString *)aString;
- (void)setBuildOptions:(NSString *)aString;
- (void)setExternalExecutorPath:(NSString *)aString;
- (void)setExecutorOptions:(NSString *)aString;
- (void)syncLanguagePropertiesWithScript;
- (void)retrieveLanguageProperties;
- (void)languagePropertyDidChangeValue:(NSNotification *)note;
- (BOOL)representationWithKeys:(NSArray *)representationKeys options:(NSDictionary *)options;
- (NSMutableArray *)keysForRepresentation:(MGSScriptRepresentation)representation;
- (void)setRepresentation:(MGSScriptRepresentation)value;
- (BOOL)conformToRepresentation:(MGSScriptRepresentation)representation options:(NSDictionary *)options;
- (void)setObject:(id)obj forKey:(NSString *)key options:(NSDictionary *)options;
@end

@interface MGSScript(Private)
- (void)createParameterHandler;
- (void)createCodeHandler;
@end

@implementation MGSScript

@synthesize parameterHandler = _parameterManager;
@synthesize modelDataKVCModified = _modelDataKVCModified;
@synthesize scriptCode = _scriptCode;
@synthesize templateName, languagePropertyManager;

#pragma mark -
#pragma mark Class Methods

/*
 
 create a new script
 
 */
+ (id)new
{
	MGSScript *script = [self newDict];

	[script setObject:MGSScriptIdentifier forKey:MGSScriptKeyIdentifier];
	[script setObject:MGS_SCRIPT_FILE_VERSION forKey:MGSScriptKeyFileVersion];
	
    // name and group must be defined and not nil or zero length
	[script setName: NSLocalizedString(@"Untitled", @"Default task name")];	
	[script setGroup: NSLocalizedString(@"Default", @"Default task group")];
	[script setDescription: NSLocalizedString(@"", @"Default task description")];	
    
	[script setPublished:NO];
	[script setScriptStatus:MGSScriptStatusNew];
	
	[script setScriptType:[self defaultScriptType]];

    // load user defaults
    NSString *stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"MGSTaskInputArgumentPrefix"];
    if (!stringValue) stringValue = @"";
    script.inputArgumentPrefix = stringValue;
    
    stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"MGSTaskInputArgumentExclusions"];
    if (!stringValue) stringValue = @"";
    script.inputArgumentNameExclusions  = stringValue;

	[script setUserInteractionMode:kMGSScriptUserModeCanInteractIfLocal];	// default to local interacting
	
	[script setAuthor:[self defaultAuthor]];
	
	// dates
	NSDate *dateNow = [NSDate date];
	[script setCreated:dateNow];
	[script setModified:dateNow];
	[script setModifiedAuto:YES];
	
	// version
	[script setVersionMajor:1];
	[script setVersionMinor:0];
	[script setVersionRevision:0];
	[script setVersionRevisionAuto:YES];

	// set version ID
	NSNumber *versionID = [NSNumber numberWithInteger:0];
	[script setObject:versionID forKey:MGSScriptKeyScriptUUID];

	// set the UUID for the script
	NSString *UUID = [NSString mgs_stringWithNewUUID];
	[script setObject:UUID forKey:MGSScriptKeyScriptUUID];
	
	[script createParameterHandler];
	[script createCodeHandler];
	[script setRepresentation:MGSScriptRepresentationComplete];
	[[script scriptCode] setSource:@""];
	
	// set the origin.
	// note there is no setter for this, nor should there be.
	[script setObject:MGSScriptOriginUser forKey:MGSScriptKeyOrigin];
		
	return script;
}
/*
 
 default author
 
 */
+ (NSString *)defaultAuthor
{
	NSString *author = [[MGSPreferences standardUserDefaults] objectForKey:MGSTaskAuthorName];
	author = [author stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	if (!author || [author length] == 0) {
		author = NSFullUserName();	// author is full user name not logon name
	} 
	
	if (!author) {
		author = @"-";
	}
	
	return author;
}

/*
 
 + defaultScriptType
 
 */
+ (NSString *)defaultScriptType
{
	return [[MGSLanguagePluginController sharedController]	defaultScriptType];
}
/*
 
 script with dictionary
 
 */
+ (id)scriptWithDictionary:(NSMutableDictionary *)dict
{
	if (!dict) return nil;
	
	// if dictionary has a representation then accept it.
	// otherwise validate it
	if (![dict objectForKey:MGSScriptKeyRepresentation]) {
		
		// dictionary must be valid and have a complete representation
		if (![[self class] validateDictionary:dict]) {
			return nil;
		}
	}
	
	// allocate script object
	id script = [[[self class] alloc] init];
	[script setDict:dict];
	
	// the script must conform to at least the minimal representation
	if (![script conformsToMinimalRepresentation]) {
		return nil;
	}
	
	return script;
}
/*
 
 create script from contents of file
 
 */
+ (id)scriptWithContentsOfFile:(NSString *)filePath error:(MGSError **)mgsError
{
	NSString *error = nil;

	// validate the path
	if (!filePath || ![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
		error = NSLocalizedString(@"Script file does not exist", @"Returned by server when script file not found");
		goto errorExit;
	}
	
	// validate that filename is a valid UUID
	NSString *UUID = [[filePath lastPathComponent] stringByDeletingPathExtension];
	if (![[UUID stringByDeletingPathExtension] mgs_isUUID]) {
		error = NSLocalizedString(@"Script file invalid filename UUID: %@", @"Returned by server when script filename contains invalid UUID");
		error = [NSString stringWithFormat:error, UUID];
		goto errorExit;
	}
	
	// load the dictionary
	NSMutableDictionary *fileDict = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
	if (nil == fileDict) {
		error = NSLocalizedString(@"Script dictionary load failed", @"Returned by server when script dictionary load fails");
		goto errorExit;
	}
	
	// add UUID to dictionary
	[fileDict setObject:UUID forKey:MGSScriptKeyScriptUUID];

	// versionise the dictionary
	if (![self versioniseDictionary:fileDict]) {
		error = NSLocalizedString(@"Could not convert script to current version", @"Returned by server when script dictionary load fails");
		goto errorExit;
	}
		
	// dictionary must be valid
	if (![[self class] validateDictionary:fileDict atPath:filePath]) {
		return nil;
	}

	// if we get this far then the script is a complete representation
	[fileDict setObject:[NSNumber numberWithInteger:MGSScriptRepresentationComplete] forKey:MGSScriptKeyRepresentation];
	
	// create script from dict dict
	MGSScript *script = [[self class] scriptWithDictionary:fileDict];
	
	// flag that the script exists on the server
	[script setScriptStatus:MGSScriptStatusExistsOnServer];
	
	return script;
	
errorExit:;
	MLog(RELEASELOG, error);
	*mgsError = [MGSError frameworkCode:MGSErrorCodeLoadScriptFromFile reason:error];
	return nil;
}

/*
 
 versionise dictionary
 
 */
+ (BOOL)versioniseDictionary:(NSMutableDictionary *)dict
{
	// get version
	NSString *version = [dict objectForKey: MGSScriptKeyFileVersion];
	if (nil == version) {
		NSString *error = NSLocalizedString(@"Script dictionary load failed - missing version key", @"Returned by server when script dictionary load fails");
		MLog(RELEASELOG, @"%@", error);
		return NO;
	}
	
    NSString *scriptType = [dict objectForKey: MGSScriptKeyScriptType];
    if (!scriptType) {
        return NO;
    }
    
	/*
     
     versionise 1.0 => 1.1
     
     */
	if ([version isEqualToString:MGS_SCRIPT_FILE_VERSION_1_0]) {
					
		// in app version 1.0 only AppleScript was supported.
		// AppleScript has an implicit run handler that runs a script when it is called without a named function.
		// The explicit form is "on run" or "on run {}".
		// Both forms are equivalent to sending the AppleScript object the open event.
		// KT 1.0 uses MGSScriptKeySubroutine with a value of MGSScriptSubroutineRun to indicate that the run handler is to be used.
		// KT > 1.0 uses MGSScriptKeyOnRun to indicate what to do when the scaript is run.
		NSString *codeSub = [dict objectForKey:MGSScriptKeySubroutine];
		NSInteger onRunMode = kMGSOnRunCallNone;
		if ([codeSub isEqualToString:MGSScriptSubroutineRun]) {
			
			[dict removeObjectForKey:MGSScriptKeySubroutine];
			
			onRunMode = kMGSOnRunCallScript;
		} else {
			
			// flag that a script function is to be called
			onRunMode = kMGSOnRunCallScriptFunction;
		}
		
		[dict setObject:[NSNumber numberWithInteger:onRunMode] forKey:MGSScriptKeyOnRun];

		// dict is now 1.1
		version = MGS_SCRIPT_FILE_VERSION_1_1;

		// update the file version to the current version
		[dict setObject:version forKey:MGSScriptKeyFileVersion];
	
		MLogDebug(@"Updated task %@ (UUID=%@) to version %@", [dict objectForKey:MGSScriptKeyName],  [dict objectForKey:MGSScriptKeyScriptUUID], version);
	}

	/*
     
     versionise 1.1 => 1.2
     
     */
	if ([version isEqualToString:MGS_SCRIPT_FILE_VERSION_1_1]) {
        
        MGSLanguagePlugin *plugin = [[MGSLanguagePluginController sharedController] pluginWithScriptType:scriptType];
        MGSLanguage *language = plugin.language;
        if (!language) return NO;
        
        // set script input argument properties
        [dict setObject:@(language.initInputArgumentName) forKey:MGSScriptInputArgumentName];
        [dict setObject:@(language.initInputArgumentCase) forKey:MGSScriptInputArgumentCase];
        [dict setObject:@(language.initInputArgumentStyle) forKey:MGSScriptInputArgumentStyle];
        
        NSString *stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"MGSTaskInputArgumentPrefix"] ;
        if (!stringValue) stringValue = @"";
        [dict setObject:stringValue forKey:MGSScriptInputArgumentPrefix];
        
        stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"MGSTaskInputArgumentExclusions"];
        if (!stringValue) stringValue = @"";
        [dict setObject:stringValue forKey:MGSScriptInputArgumentNameExclusions];
        
        // versionize parameters
        NSArray *parameters = [dict objectForKey:MGSScriptKeyParameters];
        for (NSMutableDictionary *parameter in parameters) {
            
            // add parameter UUID
            NSString *UUID = [NSString mgs_stringWithNewUUID];
            [parameter setObject:UUID forKey:MGSScriptKeyUUID];
        }
        
		// dict is now 1.2
		version = MGS_SCRIPT_FILE_VERSION_1_2;
        
		// update the file version to the current version
		[dict setObject:version forKey:MGSScriptKeyFileVersion];
        
		MLogDebug(@"Updated task %@ (UUID=%@) to version %@", [dict objectForKey:MGSScriptKeyName],  [dict objectForKey:MGSScriptKeyScriptUUID], version);
	}

	return YES;
}

/*
 
 validate dictionary
 
 */
+ (BOOL)validateDictionary:(NSDictionary *)dict 
{
	BOOL isValid = [[self class] validateDictionary:dict atPath:nil];
    
    return isValid;
}

/*
 
 validateScriptType:
 
 */
+ (BOOL)validateScriptType:(NSString *)scriptType
{
	return [[self validScriptTypes] containsObject:scriptType];
}
/*
 
 validScriptTypes
 
 */
+ (NSArray *)validScriptTypes
{

	return [[MGSLanguagePluginController sharedController] scriptTypes];

}

/*
 
 validate dictionary at path
 
 only a complete representation of a script can be saved so
 this method expects the dictionary at the given path to have a complete representation
 
 */
+ (BOOL)validateDictionary:(NSDictionary *)dict atPath:(NSString *)filePath
{
	// validate file path
	if (filePath) {
		
		// validate extension
		if (NSOrderedSame != [[filePath pathExtension] caseInsensitiveCompare:MGSScriptPlistExt]) {	
			return NO;
		}
		
		NSString *filename = [[filePath lastPathComponent] stringByDeletingPathExtension];
		NSString *UUID = [dict objectForKey:MGSScriptKeyScriptUUID];
		
		// filename must match UUID otherwise script file may not be found
		if (NSOrderedSame != [filename caseInsensitiveCompare:UUID]) {
			MLog(RELEASELOG, @"validation failed for script UUID: %@ at path: %@", UUID, filePath);
			return NO;
		}
	}
	
	if (!filePath) {
		filePath = @"none";
	}
	// validate dict
	
	// validate identifier
	id identifier = [dict objectForKey:MGSScriptKeyIdentifier];
	if (!identifier) {
		MLog(RELEASELOG, @"INVALID SCRIPT: no identifier key for script at path: %@", filePath);
		return NO;
	}
	if (![identifier isKindOfClass:[NSString class]]) {
		MLog(RELEASELOG, @"INVALID SCRIPT: non string identifier for script at path: %@", filePath);
		return NO;
	}
	if (NSOrderedSame != [(NSString *)identifier caseInsensitiveCompare:MGSScriptIdentifier]) {
		MLog(RELEASELOG, @"INVALID SCRIPT: invalid identifier %@ for script at path: %@", identifier, filePath);
		return NO;
	}
	
	// valiate file version
	if (![dict objectForKey:MGSScriptKeyFileVersion]) {
		MLog(RELEASELOG, @"INVALID SCRIPT: no file version key for script at path: %@", filePath);
		return NO;
	}
	
	// validate name
	if (![dict objectForKey:MGSScriptKeyName]) {
		MLog(RELEASELOG, @"INVALID SCRIPT: no name key for script at path: %@", filePath);
		return NO;
	}
	
	// validate UUID
	if (![dict objectForKey:MGSScriptKeyScriptUUID]) {
		MLog(RELEASELOG, @"INVALID SCRIPT: no UUID key for script at path: %@", filePath);
		return NO;
	}

	// validate code
	if (![dict objectForKey:MGSScriptKeyCode]) {
		MLog(RELEASELOG, @"INVALID SCRIPT: no code key for script at path: %@", filePath);
		return NO;
	}

	// validate on run
	if (![dict objectForKey:MGSScriptKeyOnRun]) {
		MLog(RELEASELOG, @"INVALID SCRIPT: no onRun key for script at path: %@", filePath);
		return NO;
	}
	
	// validate script type
	NSString *scriptType = [dict objectForKey:MGSScriptKeyScriptType];
	if (!scriptType) {
		MLog(RELEASELOG, @"INVALID SCRIPT: no script type key for script at path: %@", filePath);
		return NO;
	}
	if (![[self class] validateScriptType:scriptType]) {
		MLog(RELEASELOG, @"INVALID SCRIPT: invalid script type %@ for script at path: %@", scriptType, filePath);
		return NO;
	}
	
	return YES;
}
/*
 
 establish fileUUID with path
 
 */
+ (NSString *)fileUUID:(NSString *)UUID withPath:(NSString *)path
{
	NSString *UUIDPath = UUID;
	if (nil == UUIDPath) {
		MLog(DEBUGLOG, @"UUID is nil");
		return nil;
	}
	
	UUIDPath = [path stringByAppendingPathComponent:UUIDPath];
	UUIDPath = [UUIDPath stringByAppendingPathExtension:MGSScriptPlistExt];
	
	return UUIDPath;
}

/*
 
 - scriptTypeForFile:
 
 */
+ (NSString *)scriptTypeForFile:(NSString *)filename
{
	NSString *extension = [filename pathExtension];
	NSString *scriptType = nil;
	
	MGSLanguagePlugin *plugin = [[MGSLanguagePluginController sharedController] pluginForSourceFileExtension:extension];
	if (plugin) {
		scriptType = [plugin scriptType];
	}
	
	return scriptType;
}

/*
 
 + clientRepresentationRequiresAuthentication:
 
 */
+ (BOOL)clientRepresentationRequiresAuthentication:(MGSScriptRepresentation)representation
{
	switch (representation) {
			
		/*
		 
		 client must authenticate to access these representations
		 
		 */
		case MGSScriptRepresentationComplete:
			return YES;
			
		/*
		 
		 un authenticated clients may access these representations
		 
		 */
		case MGSScriptRepresentationUndefined:
		case MGSScriptRepresentationDisplay:
		case MGSScriptRepresentationSearch:
		case MGSScriptRepresentationBuild:
		case MGSScriptRepresentationSave:
		case MGSScriptRepresentationExecute:
		case MGSScriptRepresentationPreview:
			break;
			
		default:
			NSAssert(NO, @"invalid script representation");
	}

	return NO;
}

/*
 
 - timeoutSecondsForTimeout:timeoutUnits:
 
 */
+ (NSInteger)timeoutSecondsForTimeout:(float)timeout timeoutUnits:(MGSTimeoutUnits)timeoutUnits
{
    float mul = 0;
    switch (timeoutUnits) {
            
        case kMGSTimeoutHours:
            mul = 60 * 60;
            break;
            
        case kMGSTimeoutMinutes:
            mul = 60;
            break;
            
        case kMGSTimeoutSeconds:
        default:
            mul = 1;
            break;
    }
    
    return (NSInteger)(timeout * mul);
}

#pragma mark -
#pragma mark Instance Methods

/*
 
 - init
 
 */
- (id)init
{	self = [super init];
	if (self) {
		_modelDataKVCModified = NO;
		syncingWithLanguageProperties = NO;
        
        MGS_INSTANCE_TRACKER_ALLOCATE;
	}
	return self;
}


#pragma mark -
#pragma mark MGSTaskRunner dictionary representations
/*
 
 - executeTaskDictWithOptions:error:
 
 */
- (NSDictionary *)executeTaskDictWithOptions:(NSDictionary *)options error:(MGSError **)error
{	
	return [[self languagePlugin] taskDictForScript:self options:options error:error];
}

/*
 
 - buildTaskDictWithOptions:error:
 
 */
- (NSDictionary *)buildTaskDictWithOptions:(NSDictionary *)options error:(MGSError **)error
{	
	return [[self languagePlugin] buildTaskDictForScript:self options:options error:error];
}

#pragma mark -
#pragma mark NSCopying

/*
 
 duplicate
 
 */
- (id)duplicate
{
	MGSScript *dupl = [self mutableDeepCopy];
	
	// duplicate requires a unique UUID
	NSString *UUID = [NSString mgs_stringWithNewUUID];
	[dupl setObject:UUID forKey:MGSScriptKeyScriptUUID];
		
	// duplicated script cannot be bundled
	[dupl setBundled:NO];
	
	return dupl;
}

//
// 2 hours lost tracking bug here.
// initial copy code produced an immutable copy of the dictionary with copyWithZone
// need to implement - (id)mutableCopyWithZone:(NSZone *)zone
//
/*
 Copying Mutable Versus Immutable Objects
 
 Where the concept “immutable vs. mutable” applies to an object, NSCopying produces immutable copies whether the original is immutable or not. 
 Immutable classes can implement NSCopying very efficiently. 
 Since immutable objects don’t change, there is no need to duplicate them. 
 Instead, NSCopying can be implemented to retain the original. 
 For example, copyWithZone: for an immutable string class can be implemented in the following way.
 
 - (id)copyWithZone:(NSZone *)zone {
 return [self retain];
 }
 Use the NSMutableCopying protocol to make mutable copies of an object. 
 The object itself does not need to be mutable to support mutable copying. 
 The protocol declares the method mutableCopyWithZone:. 
 Mutable copying is commonly invoked with the convenience NSObject method mutableCopy, which invokes mutableCopyWithZone: with the default zone.
 */
- (id)mutableCopyWithZone:(NSZone *)zone
{
	// copy the superclass = this will create new instance of underlying dict
	// note that this will contain a deep copy of the dict
	MGSScript * aCopy = [super mutableCopyWithZone:zone];
	
	// copy local instance variables here
	// create parameter handler to point into dict
	[aCopy createParameterHandler];
	[aCopy createCodeHandler];

	return aCopy;
}

/*
 
 mutable deep copy
 
 */
- (id)mutableDeepCopy
{
	// copy the superclass = this will create new instance of underlying dict
	// note that this will contain a deep copy of the dict
	MGSScript * aCopy = [super mutableDeepCopy];
	
	// copy local instance variables here
	// create parameter handler to point into dict
	[aCopy createParameterHandler];
	[aCopy createCodeHandler];
	   
	return aCopy;
}

/*
 
 - clone
 
 */
- (id)clone
{
	id clone = [self mutableDeepCopy];
	
	return clone;
}
#pragma mark -
#pragma mark Memory management

/*
 
 - finalize
 
 */
- (void)finalize
{
#ifdef MGS_LOG_FINALIZE
    MLog(DEBUGLOG, @"MGSScript finalized");
#endif
    
    MGS_INSTANCE_TRACKER_DEALLOCATE;
    
	[super finalize];
}


#pragma mark -
#pragma mark NSKeyValueCoding

/*
 
 this will be called by the binding machinery to
 modify the model data
 
 */
- (void)setValue:(id)value forKeyPath:(NSString *)keyPath
{
	[super setValue:value forKeyPath:keyPath];
	self.modelDataKVCModified = YES;
}
- (void)setValue:(id)value forKey:(NSString *)key
{
    [super setValue:value forKey:key];
}
#pragma mark -
#pragma mark KVC validation

/*
 
 if the validates immediately bindings option is defined on the controller then these methods will be called.
  
 */
/*
 
 - validateValue:forKey:error:
 
 */
- (BOOL)validateValue:(id *)ioValue forKey:(NSString *)inKey error:(NSError **)outError 
{
    return [super validateValue:ioValue forKey:inKey error:outError];
}

/*
 
 - validateName:forKey:error:
 
 */ 
- (BOOL)validateName:(id *)inValue error:(out NSError **)outError
{
    NSString *value = (NSString *)*inValue;
    value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // value must be defined
    if (!value || [value length] == 0) {
        
        // note that an error sheet is displayed regardless of whether we define a custom
        // error message or not
        if (outError != NULL) {
            NSString *errorString = NSLocalizedString(@"Task name must be defined.", 
                                                      @"KVC validation: task name not defined error");
            NSDictionary *userInfoDict =
            [NSDictionary dictionaryWithObject:errorString forKey:NSLocalizedDescriptionKey];
            *outError = [[NSError alloc] initWithDomain:MGSErrorDomainMotherFramework
                                                   code:MGSErrorCodeTaskNameNotDefined
                                               userInfo:userInfoDict];
        }
        return NO;
    }
    
    return YES;
}

/*
 
 - validateValue:forKey:error:
 
 */ 
- (BOOL)validateGroup:(id *)inValue error:(out NSError **)outError
{
    
#pragma unused(outError)
    NSString *value = (NSString *)*inValue;
    value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // value must be defined
    if (!value || [value length] == 0) {
        
        // we don't return an error here as validating
        *inValue =  NSLocalizedString(@"Default", 
                                      @"KVC validation: default group name supplied");
    }
    
    return YES;
}

#pragma mark -
#pragma mark Author
/*
 
 author
 
 */
- (NSString *)author
{
	return [self objectForLocalizedKey:MGSScriptKeyAuthor];
}

/*
 
 set author
 
 */
- (void)setAuthor:(NSString *)aString
{
	[self setObject:aString forKey:MGSScriptKeyAuthor];
}

/*
 
 author note
 
 */
- (NSString *)authorNote
{
	return [self objectForLocalizedKey:MGSScriptKeyAuthorNote];
}

/*
 
 set author note
 
 */
- (void)setAuthorNote:(NSString *)aString
{
	[self setObject:aString forKey:MGSScriptKeyAuthorNote];
}

#pragma mark -
#pragma mark Behaviour
/*
 
 prohibit suspend
 
 */
- (BOOL)prohibitSuspend
{
	return [self boolForKey:MGSScriptKeyProhibitSuspend];
}

#pragma mark -
#pragma mark Bundle
/*
 
 local task dictionary
 
 dictionary of properties that are persisted on the client rather than the server
 
 */
- (NSMutableDictionary *)localTaskDictionary
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
	
	// color label index
	if ([self labelIndex] > 0) {
		[dict setObject:[NSNumber numberWithInteger:[self labelIndex]] forKey:MGSScriptKeyLabelIndex];
	}
	
	// rating index
	if ([self ratingIndex] > 0) {
		[dict setObject:[NSNumber numberWithInteger:[self ratingIndex]] forKey:MGSScriptKeyRatingIndex];
	}
	
	return dict;
}

/*
 
 update script with proerties from task dictionary
 
 */
- (void)updateFromTaskDictionary:(NSMutableDictionary *)dict
{
	// label index
	NSNumber *number = [dict objectForKey:MGSScriptKeyLabelIndex];
	if (number) {
		[self setLabelIndex:[number integerValue]];
	}
	
	// rating index
	number = [dict objectForKey:MGSScriptKeyRatingIndex];
	if (number) {
		[self setRatingIndex:[number integerValue]];
	}
	
}

/*
 
 bundled
 
 if script is marked as bundled then it ships with the application
 as part of the app bundle
 
 */
- (void)setBundled:(BOOL)value
{
	[self setBool:value forKey:MGSScriptKeyBundled];
}
- (BOOL)isBundled
{
	return [self boolForKey:MGSScriptKeyBundled];
}

#pragma mark -
#pragma mark Operations
/*
 
 can edit
 
 */
- (BOOL)canEdit 
{
	// can only edit bundled script
	if ([self isBundled]) {
		return [[MGSPreferences standardUserDefaults] boolForKey:MGSAllowEditApplicationTasks];
	}
	
	return YES;
}

/*
 
 - canExecute
 
 */
- (BOOL)canExecute
{
    return [self canConformToRepresentation:MGSScriptRepresentationExecute];
}
            
#pragma mark -
#pragma mark Name

- (void)setName:(NSString *)aString
{
	[super setName:aString];
}

#pragma mark -
#pragma mark Description

// long description
// NSData contains NSTextView RTFD
- (NSData *)longDescription
{
	NSData *data = [self objectForLocalizedKey:MGSScriptKeyLongDescription];
	return data;
}
- (void)setLongDescription:(NSData *)aString
{
	[self setObject:aString forLocalizedKey:MGSScriptKeyLongDescription];
}

#pragma mark -
#pragma mark Group
/*
 
 group
 
 */
- (NSString *)group
{
	NSString *group = [self objectForLocalizedKey:MGSScriptKeyGroup];
    
    // old scripts may have troublesome group names
    group = [group stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    return group;
}

/*
 
 set group
 
 */
- (void)setGroup:(NSString *)aString
{
    aString = [aString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
	[self setObject:aString forLocalizedKey:MGSScriptKeyGroup];
}

// determine if script should be considered a valid member of its group
- (BOOL)isValidGroupMember
{
	// do not group items scheduled for deletion
	if ([self scheduleDelete]) {
		return NO;
	}
	
	return YES;
}

#pragma mark -
#pragma mark Object updating

/*
 
 - setObject:forKey:options:
 
 */
- (void)setObject:(id)obj forKey:(NSString *)key options:(NSDictionary *)options
{
    BOOL updateRequired = YES;
    if (options) {
        
        /*
         
         Some of the script properties are backed by language properties that have to be kept in sync
         with the script property value.
         
         */
        NSString *languagePropertyKey = [options objectForKey:@"languagePropertyKey"];
        if (languagePropertyKey) {
            
            // get language property.
            // the language property may be nil if the language does not support this property.
            MGSLanguageProperty *langProp = [self.languagePropertyManager propertyForKey:languagePropertyKey];
            
            // validate the language property
            if (langProp) {
                
                // if property is a list then validate it.
                // our value is a key into the option list
                 if (langProp.isList) {
                    NSArray *values = [[langProp optionValues] allKeys];    // keys are index values
                    
                    if ([values containsObject:obj]) {
                        
                        // update this object
                        [self setObject:obj forKey:key];
                        updateRequired = NO;
                        
                        // update the language property option value if required.
                        // to prevent the possibility of infinite recursion only update if required.
                        if (![obj isEqual:[langProp keyForOptionValue]]) {
                            [langProp updateOptionKey:obj];
                        }
                        
                    } else {
                        MLogInfo(@"Invalid object %@ for key %@", obj, key);
                        
                        // we don't want to update this object as the value is invalid.
                        // perhaps we should set it to a known good value though?
                        updateRequired = NO;
                    }
                } else {
                    
                    // update this object
                    [self setObject:obj forKey:key];
                    updateRequired = NO;
                    
                    // update the language property value if required
                    // to prevent the possibility of infinite recursion only update if required.
                    if (![obj isEqual:[langProp value]]) {
                        [langProp setValue:obj];
                    }
                }
            }
        }
    }
    
    // ensure object gets set
    if (updateRequired) {
        [self setObject:obj forKey:key];
    }
    
}

#pragma mark -
#pragma mark Input arguments

/*
 
 - inputArgumentName
 
*/
- (MGSInputArgumentName)inputArgumentName
{
    return [[self objectForLocalizedKey:MGSScriptInputArgumentName] unsignedIntegerValue];
}

/*
 
 - setInputArgumentName:
 
*/
- (void)setInputArgumentName:(MGSInputArgumentName)value
{
    // update value for this object and the corresponding language property
    [self setObject:@(value) forKey:MGSScriptInputArgumentName options:@{@"languagePropertyKey":MGS_LP_InputArgumentName}];
}
/*
 
 - inputArgumentCase
 
*/
- (MGSInputArgumentCase)inputArgumentCase
{
    return [[self objectForLocalizedKey:MGSScriptInputArgumentCase] unsignedIntegerValue];
}
/*
 
 - setInputArgumentCase:
 
*/
- (void)setInputArgumentCase:(MGSInputArgumentCase)value
{
    // update value for this object and the corresponding language property
    [self setObject:@(value) forKey:MGSScriptInputArgumentCase options:@{@"languagePropertyKey":MGS_LP_InputArgumentCase}];
}
/*
 
 - inputArgumentStyle
 
*/
- (MGSInputArgumentStyle)inputArgumentStyle
{
    return [[self objectForLocalizedKey:MGSScriptInputArgumentStyle] unsignedIntegerValue];
}
/*
 
 - setInputArgumentStyle:
 
*/
- (void)setInputArgumentStyle:(MGSInputArgumentStyle)value
{
    // update value for this object and the corresponding language property
    [self setObject:@(value) forKey:MGSScriptInputArgumentStyle options:@{@"languagePropertyKey":MGS_LP_InputArgumentStyle}];
}
/*
 
 - inputArgumentPrefix
 
 */
- (NSString *)inputArgumentPrefix
{
    // this property is initialised from a preference rather than a language property
    return [self objectForLocalizedKey:MGSScriptInputArgumentPrefix];
}
/*
 
 - setInputArgumentPrefix:
 
 */
- (void)setInputArgumentPrefix:(NSString *)value
{
    [self setObject:value forKey:MGSScriptInputArgumentPrefix];
}
/*
 
 - inputArgumentNameExclusions
 
 */
- (NSString *)inputArgumentNameExclusions
{
    // this property is initialised from a preference rather than a language property
    return [self objectForLocalizedKey:MGSScriptInputArgumentNameExclusions];
}
/*
 
 - setInputArgumentNameExclusions:
 
 */
- (void)setInputArgumentNameExclusions:(NSString *)value
{
    [self setObject:value forKey:MGSScriptInputArgumentNameExclusions];
}


#pragma mark -
#pragma mark Language Settings

/*
 
 - languagePlugin
 
 */
- (MGSLanguagePlugin *)languagePlugin
{
	NSString *scriptType = [self scriptType];
	return [[MGSLanguagePluginController sharedController] pluginWithScriptType:scriptType];
}

/*
 
 - languagePropertyManager
 
 */
- (MGSLanguagePropertyManager *)languagePropertyManager
{
	/*
	 
	 the language property manager may not be initially available
	 for all reprsentations
	 
	 */
	if (!languagePropertyManager) {
		[self retrieveLanguageProperties];
		[self syncLanguagePropertiesWithScript];
	}
	return languagePropertyManager;
}

/*
 
 - setLanguagePropertyManager:
 
 */
- (void)setLanguagePropertyManager:(MGSLanguagePropertyManager *)manager
{
	if (languagePropertyManager) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:MGSNoteLanguagePropertyDidChangeValue object:languagePropertyManager];
	}
	
	languagePropertyManager = [manager copy];
	
	// observer changes to properties
	// when we update these language properties the corresponding script
	// properties will be updated
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(languagePropertyDidChangeValue:) 
										name:MGSNoteLanguagePropertyDidChangeValue
										object:languagePropertyManager];

}

/*
 
 - updateLanguagePropertyManager:
 
 */
- (void)updateLanguagePropertyManager:(MGSLanguagePropertyManager *)manager
{
	[self setLanguagePropertyManager:manager];
	[self syncScriptWithLanguageProperties];
}	

/*
 
 - retrieveLanguageProperties
 
 */
- (void)retrieveLanguageProperties
{
	// retrieve language properties to the script type
	MGSLanguagePlugin *plugin = [self languagePlugin];	
	[self setLanguagePropertyManager:[plugin languagePropertyManager]];
}

/*
 
 - syncLanguagePropertiesWithScript
 
 */
- (void)syncLanguagePropertiesWithScript
{
	
	syncingWithLanguageProperties = YES;
		
	// update properties with script values.
	// absent script values cause settings to retain their default values
	[[languagePropertyManager propertyForKey:MGS_LP_RunFunction] updateValue:[self subroutine]];
	[[languagePropertyManager propertyForKey:MGS_LP_RunClass] updateValue:[self runClass]];
	[[languagePropertyManager propertyForKey:MGS_LP_OnRunTask] updateOptionKey:[self onRun]];
	[[languagePropertyManager propertyForKey:MGS_LP_ExternalBuildPath] updateValue:[self externalBuildPath]];
	[[languagePropertyManager propertyForKey:MGS_LP_BuildOptions] updateValue:[self buildOptions]];
	[[languagePropertyManager propertyForKey:MGS_LP_ExternalExecutorPath] updateValue:[self externalExecutorPath]];
	[[languagePropertyManager propertyForKey:MGS_LP_ExecutorOptions] updateValue:[self executorOptions]];

    [[languagePropertyManager propertyForKey:MGS_LP_InputArgumentCase] updateOptionKey:@([self inputArgumentCase])];
    [[languagePropertyManager propertyForKey:MGS_LP_InputArgumentStyle] updateOptionKey:@([self inputArgumentStyle])];
    [[languagePropertyManager propertyForKey:MGS_LP_InputArgumentName] updateOptionKey:@([self inputArgumentName])];

	syncingWithLanguageProperties = NO;

}

/*
 
 - syncScriptWithLanguageProperties
 
 */
- (void)syncScriptWithLanguageProperties
{
    if (!languagePropertyManager) {
        return;
    }
    
	NSAssert(languagePropertyManager, @"languagePropertyManager is nil");
    id valueKey = nil;
    
	// onRun is mandatory.
	MGSLanguageProperty *langProp = [languagePropertyManager propertyForKey:MGS_LP_OnRunTask];
	valueKey = [langProp keyForOptionValue];
    if (langProp && ![self.onRun isEqual:valueKey]) {
        self.onRun = valueKey;
    }
    
	// an assertion raised here stops any new tasks from being created!
	// so just log the condition here
	if (![self onRun]) {
		MLogInfo(@"script onRun property is nil - the script is not properly initialised.");
	}
	
    /*
    
     the language property may be nil if the language does not support
     that property
     
     */
    
	// update script with property values
	// absent script values cause settings to retain their default values
    langProp = [languagePropertyManager propertyForKey:MGS_LP_RunFunction];
    if (langProp && ![langProp.value isEqual:self.subroutine]) {
        self.subroutine = langProp.value;
    }
          
    langProp = [languagePropertyManager propertyForKey:MGS_LP_RunClass];
    if (langProp && ![langProp.value isEqual:self.runClass]) {
        self.runClass = langProp.value;
    }
	
    langProp = [languagePropertyManager propertyForKey:MGS_LP_ExternalBuildPath];
    if (langProp && ![langProp.value isEqual:self.externalBuildPath]) {
        self.externalBuildPath = langProp.value;
    }
	
    langProp = [languagePropertyManager propertyForKey:MGS_LP_BuildOptions];
    if (langProp && ![langProp.value isEqual:self.buildOptions]) {
        self.buildOptions = langProp.value;
    }

    langProp = [languagePropertyManager propertyForKey:MGS_LP_ExternalExecutorPath];
    if (langProp && ![langProp.value isEqual:self.externalExecutorPath]) {
        self.externalExecutorPath = langProp.value;
    }
	
    langProp = [languagePropertyManager propertyForKey:MGS_LP_ExecutorOptions];
    if (langProp && ![langProp.value isEqual:self.executorOptions]) {
        self.executorOptions = langProp.value;
    }

    langProp = [languagePropertyManager propertyForKey:MGS_LP_InputArgumentName];
    valueKey = [langProp keyForOptionValue];
    NSAssert([valueKey isKindOfClass:[NSNumber class]], @"NSNumber expected found %@", [valueKey class]);
    if (self.inputArgumentName != [(NSNumber *)valueKey unsignedIntegerValue]) {
        self.inputArgumentName = [(NSNumber *)valueKey unsignedIntegerValue];
    }
    
    langProp = [languagePropertyManager propertyForKey:MGS_LP_InputArgumentCase];
    valueKey = [langProp keyForOptionValue];
    NSAssert([valueKey isKindOfClass:[NSNumber class]], @"NSNumber expected found %@", [valueKey class]);
    if (self.inputArgumentCase != [(NSNumber *)valueKey unsignedIntegerValue]) {
        self.inputArgumentCase = [(NSNumber *)valueKey unsignedIntegerValue];
    }
    
    langProp = [languagePropertyManager propertyForKey:MGS_LP_InputArgumentStyle];
    valueKey = [langProp keyForOptionValue];
    NSAssert([valueKey isKindOfClass:[NSNumber class]], @"NSNumber expected found %@", [valueKey class]);
    if (self.inputArgumentStyle != [(NSNumber *)valueKey unsignedIntegerValue]) {
        self.inputArgumentStyle =  [(NSNumber *)valueKey unsignedIntegerValue];
    }
}


#pragma mark -
#pragma mark MGSLanguageProperty proxies
/*
 
 - setExternalBuildPath:
 
 */
- (void)setExternalBuildPath:(NSString *)aString
{
	[self setObject:aString forKey:MGSScriptKeyExternalBuildPath  options:@{@"languagePropertyKey":MGS_LP_ExternalBuildPath}];
}
/*
 
 - externalBuildPath
 
 */
- (NSString *)externalBuildPath
{
	return [self objectForKey:MGSScriptKeyExternalBuildPath];
}

/*
 
 - setBuildOptions:
 
 */
- (void)setBuildOptions:(NSString *)aString
{
	[self setObject:aString forKey:MGSScriptKeyBuildOptions  options:@{@"languagePropertyKey":MGS_LP_BuildOptions}];
}
/*
 
 - buildOptions
 
 */
- (NSString *)buildOptions
{
	return [self objectForKey:MGSScriptKeyBuildOptions];
}

/*
 
 - setExternalExecutorPath:
 
 */
- (void)setExternalExecutorPath:(NSString *)aString
{
	[self setObject:aString forKey:MGSScriptKeyExternalExecutorPath options:@{@"languagePropertyKey":MGS_LP_ExternalExecutorPath}];
}
/*
 
 - externalBuildPath
 
 */
- (NSString *)externalExecutorPath
{
	return [self objectForKey:MGSScriptKeyExternalExecutorPath];
}

/*
 
 - setExecutorOptions:
 
 */
- (void)setExecutorOptions:(NSString *)aString
{
	[self setObject:aString forKey:MGSScriptKeyExecutorOptions  options:@{@"languagePropertyKey":MGS_LP_ExecutorOptions}];
}
/*
 
 - buildOptions
 
 */
- (NSString *)executorOptions
{
	return [self objectForKey:MGSScriptKeyExecutorOptions];
}

#pragma mark -
#pragma mark MGSLanguagePropertyManager notifications

/*
 
 - languagePropertyDidChangeValue:
 
 most of the language properties are not mutable.
 some of those which are must be represented in the the script object.
 
 */
- (void)languagePropertyDidChangeValue:(NSNotification *)note
{
	
	MGSLanguageProperty *langProperty = [[note userInfo] objectForKey:MGSNoteKeyLanguageProperty];
	
	if (syncingWithLanguageProperties) {
		return;
	}
	
	if (!langProperty.editable) {
		return;
	}
	
	NSString *propKey = langProperty.key;
	id optionKey = nil;
	
	id propValue = langProperty.value;
	if (!propValue) {
		MLogDebug(@"nil value for property: %@", propKey);
		return;
	}
	
	// sync properties with the script

	// script function to call
	if ([propKey isEqualToString:MGS_LP_RunFunction]) {
		[self setSubroutine:propValue];
	
	// class to call
	} else if ([propKey isEqualToString:MGS_LP_RunClass]) {
		[self setRunClass:propValue];
		
	// on run task - call script, function or class function
	} else if ([propKey isEqualToString:MGS_LP_OnRunTask]) {
        optionKey = [langProperty keyForOptionValue];
		[self setOnRun:optionKey];
		
	// external build path
	} else if ([propKey isEqualToString:MGS_LP_ExternalBuildPath]) {
		[self setExternalBuildPath:propValue];
		
	// build options
	} else if ([propKey isEqualToString:MGS_LP_BuildOptions]) {
		[self setBuildOptions:propValue];
		
	// external executor path
	} else if ([propKey isEqualToString:MGS_LP_ExternalExecutorPath]) {
		[self setExternalExecutorPath:propValue];
		
	// executor options
	} else if ([propKey isEqualToString:MGS_LP_ExecutorOptions]) {
		[self setExecutorOptions:propValue];
    
    } else if ([propKey isEqualToString:MGS_LP_InputArgumentCase]) {
        optionKey = [langProperty keyForOptionValue];
        [self setInputArgumentCase:[optionKey unsignedIntegerValue]];

    } else if ([propKey isEqualToString:MGS_LP_InputArgumentStyle]) {
        optionKey = [langProperty keyForOptionValue];
        [self setInputArgumentStyle:[optionKey unsignedIntegerValue]];

    } else if ([propKey isEqualToString:MGS_LP_InputArgumentName]) {
        optionKey = [langProperty keyForOptionValue];
        [self setInputArgumentName:[optionKey unsignedIntegerValue]];
    }
}

#pragma mark -
#pragma mark Representation
/*
 
 - setRepresentation:
 
 the underlying dictionary may not contain a full represntation of the script.
 searches for example will only return a minimal representation
 
 */
- (void)setRepresentation:(MGSScriptRepresentation)value
{
	switch (value) {
		case MGSScriptRepresentationUndefined:
		case MGSScriptRepresentationComplete:
		case MGSScriptRepresentationDisplay:
		case MGSScriptRepresentationSearch:
		case MGSScriptRepresentationBuild:
		case MGSScriptRepresentationSave:
		case MGSScriptRepresentationExecute:
		case MGSScriptRepresentationPreview:
		case MGSScriptRepresentationNegotiate:
			break;
			
		default:
			NSAssert(NO, @"invalid script representation");
	}
	
	[self setInteger:value forKey:MGSScriptKeyRepresentation];
}

/*
 
 - representation
 
 */
- (MGSScriptRepresentation)representation
{
	return [self integerForKey:MGSScriptKeyRepresentation];
}

/*
 
 - canConformToRepresentation:
 
 */
- (BOOL)canConformToRepresentation:(MGSScriptRepresentation)representation
{
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:NO], @"conform",
							 nil];
	return [self conformToRepresentation:representation options:options];
}

/*
 
 - conformToRepresentation:
 
 */
- (BOOL)conformToRepresentation:(MGSScriptRepresentation)representation
{
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], @"conform",
							 nil];

	return [self conformToRepresentation:representation options:options];
}

/*
 
 - conformToRepresentation:
 
 */
- (BOOL)conformToRepresentation:(MGSScriptRepresentation)representation options:(NSDictionary *)options
{
	BOOL success = YES;
	NSMutableArray *representationKeys = nil;
	BOOL conform = [[options objectForKey:@"conform"] boolValue];
	
	if ([self representation] == representation) {
		return YES;
	}
	
	// negotiate rpresentation
	if (representation == MGSScriptRepresentationNegotiate) {
		
		// we have to be able to negotiate all types of representations
		// as used by the various commands
		switch ([self representation]) {
				
				//
			case MGSScriptRepresentationComplete:
			case MGSScriptRepresentationDisplay:
			case MGSScriptRepresentationSearch:
			case MGSScriptRepresentationBuild:
			case MGSScriptRepresentationSave:
			case MGSScriptRepresentationExecute:
			case MGSScriptRepresentationPreview:
				if (conform) {
					representationKeys = [self keysForRepresentation:MGSScriptRepresentationNegotiate];
				}
				break;

			default:
				NSAssert(NO, @"bad script representation");
				break;
				
		}
		
	} else {

	
		// we can only conform to a representation that contains fewer
		// dictionary keys then we have presently
		switch ([self representation]) {
				
			// complete representation
			case MGSScriptRepresentationComplete:
				
				switch (representation) {
						
						// a representation suitable for the client to display.
						// a display representation can be used to generate an execute request.
					case MGSScriptRepresentationDisplay:
						if (conform) {
							[self removeScriptCode];
						}
						break;

						// a representation suitable for the client to preview
					case MGSScriptRepresentationPreview:
						if (conform) {
							[self removeScriptCode];
							representationKeys = [self keysForRepresentation:MGSScriptRepresentationPreview];
						}
						break;
						
						// a representation that the server can build
					case MGSScriptRepresentationBuild:
						success = [[self scriptCode] conformToRepresentation:MGSScriptCodeRepresentationBuild options:options];
						if (success && conform) {
							representationKeys = [self keysForRepresentation:MGSScriptRepresentationBuild];
						}
						break;
					
						// a representation that the server can save
					case MGSScriptRepresentationSave:
						success = [[self scriptCode] conformToRepresentation:MGSScriptCodeRepresentationSave options:options];

						if (success && conform) {
							// remove non persisting properties
							[self acceptScheduleSave];									// ephemeral
							[self removeObjectForKey:MGSScriptKeyStatus];			// ephemeral
							[self removeObjectForKey:MGSScriptKeySchedulePublished];	// ephemeral
							[self removeObjectForKey:MGSScriptKeyRatingIndex];			// saved in local plist
							[self removeObjectForKey:MGSScriptKeyLabelIndex];			// saved in local plist	
							[self removeObjectForKey:MGSScriptKeyPublished];			// saved in local plist
							
							// remove our UUID.
							// maintaining the UUID in the file raises the possibility of the file being renamed
							// to another valid UUID without the dict object being updated.
							// the UUID is recreated in the dict when first loaded from file.
							[self removeObjectForKey:MGSScriptKeyScriptUUID];
						}
						
						break;
						
						// a representation that the server can execute.
					case MGSScriptRepresentationExecute:
						/* if script is scheduled for save then a full representation
						   will be required in order to execute
						 */
                        // in the editor we have an unsaved complete rep that we should eb able to edit
						//if ([self scheduleSave]) {
						//	success = NO;
						//}
                            
                        if (conform) {
							success = [_parameterManager conformToRepresentation:MGSScriptParameterRepresentationExecute options:options];

							if (success) {
								representationKeys = [self keysForRepresentation:MGSScriptRepresentationExecute];
							}
						}
						break;
						
					default:
						success = NO;
						break;
				}
				
				break;
			
			// display representation
			case MGSScriptRepresentationDisplay:
				switch (representation) {
											
						// a representation that the server can execute.
						// as the current representation is display we can assume
						// that the script code resides on the server.
					case MGSScriptRepresentationExecute:
						success = [_parameterManager conformToRepresentation:MGSScriptParameterRepresentationExecute options:options];

						if (success && conform) {
							representationKeys = [self keysForRepresentation:MGSScriptRepresentationExecute];
						}
						break;
						
					default:
						success = NO;
						break;
				}
				break;
						
			default:
				success = NO;
				break;
				
		}
	}
	
	if (conform) {
		
		// if we have representation keys then use them
		if (representationKeys) {
			success = [self representationWithKeys:representationKeys options:nil];
		}
		
		if (success) {
			[self setRepresentation:representation];
		} else {
			MLogInfo(@"cannot conform to representation");
		}
	}
	
	return success;
}

/*
 
 - representationWithKeys:options:
 
 */
- (BOOL)representationWithKeys:(NSArray *)representationKeys options:(NSDictionary *)options
{
#pragma unused(options)
	if (!representationKeys) {
		MLogInfo(@"representation requested but keys are nil");
		return YES;
	}
	
	NSArray *allKeys = [[self dict] allKeys];
	
	// remove all keys not in our representationKeys
	for (NSString *aKey in allKeys) {
		if (![representationKeys containsObject:aKey]) {
			[self removeObjectForKey:aKey];
		}
	}
	
	return YES;
}

/*
 
 - keysForRepresentation:
 
 */
- (NSMutableArray *)keysForRepresentation:(MGSScriptRepresentation)representation
{
	NSMutableArray *keys = nil;
	
	switch (representation) {
			
		case MGSScriptRepresentationBuild:
			/*
			 
			 build may validate the run parameters
			 so include them by default
			 
			 */
			keys = [NSMutableArray arrayWithObjects:
						 MGSScriptKeyScriptUUID,
						 MGSScriptKeyScriptType,
						 MGSScriptKeyCode,
						 MGSScriptKeyOnRun,
						 MGSScriptKeyRunClass,
						 MGSScriptKeySubroutine,
						 MGSScriptKeyBuildOptions,
						 MGSScriptKeyExternalBuildPath,
						 nil];
			break;
			
		case MGSScriptRepresentationExecute:
			/*
			 
			 minimal key set to execute existing script
			 
			 */
			
			keys = [NSMutableArray arrayWithObjects:
						 MGSScriptKeyScriptUUID,
						 MGSScriptKeyScriptType,
						 MGSScriptKeyParameters,
						 MGSScriptKeyOnRun,
						 MGSScriptKeyRunClass,
						 MGSScriptKeySubroutine,
						 MGSScriptKeyBundled,
						 MGSScriptKeyExecutorOptions,
						 MGSScriptKeyExternalExecutorPath,
						 nil];
			
			break;
	
		case MGSScriptRepresentationPreview:
			/*
			 
			 minimal key set to preview a script
			 
			 */
			
			keys = [NSMutableArray arrayWithObjects:
					MGSScriptKeyScriptUUID,
					MGSScriptKeyScriptType,
					MGSScriptKeyBundled,
					MGSScriptKeyName,
					MGSScriptKeyDescription,
					MGSScriptKeyGroup,
					nil];
			
			break;
		
		case MGSScriptRepresentationNegotiate:
			/*
			 
			 minimal key set to negotiate a script
			 
			 */
			keys = [NSMutableArray arrayWithObjects:
					MGSScriptKeyScriptUUID,
					nil];
			break;
			
		default:
			break;
	}
	
	return keys;
}

/*
 
 script representation suitable for returning as a search result
 
 */
- (NSMutableDictionary *)searchRepresentationDictionary
{
	NSMutableDictionary *repDict = nil;
	
	@try { 
		repDict = [NSMutableDictionary 
						dictionaryWithObjectsAndKeys: 
						[NSNumber numberWithInteger:MGSScriptRepresentationSearch], MGSScriptKeyRepresentation,
						[self UUID], MGSScriptKeyScriptUUID, 
						[self name], MGSScriptKeyName, 
						[self scriptType], MGSScriptKeyScriptType,	// without this we cannot get the plugin
						[self group], MGSScriptKeyGroup, 
						[self description], MGSScriptKeyDescription,
						[NSNumber numberWithBool:[self isBundled]], MGSScriptKeyBundled,
						nil];
	} @catch(NSException *e)
	{
		MLog(RELEASELOG, @"Exception forming script search representation: %@", [e name]);
		repDict = nil;
	}
	
	return repDict;
}

/*
 
 - conformsToMinimalRepresentation
 
 */
- (BOOL)conformsToMinimalRepresentation
{
	// valid UUID is mandatory
	if (![[self UUID] mgs_isUUID]) {
		MLogInfo(@"Script UUID is invalid");
		return NO;;
	}
	
	// representation is mandatory
	switch ([self representation]) {
		case MGSScriptRepresentationComplete:
		case MGSScriptRepresentationDisplay:
		case MGSScriptRepresentationSearch:
		case MGSScriptRepresentationBuild:
		case MGSScriptRepresentationSave:
		case MGSScriptRepresentationExecute:
		case MGSScriptRepresentationPreview:
		case MGSScriptRepresentationNegotiate:
			break;
			
		default:
			MLogInfo(@"Script representation is invalid");
			return NO;
	}
	
	return YES;
}

#pragma mark -
#pragma mark key


/*
 
 - key
 
 */
- (NSString *)key
{
	/*
	 
	 we may wish to use the script object as a key.
	 however keys are usually copied, which is undesirable for a object such as this.
	 hence we require a unique key.
	 
	 */
	return [self keyWithString:nil];
}
/*
 
 - keyWithString:
 
 */
- (NSString *)keyWithString:(NSString *)aString
{
	
	if (!aString) {
		aString = @"";
	}
	/*
	 
	the script may appear repeatedly in some collections.
	hence we offer additional keys.
	 
	 */
	return [NSString stringWithFormat:@"%@%@", aString, [self UUID]];
}


#pragma mark -
#pragma mark UUID

/*
 
 - UUID
 
 */
- (NSString *)UUID 
{
	return [self objectForKey:MGSScriptKeyScriptUUID];
}

/*
 
 establish UUID with path
 
 */
- (NSString *)UUIDWithPath:(NSString *)path
{
	return [[self class] fileUUID:[self UUID] withPath:path];
}

/*
 
 set dict
 
 */
- (void)setDict:(NSMutableDictionary *)dict
{
#pragma mark warning need to validate the dict here somewhere
	
	@try {
		// note that testing -isKindOfClass is defective.
		// due to class clustering all instances of NSDictionary are NSCFDictionary.
		// and all of them look mutable.
		//NSAssert([object isKindOfClass:[NSMutableDictionary class]], @"dictionary not mutable");
		NSAssert([dict classForCoder] == [NSMutableDictionary class], @"dict is not mutable");

		[super setDict:dict];
		[self createParameterHandler];
		[self createCodeHandler];
		
		/*
		 
		 a complete representation will have its language properties defined
		 
		 */
		if ([self representation] == MGSScriptRepresentationComplete) {
			[self retrieveLanguageProperties];
			[self syncLanguagePropertiesWithScript];
		}
			
	} @catch (NSException *e) {
		MLog(RELEASELOG, @"exception: %@", [e reason]);
	}
}

#pragma mark -
#pragma mark Updating
/*
 
 - updateFromCopy:
 
 */
- (void)updateFromCopy:(MGSScript *)script
{
	if (![[self UUID] isEqualToString:[script UUID]]) {
		[NSException raise:MGSScriptException format:@"attempted to updated script from non copy"];
	}
		  
	[self updateFromScript:script];
}

/*
 
 - updateFromScript:
 
 */
- (void)updateFromScript:(MGSScript *)script
{
	[self copyDictFrom:script];
}
/*
 
 - updateFromScript:options:
 
 */
- (void)updateFromScript:(MGSScript *)script options:(NSDictionary *)options
{
    NSArray * updates = [options objectForKey:@"updates"];
    
    // find and apply updates
    if (updates && [updates isKindOfClass:[NSArray class]]) {
        
        // script type
        if ([updates containsObject:@"scriptType"]) {
            if (script.scriptType != self.scriptType) {
                self.scriptType = script.scriptType;
            }
        }
        
        // all input arguments
        if ([updates containsObject:@"allInputArguments"]) {
            self.inputArgumentName = script.inputArgumentName;
            self.inputArgumentCase = script.inputArgumentCase;
            self.inputArgumentStyle = script.inputArgumentStyle;
            self.inputArgumentPrefix = script.inputArgumentPrefix;
            self.inputArgumentNameExclusions = script.inputArgumentNameExclusions;
        }
        
        // all parameter variables
        if ([updates containsObject:@"allScriptParameterVariables"]) {
            if (self.parameterHandler.count == script.parameterHandler.count) {
                for (NSInteger i = 0; i < self.parameterHandler.count; i++) {
                    MGSScriptParameter *scriptParameter = [self.parameterHandler itemAtIndex:i];
                    MGSScriptParameter *scriptParameter2 = [script.parameterHandler itemAtIndex:i];
                    
                    // update
                    [scriptParameter updateFromScriptParameter:scriptParameter2 options:options];
                }
            } else {
                NSLog(@"Cannot update parameter variables from script. Parameter counts differ.");
            }
        }
        
    }

}
#pragma mark -
#pragma mark Timeout
/*
 
 - timeoutSeconds
 
 */
- (NSInteger)timeoutSeconds
{
    return [[self class] timeoutSecondsForTimeout:[self timeout] timeoutUnits:[self timeoutUnits]];
}

/*
 
 - timeout
 
 */
- (float)timeout
{
	NSNumber *number = [self objectForLocalizedKey:MGSScriptKeyTimeout];
	if (number) {
		return [number floatValue];
	}
	
	return 0.0f;
}
/*
 
 - setTimeout:
 
 */
- (void)setTimeout:(float)timeout
{
	[self setObject:[NSNumber numberWithFloat:timeout] forLocalizedKey:MGSScriptKeyTimeout];
}

/*
 
 - timeoutUnits
 
 */
- (NSUInteger)timeoutUnits
{
	NSNumber *number = [self objectForLocalizedKey:MGSScriptKeyTimeoutUnits];
	if (number) {
		return [number unsignedIntegerValue];
	}
	
	return kMGSTimeoutSeconds;
}

/*
 
 - setTimeoutUnits:
 
 */
- (void)setTimeoutUnits:(NSUInteger)units
{
	[self setObject:[NSNumber numberWithUnsignedInteger:units] forLocalizedKey:MGSScriptKeyTimeoutUnits];
}

/*
 
 - setApplyTimeout:
 
 */
- (void)setApplyTimeout:(BOOL)value
{
	[self setObject:[NSNumber numberWithBool:value] forLocalizedKey:MGSScriptKeyApplyTimeout];
}

/*
 
 - applyTimeout
 
 */
- (BOOL)applyTimeout
{
	NSNumber *number = [self objectForLocalizedKey:MGSScriptKeyApplyTimeout];
	if (number) {
		return [number boolValue];
	}
	
    // if we have a timeout defined then for compatability we apply it
    if ((NSInteger)[self timeout] >= 1) {
        return true;
    }
    
	return false;
}

/*
 
 - applyTimeoutDefaults
 
 */
- (void)applyTimeoutDefaults
{
    if ([self timeout] < 1) {
        
        NSInteger timeout = [[MGSPreferences standardUserDefaults] integerForKey:MGSLocalUserTaskTimeout];
        NSUInteger timeoutUnits = [[MGSPreferences standardUserDefaults] integerForKey:MGSLocalUserTaskTimeoutUnits];
        BOOL useTimeout = [[MGSPreferences standardUserDefaults] integerForKey:MGSApplyTimeoutToLocalUserTasks];
        
        [self setTimeout:timeout];
        [self setTimeoutUnits:timeoutUnits];
        [self setApplyTimeout:useTimeout];
    }
}


/*
 
 set prohibit suspend
 
 */
- (void)setProhibitSuspend:(BOOL)value
{
	[self setBool:value forKey:MGSScriptKeyProhibitSuspend];
}

/*
 
 prohibit terminate
 
 */
- (BOOL)prohibitTerminate
{
	return [self boolForKey:MGSScriptKeyProhibitTerminate];
}

/*
 
 set prohibit terminate
 
 */
- (void)setProhibitTerminate:(BOOL)value
{
	[self setBool:value forKey:MGSScriptKeyProhibitTerminate];
}


#pragma mark -
#pragma mark Modification

// created
- (NSDate *)created
{
	return [self objectForKey:MGSScriptKeyCreated];
}
- (void)setCreated:(NSDate *)date
{
	[self setObject:date forKey:MGSScriptKeyCreated];
}

/*
 
 modified
 
 */
- (NSDate *)modified
{
	return [self objectForKey:MGSScriptKeyModified];
}
- (void)setModified:(NSDate *)date
{
	[self setObject:date forKey:MGSScriptKeyModified];
}
/*
 
 modified auto increment
 
 */
- (void)setModifiedAuto:(BOOL)value
{
	[self setBool:value forKey:MGSScriptKeyModifiedAuto];
}
- (BOOL)modifiedAuto
{
	return [self boolForKey:MGSScriptKeyModifiedAuto];
}

#pragma mark -
#pragma mark Origin

/*
 
 origin
 
 this property cannot be changed.
 scripts which ship with the app will have this preset to Mugginsoft.
 otherwise it will return User
 
 */
- (NSString *)origin
{
	return [self objectForKey:MGSScriptKeyOrigin];
}

#pragma mark -
#pragma mark Identifier
/*
 
 identifier
 
 */
- (NSString *)identifier
{
	return [self objectForLocalizedKey:MGSScriptKeyIdentifier];
}


#pragma mark -
#pragma mark Images

/*
 
 bundled icon
 
 */
- (NSImage *)bundledIcon
{
	if ([self isBundled]) {
		return [NSImage imageNamed:@"GearSmall"];
	} else {
		return [[(MGSImageManager *)[MGSImageManager sharedManager] user] copy];
	}
}
/*
 
 published icon
 
 */
- (NSImage *)publishedIcon
{
	if ([self published]) {
		return [[[MGSImageManager sharedManager] publishedActionTemplate] copy];
	} else {
		return nil;
	}
}


#pragma mark -
#pragma mark Name
/*
 
 append string to name
 
 */
- (void)appendStringToName:(NSString *)appendage
{
	NSString *newScriptName = [[self name] stringByAppendingString:appendage];
	[self setName:newScriptName];
}


#pragma mark -
#pragma mark Published
/*
 
 published
 
 */
- (BOOL)published
{
	return [self boolForKey:MGSScriptKeyPublished];
}
/*
 
 published
 
 */
- (void)setPublished:(BOOL)value
{
	[self setBool:value forKey:MGSScriptKeyPublished];
}

/*
 
 returns YES if schedule published key exists
 
 */
- (BOOL)schedulePublished
{
	// if the key exists then the published property has been modified
	return [self objectForKey:MGSScriptKeySchedulePublished] != nil ? YES : NO;
}
/*
 
 schedule a change to the published property.
 
 */
- (void)setSchedulePublished:(BOOL)value
{
	// if prior key does not exist then create it.
	// the presence of this key indicates that a publication change has occurred.
	// it also stores the prior value in case an undo is required
	if (![self schedulePublished]) {
		[self setBool:[self published] forKey:MGSScriptKeySchedulePublished];
	}
	
	[self setPublished:value];
}

/*
 
 undo schedule for publish 
 
 */
- (void)undoSchedulePublished
{
	if ([self schedulePublished]) {
		
		// reset published property with value retained in schedulePublished
		[self setPublished:[self boolForKey:MGSScriptKeySchedulePublished]];
		
		[self acceptSchedulePublished];
	}
}

/*
 
 accept scheduled change for publish 
 
 */
- (void)acceptSchedulePublished
{
	if ([self schedulePublished]) {
				
		// accept change by removing schedule published key
		[self removeObjectForKey:MGSScriptKeySchedulePublished];
	}
}

#pragma mark -
#pragma mark Schedule Delete
/*
 
 schedule delete
 
 */
- (void)setScheduleDelete
{
	[self setBool:YES forKey:MGSScriptKeyScheduleForDeletion];
}
/*
 
 schedule delete
 
 */
- (BOOL)scheduleDelete
{
	return [self boolForKey:MGSScriptKeyScheduleForDeletion];
}

/*
 
 undo schedule for delete key
 
 */
- (void)undoScheduleDelete
{
	[self removeObjectForKey:MGSScriptKeyScheduleForDeletion];
}

#pragma mark -
#pragma mark Schedule Save
/*
 
 set schedule save
 
 */
- (void)setScheduleSave
{
	if (![self scheduleSave]) {
		
		// set flag
		[self setBool:YES forKey:MGSScriptKeyScheduleForSave];
	
		// update version ID.
		// this increases with every saved version
		[self updateVersionID];
	}
}
/*
 
 schedule save
 
 */
- (BOOL)scheduleSave
{
	return [self boolForKey:MGSScriptKeyScheduleForSave];
}

/*
 
 accept schedule save
 
 */
- (void)acceptScheduleSave
{
	// remove keys
	[self removeObjectForKey:MGSScriptKeyScheduleForSave];
}

#pragma mark -
#pragma mark Status 

// script status
- (MGSScriptStatus)scriptStatus
{
	return [self integerForKey:MGSScriptKeyStatus];
}
- (void)setScriptStatus:(MGSScriptStatus)value
{
	[self setInteger:value forKey:MGSScriptKeyStatus];
}

#pragma mark -
#pragma mark ScriptType

/*
 
 - scriptTypes
 
 */
- (NSArray *)scriptTypes
{
	return [[self class] validScriptTypes];
}

/*
 
 - scriptType
 
 */
- (NSString *)scriptType
{
	return [self objectForKey:MGSScriptKeyScriptType];
}
/*
 
 - setScriptType:
 
 */
- (void)setScriptType:(NSString *)aString
{
	NSAssert([[self class] validateScriptType:aString], @"invalid script type");
	
	[self setObject:aString forKey:MGSScriptKeyScriptType];

	[self retrieveLanguageProperties];
	[self syncScriptWithLanguageProperties];
}

#pragma mark -
#pragma mark User interaction mode

- (MGSScriptUserModeInteraction)userInteractionMode
{
	return [self integerForKey:MGSScriptKeyUserInteractionMode];
}
- (void)setUserInteractionMode:(MGSScriptUserModeInteraction)value
{
	[self setInteger:value forKey:MGSScriptKeyUserInteractionMode];
}

#pragma mark -
#pragma mark Labels and Ratings
/*
 
 set label index
 
 */
- (void)setLabelIndex:(NSInteger)idx
{
	[self setObject:[NSNumber numberWithInteger:idx] forKey:MGSScriptKeyLabelIndex];
}
/*
 
 label index
 
 */
- (NSInteger)labelIndex
{
	return [[self objectForKey:MGSScriptKeyLabelIndex] intValue];
}

/*
 
 set rating index
 
 */
- (void)setRatingIndex:(NSInteger)idx
{
	[self setObject:[NSNumber numberWithInteger:idx] forKey:MGSScriptKeyRatingIndex];
}
/*
 
 rating index
 
 */
- (NSInteger)ratingIndex
{
	return [[self objectForKey:MGSScriptKeyRatingIndex] intValue];
}

#pragma mark -
#pragma mark Script Code

/*
 
 - subroutine
 
 */
- (NSString *)subroutine
{
	return [self objectForLocalizedKey:MGSScriptKeySubroutine];
}

/*
 
 - setSubroutine:
 
 */
- (void)setSubroutine:(NSString *)aString
{
	[self setObject:aString forKey:MGSScriptKeySubroutine options:@{@"languagePropertyKey":MGS_LP_RunFunction}];
}

/*
 
 - runClass
 
 */
- (NSString *)runClass
{
	return [self objectForKey:MGSScriptKeyRunClass];
}

/*
 
 - setRunClass:
 
 */
- (void)setRunClass:(NSString *)aString
{
	[self setObject:aString forKey:MGSScriptKeyRunClass  options:@{@"languagePropertyKey":MGS_LP_RunClass}];
}

/*
 
 - onRun
 
 */
- (NSNumber *)onRun
{
	return [self objectForKey:MGSScriptKeyOnRun];
}

/*
 
 - setOnRun:
 
 */
- (void)setOnRun:(NSNumber *)runMode
{
	[self setObject:runMode forKey:MGSScriptKeyOnRun options:@{@"languagePropertyKey":MGS_LP_OnRunTask}];
    
    switch ([runMode integerValue]) {
        case kMGSOnRunCallNone:
        case kMGSOnRunCallScript:
            [self setSubroutine:nil];
            [self setRunClass:nil];
            break;
            
        case kMGSOnRunCallScriptFunction:
            [self setRunClass:nil];
            break;
            
        case kMGSOnRunCallClassFunction:
            break;
    }
}

/*
 
 remove the scriptcode
 
 when the script dict is downloaded to the client the scriptcode component is not sent.
 if the client wants the scriptcode it has to authenticate first
 
 */
- (void)removeScriptCode
{
	_scriptCode = nil;
	[[self dict] removeObjectForKey:MGSScriptKeyCode];
}


/*
 
 subroutine template 
 
 */
- (NSString *)subroutineTemplate
{
	return @"Sat 28 Aug 2010 16:55:52 IST";
}

/*
 
 sync with script
 
 update script script with objects from syncScript
 */
- (BOOL)syncWithScript:(MGSScript *)syncScript error:(MGSError **)mgsError
{
#pragma unused(mgsError)
	[self syncWithDict:[syncScript dict]];
	
	return YES;
}

/*
 
 - executableData
 
 */
- (NSData *)executableData
{
	NSData *data = nil;
	
	// script executable data may be compiled script data or
	// textual NSString data
	if (([[self languagePlugin] buildResultFlags] & kMGSCompiledScript) > 0) {
		data = [[self scriptCode] compiledData];
	} else {
		data = [[self scriptCode] sourceData];
	}	
	
	return data;
}

/*
 
 - onRunString
 
 */
- (NSString *)onRunString
{
    eMGSOnRunTask onRun = [self onRun].integerValue;
    NSString *onRunString = nil;
    switch (onRun) {
            
        case kMGSOnRunCallNone:
            onRunString = NSLocalizedString(@"No run behaviour defined" , @"On run task value");
            break;
            
        case kMGSOnRunCallScript:
            onRunString = NSLocalizedString(@"Call script" , @"On run task value");
            break;
            
        case kMGSOnRunCallScriptFunction:
            onRunString = [NSString stringWithFormat:NSLocalizedString(@"Call function %@" , @"On run task value"), [self subroutine]];
            break;
            
        case kMGSOnRunCallClassFunction:
            onRunString = [NSString stringWithFormat:NSLocalizedString(@"Call function %@ on class %@" , @"On run task value"), [self subroutine], [self runClass]];
            break;
    }
    
    return onRunString;

}

#pragma mark -
#pragma mark Templates

/*
 
 - templateManager
 
 */
- (MGSLanguageTemplateResourcesManager *)templateManager
{
	MGSLanguageTemplateResourcesManager* manager = [[[self languagePlugin] applicationResourcesManager] templateManager];
	
	return manager;
}
/*
 
 - templateNames
 
 */
- (NSArray *)templateNames
{
	return [[self templateManager] resourceNames];
}

/*
 
 - setTemplateName:
 
 */
- (void)setTemplateName:(NSString *)name
{
	templateName = name;
}

/*
 
 - templateName:
 
 */
- (NSString *)templateName
{
	if (!templateName) {
		templateName = [[self templateManager] defaultTemplateName];
	}
	
	return templateName;
}

#pragma mark -
#pragma mark Storage

//=======================================================
// save edited script
// return YES on success - reply sent
// return NO on failure - caller sends error reply
//
// the existing script dict will be moved.
// the new script dict will be written out.
// if the new script write fails then the old dict will be restored
//=======================================================
- (BOOL)saveToPath:(NSString *)path error:(MGSError **)mgsError
{
	NSString *error = nil;
	NSError *errorObj = nil;
	NSString *UUID = [self UUID];
	
	// script must have a UUID
	if (nil == UUID) {
		error = NSLocalizedString(@"Script UUID is nil", @"Script UUID is nil");
		goto errorExit;
	}
	
	// sanity check on the UUID string
	if (![UUID mgs_isUUID]) {
		error = NSLocalizedString(@"Script UUID is invalid", @"Script UUID is invalid");
		goto errorExit;
	}
	
	// script must have a valid script code section
	if (![self isValidForSave]) { 
		error = [NSString stringWithFormat:NSLocalizedString(@"Script code is invalid for UUID: %@", @"Script code is invalid"), UUID];
		goto errorExit;
	}

	// script must have a complete representation
	if ([self representation] != MGSScriptRepresentationComplete) { 
		error = [NSString stringWithFormat:NSLocalizedString(@"Script representation is invalid for UUID: %@", @"Script representation is invalid"), UUID];
		goto errorExit;
	}
    
	// save path
	NSString *savePath = [self UUIDWithPath:path];
	NSString *rollbackPath = [savePath stringByAppendingPathExtension:@"tmp"];
	
	// we do not wish to persist certain objects in our file based dictionary.
	// so we duplicate our script first
	MGSScript *saveScript = [self mutableDeepCopy];
	
	// conform to the save representation
	if (![saveScript conformToRepresentation:MGSScriptRepresentationSave]) {
		error = [NSString stringWithFormat:NSLocalizedString(@"Script save representation is invalid for UUID: %@", @"Script representation is invalid"), UUID];
		goto errorExit;
	}
	
	// remove the representation keys
	[saveScript removeObjectForKey:MGSScriptKeyRepresentation];	// recreated when script validated on load
	[[saveScript scriptCode] removeObjectForKey:MGSScriptKeyRepresentation];
	[[saveScript parameterHandler] removeRepresentation];
	
	// get property list representation
	NSData *xmlData = [saveScript propertyListData];
	if(!xmlData)
	{
		error = [NSString stringWithFormat:NSLocalizedString(@"Cannot serialize script for UUID", @"Error serializing script dict content"), UUID];

		goto errorExit;
	}
	
	// move existing script file to rollback path
	// if an error occurs writing the new file we can roll back
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	// delete any existing rollback file
	if ([fileManager fileExistsAtPath:rollbackPath]) {
		
		if (![fileManager removeItemAtPath:rollbackPath error:&errorObj]) {
			error = NSLocalizedString(@"Cannot delete rollback file", @"Error deleting rollback");
			MLog(DEBUGLOG, @"error deleting rollback file: %@", [errorObj localizedDescription]);
			goto errorExit;			
		}
	}
	
	// move existing file to roll back
	if ([fileManager fileExistsAtPath:savePath]) {

		if (![fileManager moveItemAtPath:savePath toPath:rollbackPath error:NULL]) {
			error = NSLocalizedString(@"Cannot create rollback file", @"Error creating rollback");
			goto errorExit;						
		}
	}
	
	// save the data
	if (![xmlData writeToFile:savePath options:NSAtomicWrite error:&errorObj]) {
		
		error = NSLocalizedString(@"Cannot write to file", @"Error writing file");
		MLog(DEBUGLOG, @"error writing script to file: %@", [errorObj localizedDescription]);
		
		// rollback
		NSString *errorAppend;
		if (![fileManager moveItemAtPath:rollbackPath toPath:savePath error:NULL]) {
			errorAppend = NSLocalizedString(@" - rollback to previous version succeeded", @"Rollback success");
		} else {
			errorAppend = NSLocalizedString(@" - rollback to previous version failed", @"Rollback fail");
		}
		
		error = [error stringByAppendingString:errorAppend];
		goto errorExit;
	}	
	
	// delete the rollback file 
	[fileManager removeItemAtPath:rollbackPath error:&errorObj];
	
	*mgsError = nil;
	return YES;
	
errorExit:;
	*mgsError = [MGSError frameworkCode:MGSErrorCodeSaveScript reason:error];
	return NO;	
}

/*
 
 - isValidForSave
 
 */
- (BOOL)isValidForSave
{
	NSData *executableData = [self executableData];
	NSString *source = [self.scriptCode source];
	
	if (executableData != nil && source != nil) {
		return YES;
	}
	
	if (!source) {
		MLog(RELEASELOG, @"Source is missing.");
	}
	
	if (!executableData) {
		MLog(RELEASELOG, @"Executable data is missing.");
	}
	
	return NO;
}

/*
 
 script default path
 
 */
- (NSString *)defaultPath
{
	return [self isBundled] ?  [MGSScriptManager applicationDocumentPath] : [MGSScriptManager userDocumentPath];
}


/*
 
 attachments
 
 */
- (MGSNetAttachments *)attachmentsWithError:(MGSError **)mgsError
{
	NSUInteger count = [_parameterManager count];
	
	if (count == 0) {
		return nil;
	}

	MGSNetAttachments *attachments = nil;
	NSString *error = nil;
	
	//
	// look for parameters to be sent as attachments
	//
	for (NSUInteger i = 0; i < count; i++) {
		
		MGSScriptParameter *parameter = [_parameterManager itemAtIndex:i];
		if ([parameter sendAsAttachment]) {
			
			// lazy
			if (!attachments) {
				attachments = [[MGSNetAttachments alloc] init];
			}
			
			// the parameter value must represent an existing file 
			// that can be read
			NSString *filePath = [parameter value];
			if (![filePath isKindOfClass:[NSString class]]) {
				error = NSLocalizedString(@"File parameter is wrong class.", @"Attachment file error presented to user");
				*mgsError = [MGSError clientCode:MGSErrorCodeAttachment reason:error];
				
				return nil;
			}
			
			// add attachment
			if (![attachments addAttachmentToExistingReadableFile:filePath]) {
				
				error = NSLocalizedString(@"File %@ does not exist or cannot be read.", @"Attachment file error presented to user");
				error = [NSString stringWithFormat:error, filePath];
				*mgsError = [MGSError clientCode:MGSErrorCodeAttachment reason:error];
				
				return nil;
			}
			
			// set attachment index for parameter.
			[parameter setAttachmentIndex: [attachments count]-1];
			
			// our value is the attachment name
			[parameter setValue:@"attachment"];
		}
	}
	
	return attachments;
}

/* 
 
 script name with parameter values
 
 */
- (NSString *)nameWithParameterValues 
{
	NSString *name = [self name];
	
	NSInteger count = [_parameterManager count];
	
	if (count == 0) {
		return name;
	}
	
	return [NSString stringWithFormat:@"%@ (%@)", name, [_parameterManager shortStringValue]];
}


#pragma mark -
#pragma mark Version
/*
 
 file version
 
 */
- (NSString *)FileVersion
{
	return [self objectForLocalizedKey:MGSScriptKeyFileVersion];
}

/*
 
 versionID
 
 */
- (NSInteger)versionID
{
	return [[self objectForKey:MGSScriptKeyScriptVersionID] intValue];
}

/*
 
 updateVersionID
 
 this never decreases
 
 */
- (void)updateVersionID
{
	NSInteger versionID = [self versionID];
	
	[self setObject:[NSNumber numberWithInteger:++versionID] forKey:MGSScriptKeyScriptVersionID];
}

/*
 
 major version
 
 */
- (void)setVersionMajor:(NSInteger)version
{
	[self setObject:[NSNumber numberWithInteger:version] forKey:MGSScriptKeyVersionMajor];
}
- (NSInteger)versionMajor
{
	return [[self objectForKey:MGSScriptKeyVersionMajor] intValue];
}

/*
 
 minor version
 
 */
- (void)setVersionMinor:(NSInteger)version
{
	[self setObject:[NSNumber numberWithInteger:version] forKey:MGSScriptKeyVersionMinor];
}
- (NSInteger)versionMinor
{
	return [[self objectForKey:MGSScriptKeyVersionMinor] intValue];
}

/*
 
 revision version
 
 */
- (void)setVersionRevision:(NSInteger)version
{
	[self setObject:[NSNumber numberWithInteger:version] forKey:MGSScriptKeyVersionRevision];
}
- (NSInteger)versionRevision
{
	return [[self objectForKey:MGSScriptKeyVersionRevision] intValue];
}

/*
 
 revision version auto increment
 
 */
- (void)setVersionRevisionAuto:(BOOL)value
{
	[self setBool:value forKey:MGSScriptKeyVersionRevisionAuto];
}
- (BOOL)versionRevisionAuto
{
	return [self boolForKey:MGSScriptKeyVersionRevisionAuto];
}

/*
 
 increment the version revision
 
 */
- (void)incrementVersionRevision
{
	NSInteger revision = [self versionRevision];
	if (revision < 99) {
		[self setVersionRevision: ++revision];
	}
}

#pragma mark -
#pragma mark Validation
/*
 
 - validateOSVersion
 
 */
- (BOOL)validateOSVersion
{
	return [[self languagePlugin] validateOSVersion];
}

@end

@implementation MGSScript(Private)


- (void)createParameterHandler
{
	// create parameter handler from script dict
	_parameterManager = [[MGSScriptParameterManager alloc] init];
	// this just points into the existing dict
	[_parameterManager setHandlerFromDict:[self dict]];
}

- (void)createCodeHandler
{
	// create code handler from script dict
	_scriptCode = [[MGSScriptCode alloc] init];
	
	// this just points into the existing dict
	[_scriptCode setDict:[self dict]];
	
	[_scriptCode setRepresentation:MGSScriptCodeRepresentationStandard];

}
@end
