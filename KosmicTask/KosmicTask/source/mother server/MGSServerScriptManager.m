//
//  MGSServerScriptManager.m
//  Mother
//
//  Created by Jonathan on 22/11/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSPath.h"
#import "MGSServerScriptManager.h"
#import "MGSScriptPlist.h"
#import "NSMutableDictionary_Mugginsoft.h"
#import "NSString_Mugginsoft.h"


NSString *MGSApplicationTaskPlist = @"ApplicationTasks.plist";
NSString *MGSKeyTasks = @"Tasks";
NSString *MGSKeyPublished = @"Published";

@interface MGSServerScriptManager (Private)
- (BOOL)loadScriptArrayAtPath:(NSString *)path withRepresentation:(MGSScriptRepresentation)representation bundled:(BOOL)bundled;
//- (NSMutableDictionary *)scriptDictionaryAtPath:(NSString *)path withRepresentation:(MGSScriptRepresentation)representation;
- (BOOL)loadApplicationScriptsWithRepresentation:(MGSScriptRepresentation)representation;
- (BOOL)loadUserScriptsWithRepresentation:(MGSScriptRepresentation)representation;
- (void)removeMatchingScriptsIn:(MGSScriptManager *)otherHandler;
- (BOOL)saveApplicationTaskDictionary:(NSString **)error;
- (NSString *)applicationTaskPath;
- (NSMutableDictionary *)applicationTaskDictionary;
- (NSMutableDictionary *)applicationTaskObjectForScript:(MGSScript *)script;
@end

@implementation MGSServerScriptManager

/*
 
 save script property published
 
 */
- (BOOL)saveScriptPropertyPublished:(MGSScript *)script error:(NSString **)error
{
	NSMutableDictionary	*dictItem = [self applicationTaskObjectForScript:script];
	
	// bundled scripts must have published property set regardless to ensure override
	// of bundle property list value
	if ([script isBundled] || [script published]) {
		[dictItem setObject:[NSNumber numberWithBool:[script published]] forKey:MGSKeyPublished];
	} else {
		[dictItem removeObjectForKey:MGSKeyPublished];
	}
	
	// save it
	return [self saveApplicationTaskDictionary:error];
}

/*
 
 load all application scripts with representation
 
 */
- (BOOL)loadScriptsWithRepresentation:(MGSScriptRepresentation)representation
{
	[self setArray:nil];
	
	// load user scripts
	if (![self loadUserScriptsWithRepresentation:representation]) {
		return NO;
	}
	
	// load bundle scripts manager
	MGSServerScriptManager *bundleScriptManager = [[MGSServerScriptManager alloc] init];
	if (![bundleScriptManager loadApplicationScriptsWithRepresentation:representation]) {
		return NO;
	}
	
	// sanity check.
	// script UUIDs should be unique. however, make sure that we have no duplicates
	// in the bundle
	[self removeMatchingScriptsIn:bundleScriptManager];
	
	// add bundle scripts
	[[self array] addObjectsFromArray:[bundleScriptManager array]];
	
	// set script properties defined in application task dictionary
	[self setApplicationTaskDictionaryProperties];
	
	return YES;
}

/*
 
 set script properties defined in application task dictionary
 
 */
- (void)setApplicationTaskDictionaryProperties
{
	//
	// load application task property list
	//
	NSDictionary *tasksDictionary = [[self applicationTaskDictionary] objectForKey:MGSKeyTasks];
	if (tasksDictionary) {
		
		for (int i = 0;i < [self count]; i++) {
			
			// if the script handler array does not contain mutable entries
			// then itemAtIndex may throw an exception !
			MGSScript *script = [self itemAtIndex:i];
			
			// look for matching UUID in tasks dict
			NSString *UUID = [script UUID];
			NSDictionary *bundleDict = [tasksDictionary objectForKey:UUID];
			if (bundleDict) {
				// set published state
				[script setPublished:[[bundleDict objectForKey:MGSKeyPublished] boolValue]];
			} 
		}
	}
}

/*
 
 script UUID is published
 
 this message consults the application task dictionary to determine if a
 script has been published
 
 the script handler could be queried but this is more definitive
 
 */
- (BOOL)scriptUUIDPublished:(NSString *)UUID
{
	BOOL published = NO;
	//
	// load application task property list
	//
	NSDictionary *tasksDictionary = [[self applicationTaskDictionary] objectForKey:MGSKeyTasks];
	if (tasksDictionary) {
		NSDictionary *bundleDict = [tasksDictionary objectForKey:UUID];
		if (bundleDict) {
			
			// set published state
			published = [[bundleDict objectForKey:MGSKeyPublished] boolValue];
		}
	}
	
	return published;
}
@end

@implementation MGSServerScriptManager (Private)


/*
 
 application task object for script
 
 */
- (NSMutableDictionary *)applicationTaskObjectForScript:(MGSScript *)script
{
	NSMutableDictionary *tasks = [[self applicationTaskDictionary] objectForKey:MGSKeyTasks];
	
	// get dict item for this script
	NSMutableDictionary	*dictItem = [tasks objectForKey:[script UUID]];
	if (!dictItem) {
		dictItem = [NSMutableDictionary dictionaryWithCapacity:1];
		[tasks setObject:dictItem forKey:[script UUID]];
	}
	
	return dictItem;
}

/*
 
 save application task dictionary
 
 */
- (BOOL)saveApplicationTaskDictionary:(NSString **)error
{
	NSMutableDictionary *taskDictionary = [self applicationTaskDictionary];
	
	// remove items with no entries from the tasks sub dict
	NSMutableDictionary *tasks = [taskDictionary objectForKey:MGSKeyTasks];
	for (NSString *key in [tasks allKeys]) {
		NSDictionary *item = [tasks objectForKey:key];
		if ([item count] == 0) {
			[tasks removeObjectForKey:key];
		}
	}
	
	// save it
	if (![taskDictionary writeToFile:[self applicationTaskPath] atomically:YES]) {
		*error = [NSString stringWithFormat: NSLocalizedString( @"Could not save application task list at path: %@", @"Application task plist write error"), [self applicationTaskPath]];
		return NO;
	}
	
	return YES;
}

/*
 
 application task dictionary
 
 */
- (NSMutableDictionary *)applicationTaskDictionary
{
	if (!_applicationTaskDictionary) {
		
		
		// regardless of where agent is in the app bundle our plist is in the bundle resources folder
		NSString *bundleTaskPath = [MGSPath bundleResourcePath];
		bundleTaskPath = [bundleTaskPath stringByAppendingPathComponent:MGSApplicationTaskPlist];
		
		// load bundle task dictionary
		NSMutableDictionary *taskDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:bundleTaskPath];
		if (!taskDictionary) {
			taskDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
		}
		
		// get application task dict from file or create if missing
		NSString *applicationTaskPath = [self applicationTaskPath];
		NSMutableDictionary *appTaskDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:applicationTaskPath];
		
		// coalesce the bundle and app task dictionaries.
		// the bundle provides the default properties (such as Published) for the bundled scripts.
		// if the user modifies the default property the new property value is written to the app task dictionary
		// which replaces the bundle property
		if (appTaskDictionary) {
			[taskDictionary addEntriesFromDictionary:appTaskDictionary];
		}
		
		_applicationTaskDictionary = taskDictionary;
	}
	
	// validate
	NSMutableDictionary *tasks = [_applicationTaskDictionary objectForKey:MGSKeyTasks];
	if (!tasks) {
		tasks = [NSMutableDictionary dictionaryWithCapacity:1];
		[_applicationTaskDictionary setObject:tasks forKey:MGSKeyTasks];
	}
	
	return _applicationTaskDictionary;
}

/*
 
 application task property list path
 
 */
- (NSString *)applicationTaskPath
{
	return [[MGSPath userApplicationSupportPath] stringByAppendingPathComponent:MGSApplicationTaskPlist];
}

//=========================================
//
// scan path to build script array
//
//=========================================
- (BOOL)loadScriptArrayAtPath:(NSString *)path withRepresentation:(MGSScriptRepresentation)representation bundled:(BOOL)bundled
{
	NSMutableArray *scriptArray = [NSMutableArray arrayWithCapacity:2];
	
	NSAssert(path, @"path is nil");
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	// enumerate path
	NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:path];
	if (!dirEnum) {
		MLog(DEBUGLOG, @"cannot enumerate path");	// when not run by parent the path points to the process executable
		return NO;
	}
	
	NSString *file;
	while ((file = [dirEnum nextObject])) {
		
		// want to copy files only
		if (![[[dirEnum fileAttributes] objectForKey:NSFileType] isEqualToString: NSFileTypeRegular]) {
			[dirEnum skipDescendents];	// don't enumerate directory any further
			continue;
		}
		
		// want to scan mother plists only 
		if (NSOrderedSame != [[file pathExtension] caseInsensitiveCompare:MGSScriptPlistExt]) {	
			continue;
		}
		
		// validate that filename is a valid UUID
		if (![[file stringByDeletingPathExtension] mgs_isUUID]) {
			MLog(RELEASELOG, @"Invalid UUID at path: %@", [path stringByAppendingPathComponent:file]);
			continue;
		}
		
		// attempt to load the script from the  file
		NSString *filePath = [path stringByAppendingPathComponent:file];
		MGSError *mgsError = nil;
		MGSScript *script = [MGSScript scriptWithContentsOfFile:filePath error:&mgsError];
		if (!script) {
			continue;
		}
		
		// set bundled state
		[script setBundled:bundled];

		// if dict is to be published then minimise the contents
		switch (representation) {
				
				// script representation is complete after load
			case MGSScriptRepresentationComplete:
				break;
				
				// form a display representation
			case MGSScriptRepresentationDisplay:
			case MGSScriptRepresentationPreview:
				if (![script conformToRepresentation:representation]) {
					MLog(RELEASELOG, @"script failed to conform to required representation");
					continue;
				}
				
				break;
				
			case MGSScriptRepresentationUndefined:
			default:
				MLog(RELEASELOG, @"invalid script representation requested at path: %@", [path stringByAppendingPathComponent:file]);
				continue;
		}
		
		// add script dict to array
		[scriptArray addObject:[script dict]];
	}
	
	[self setArray:scriptArray];
	
	return YES;
}

//=========================================
//
// scan path to build script dictionary
//
//=========================================
/*
- (NSMutableDictionary *)scriptDictionaryAtPath:(NSString *)path forDisplay:(BOOL)display
{
	NSMutableDictionary *scriptDict = [NSMutableDictionary dictionaryWithCapacity:2];
	NSMutableArray *scriptArray = [NSMutableArray arrayWithCapacity:2];
	[scriptDict setObject:scriptArray forKey:MGSScriptKeyScripts];
	
	NSAssert(path, @"path is nil");
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	// enumerate path
	NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:path];
	if (!dirEnum) {
		MLog(DEBUGLOG, @"cannot enumerate bundle plists path");	// when not run by parent the path points to the process executable
		return nil;
	}
	
	NSString *file;
	while (file = [dirEnum nextObject]) {
		
		// want to copy files only
		if (![[[dirEnum fileAttributes] objectForKey:NSFileType] isEqualToString: NSFileTypeRegular]) {
			[dirEnum skipDescendents];	// don't enumerate directory any further
			continue;
		}
		
		// want to scan mother plists only (there shouldn't be anything else in there though)
		if (NSOrderedSame != [[file pathExtension] caseInsensitiveCompare:MGSScriptPlistExt]) {	
			continue;
		}
		*/
		// file must also include the bundle id ext
		/*
		 NSRange range = [file rangeOfString:MGSScriptPlistBundleIDExt options:NSCaseInsensitiveSearch];
		 if (NSNotFound == range.location) {
		 continue;
		 }
		 */
	/*	
		MGSError *mgsError = nil;
		// attempt to load the script from the  file
		NSString *filePath = [path stringByAppendingPathComponent:file];
		MGSScript *script = [MGSScript scriptWithContentsOfFile:filePath error:&mgsError];
		if (!script) {
			continue;
		}
		
		// if dict is to be published then minimise the contents
		if (publish) {
			[script removeScriptCode];
		}
		
		// add script dict to array
		[scriptArray addObject:[script dict]];
	}
	
	return scriptDict;
}
*/
/*
 
 load application scripts with representation
 
 */
- (BOOL)loadApplicationScriptsWithRepresentation:(MGSScriptRepresentation)representation
{
	// load the application script array from file
	if (![self loadScriptArrayAtPath:[MGSScriptManager applicationDocumentPath] withRepresentation:representation bundled:YES]) {
		MLog(DEBUGLOG, @"could not load bundle scripts");
		return NO;
	}
	
	return YES;
}
/*
 
 load user scripts with representation
 
 */
- (BOOL)loadUserScriptsWithRepresentation:(MGSScriptRepresentation)representation
{
	// load the user script array from file
	if (![self loadScriptArrayAtPath:[MGSScriptManager userDocumentPath] withRepresentation:representation bundled:NO]) {
		MLog(DEBUGLOG, @"could not load user scripts");
		return NO;
	}
	
	return YES;
}


/*
 
 remove any scripts from the receiver that occur in otherHandler
 
 */
- (void)removeMatchingScriptsIn:(MGSScriptManager *)otherHandler
{
	NSDictionary *receiverDict = [self scriptDictionaryWithUUIDKeys];
	NSDictionary *otherDict = [otherHandler scriptDictionaryWithUUIDKeys];
	for (id key in [otherDict allKeys]) {
		MGSScript *script = [receiverDict objectForKey:key];
		if (script) {
			[self removeScript:script];
			MLog(RELEASELOG, @"Duplicate script UUID found: %@", key);
		}
	}
}

@end
