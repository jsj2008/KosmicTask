//
//  MGSClientScriptManager.m
//  Mother
//
//  Created by Jonathan on 30/12/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//
#import "MGSMother.h"
#import "MGSScriptPlist.h"
#import "MGSClientScriptManager.h"
#import "MGSScriptManager.h"
#import "MGSScript.h"
#import "MGSImageAndText.h"
#import "MGSImageAndTextCell.h"
#import "MGSLabelTextCell.h"
#import "MGSLabelLevelIndicatorCell.h"
#import "MGSPath.h"
#import "MGSScriptGroup.h"

static MGSScriptGroup *_bundleScriptGroup = nil;
static MGSScriptGroup *_userScriptGroup = nil;
static BOOL _userScriptGroupSaved = NO;

@interface MGSClientScriptManager(Private)
- (void)buildGroupArray;
- (NSImage *)imageForGroup:(MGSScriptManager *)scriptManager;
- (NSString *)userGroupPath;
@end

@implementation MGSClientScriptManager

@synthesize groupNames = _groupNames;

/*
 
 group name all
 
 */
+ (NSString *)groupNameAll
{
	return NSLocalizedString(@"All", @"All group names in group tableview");
}

#pragma mark Instance Methods

/*
 
 init
 
 */
- (MGSClientScriptManager *)init
{
	if ([super init]) {
		_scriptManager = [[MGSScriptManager alloc] init];		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
	}
	return self;		 
}
/*
 
 bundle script group
 
 */
- (MGSScriptGroup *)bundleScriptGroup
{
	// lazy
	if (!_bundleScriptGroup) {
		// load task groups dict from bundle
		NSString *bundleTaskGroupsPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TaskGroups.plist"];
		_bundleScriptGroup = [[MGSScriptGroup alloc] initWithContentsOfFile:bundleTaskGroupsPath];		
	}
	return _bundleScriptGroup;
}
/*
 
 user script group
 
 */
- (MGSScriptGroup *)userScriptGroup
{
	// lazy
	if (!_userScriptGroup) {
		// load use task groups dictionary
		_userScriptGroup = [[MGSScriptGroup alloc] initWithContentsOfFile:[self userGroupPath]];
	}
	return _userScriptGroup;
}


/*
 
 hasScripts
 
 returns YES if scripts present
 
 */
- (bool)hasScripts
{
	return [_scriptManager hasScripts];
}

/*
 
 set dictionary containing scripts
 
 */
- (void)setDictionary:(NSMutableDictionary *)aDict
{
	[_scriptManager setDictionary:aDict]; 
	//[_scriptManager setScriptStatus:MGSScriptStatusExistsOnServer];
	
	if ([_scriptManager count] == 0) {
		_groupScriptManagerArray= [[NSMutableArray alloc] init];
		//_groupSet= [[NSMutableSet alloc] init];
		//[self setActiveGroupIndex:0];
		return;
	}
	
	[self buildGroupArray];
}


/*
 
 make a deep copy of this object
 
 */
-(MGSClientScriptManager *)mutableDeepCopy
{
	id aCopy = [[[self class] alloc] init];
	[aCopy setDictionary:[_scriptManager mutableDeepCopyOfDictionary]];
	return aCopy;
}



/*
 
 active group script handler
 
 */
- (MGSScriptManager *)activeGroup
{
	return _activeGroupScriptManager;
}

/*
 script count

*/
- (NSInteger)scriptCount
{
	NSInteger count;
	
	// [_scriptManager count] will include invalid group items (those scheduled for deletion)
	// the all group at index 0 will be filtered
	if ([_groupScriptManagerArray count] > 0) {
		count = [[_groupScriptManagerArray objectAtIndex:0] count];
	} else {
		count = 0;
	}
	return count;
}

/*
 
 published script count
 
 */
- (NSInteger)publishedScriptCount
{
	NSInteger count = [_scriptManager publishedCount];
	return count;
}
/*
 
 get script index matching UUID
 
 */
- (NSInteger)scriptIndexForUUID:(NSString *)UUID
{
	if (nil == UUID) return -1;
	
	for (int i = 0; i < [_scriptManager count]; i++) {
		MGSScript * script = [_scriptManager itemAtIndex:i];
		if ([[script UUID] isEqualToString:UUID]) {
			return i;
		}
	}
	
	return -1;
}

/*
 
 get script for UUID
 
 */
- (MGSScript *)scriptForUUID:(NSString *)UUID
{
	int i = [self scriptIndexForUUID:UUID];
	if (i == -1) return nil;
	
	MGSScript *script = [_scriptManager itemAtIndex:i];
	
	return script;
}

/*
 
 set active group index
 
 */
- (void)setActiveGroupIndex:(NSInteger)idx
{
	_activeGroupScriptManager = [_groupScriptManagerArray objectAtIndex:idx];
}


/*
 
 get index of group
 
 */
- (NSUInteger)indexOfGroup:(MGSScriptManager *)group
{
	return [_groupScriptManagerArray indexOfObjectIdenticalTo:group];
}

/*
 
 get index of group with name
 
 */
- (NSUInteger)indexOfGroupWithName:(NSString *)groupName
{
	NSUInteger idx = 0;
	for (MGSScriptManager *scriptManager in _groupScriptManagerArray) {
		if ([scriptManager.name isEqualToString:groupName]) {
			return idx;
		}
		idx++;
	}
	
	return NSNotFound;
}


/*
 
 published script handler
 
 */
- (MGSClientScriptManager *)publishedScriptManager
{
	// allocate a new client script handler
	MGSClientScriptManager *clientScriptManager = [[[self class] alloc] init];

	// get script handler for published scripts
	MGSScriptManager *scriptManager = [_scriptManager publishedScriptManager];

	[clientScriptManager setDictionary:[scriptManager dictionary]];
	
	return clientScriptManager;
	
}

#pragma mark Collections

/*
 
 deep copy of dictionary
 
 */
- (NSMutableDictionary *)mutableDeepCopyOfDictionary
{
	return [_scriptManager mutableDeepCopyOfDictionary];
}

/*
 
 edit dictionary copy
 
 */
- (NSMutableDictionary *)editDictionaryCopy
{
	return [_scriptManager editDictionaryCopy];
}	
/*
 
 edit dictionary for script
 
 */
- (NSMutableDictionary *)editDictionaryForScript:(MGSScript *)script
{
	return [_scriptManager editDictionaryForScript:script];
}
/*
 
 change dictionary copy
 
 */
- (NSMutableDictionary *)changeDictionaryCopy
{
	return [_scriptManager changeDictionaryCopy];
}
/*
 
 change dictionary copy
 
 */
- (NSMutableArray *)changeArrayCopy
{
	return [_scriptManager changeArrayCopy];
}
/*
 
 change dictionary 
 
 */
- (NSArray *)changeArrayScheduleForDelete
{
	return [_scriptManager changeArrayScheduleForDelete];
}

#pragma mark Configuration Changes
/*
 
 undo configuration changes
 
 */
- (void)undoConfigurationChanges
{
	[self undoScheduleForDelete];
	[self undoSchedulePublished];
}
/*
 
 accept configuration changes
 
 */
- (void)acceptConfigurationChanges
{
	// remove scripts scheduled for deletion
	[self acceptScheduleDelete];	
	
	// accept schedule published
	[self acceptSchedulePublished];	
}

#pragma mark Image Resource

/*
 
 set image resource for group
 
 */
- (void)setImageResourceForGroup:(MGSScriptManager *)scriptManager name:(NSString *)name location:(NSString *)location
{
	if (scriptManager.hasAllScripts) {
		[[self userScriptGroup] setImageResourceForAllGroup:name location:location];
	} else {
		[[self userScriptGroup] setImageResourceForGroupName:scriptManager.name imageName:name location:location];
	}
	[scriptManager setDisplayImage:[self imageForGroup:scriptManager]];
}

/*
 
 image resource for group
 
 */
- (void)imageResourceForGroup:(MGSScriptManager *)scriptManager name:(NSString **)name location:(NSString **)location
{
	if (scriptManager.hasAllScripts) {
		[[self userScriptGroup] imageResourceForAllGroup:name location:location];
		if (!*name || !*location) {
			[[self bundleScriptGroup] imageResourceForAllGroup:name location:location];
		}
	} else {
		[[self userScriptGroup] imageResourceForGroupName:scriptManager.name imageName:name location:location];
		if (!*name || !*location) {
			[[self bundleScriptGroup] imageResourceForGroupName:scriptManager.name imageName:name location:location];
		}
	}
	
	if (!*name || !*location) {
		[[self bundleScriptGroup] imageResourceForGroup:name location:location];
	}	
}


#pragma mark Modification
/*
 
 schedule the script for deletion
 
 */
- (void)scheduleDeleteScript:(MGSScript *)script
{
	[script setScheduleDelete];
	[self buildGroupArray];
}

/*
 
 replace item with UUID of updatedScript
 with updatedScript
 
 */
- (void)updateScript:(MGSScript *)updatedScript
{
	/*
	 updates can be attempted in two ways:
	 
	 1. we replace the original object with the update.
	 2. we keep the existing script object and update its internal dictionary.
	 
	 also note that this updating methodolgy makes binding to the script properties
	 infeasible as after a script is edited the object (or at least its dict) is replaced
	 rather than properties being indivdually updated via KVC compliant methods.
	 
	 */
#ifdef MGSReplaceScriptWithUpdate
	
	NSInteger idx  = [self scriptIndexForUUID:[updatedScript UUID]];
	if (idx != -1) {
		[_scriptManager removeItemAtIndex:idx];
	} 
	
	// add copy of the updated script
	[_scriptManager addItem:[updatedScript mutableDeepCopy]];
	
#else
	MGSScript *script = [self scriptForUUID:[updatedScript UUID]];
	if (script) {
		[script updateFromCopy:updatedScript];
	} else {
		
		// add new copy of script
		[_scriptManager addItem:[updatedScript mutableDeepCopy]];
	}
	
#endif
	
	// rebuild group array as script
	// group properties may well have changed
	[self buildGroupArray];
}

/*
 
 sort using descriptors
 
 */
- (void)sortUsingDescriptors:(NSArray *)descriptors
{
	id firstItem = nil;
	
	// we always want the first item, representing All Groups,
	// to remain at the top of the array, whatever the sorting
	if ([_groupScriptManagerArray count] > 0) {
		firstItem = [_groupScriptManagerArray objectAtIndex:0];
		[_groupScriptManagerArray removeObjectAtIndex:0];
	}
	[_groupScriptManagerArray sortUsingDescriptors:descriptors];
	if (firstItem) {
		[_groupScriptManagerArray insertObject:firstItem atIndex:0];
	}
	
}

#pragma mark Notifications

/*
 
 application will terminate
 
 */
- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	#pragma unused(aNotification)
	
	// save the user script group
	// this is only saved once so it will apply to all servers
	if (!_userScriptGroupSaved) {
		[_userScriptGroup saveToPath:[self userGroupPath]];
		_userScriptGroupSaved = YES;
	}
}

#pragma mark Local Task Configuration

/*
 
 update scripts from local task dictionary
 
 */
- (void)updateScriptsFromLocalTaskDictionary:(NSMutableDictionary *)localTaskDictionary
{
	for (int i = 0; i < [_scriptManager count]; i++) {
		MGSScript *script = [_scriptManager itemAtIndex:i];
		NSMutableDictionary *dict = [localTaskDictionary objectForKey:[script UUID]];
		if (dict) {
			[script updateFromTaskDictionary:dict];
		}
	}	
}
/*
 
 local task dictionary
 
 */
- (NSMutableDictionary *)localTaskDictionary
{
	
	// dictionary of properties not persisted on the server but locally.
	// eg: labelIndex
	// perhaps there should be a clientScript subclass ?
	NSMutableDictionary *taskDict = [NSMutableDictionary dictionaryWithCapacity:2];	
	for (int i = 0; i < [_scriptManager count]; i++) {
		MGSScript *script = [_scriptManager itemAtIndex:i];
		NSMutableDictionary *dict = [script localTaskDictionary];
		if ([dict count] > 0) {
			[taskDict setObject:dict forKey:[script UUID]];
		}
	}
	
	return taskDict;
}

#pragma mark Schedule Published 
/*
 
 accept schedule for publish
 
 */
- (void)acceptSchedulePublished
{
	[_scriptManager acceptSchedulePublished];
}

/*
 
 undo schedule published
 
 */
- (void)undoSchedulePublished
{
	[_scriptManager undoSchedulePublished];
}

#pragma mark Schedule Delete 
/*
 
 undo schedule for delete
 
 */
- (void)undoScheduleForDelete
{
	[_scriptManager undoScheduleDelete];
	
	// tasks scheduled for delete are excluded from the group array so rebuild
	[self buildGroupArray];
}
/*
 
 accept schedule delete
 
 */
- (void)acceptScheduleDelete
{
	[_scriptManager acceptScheduleDelete];
	
	// tasks scheduled for delete are excluded from the group array so rebuild is NOT reqd
	//[self buildGroupArray];
}

#pragma mark Schedule Save 
/*
 
 clear schedule for save
 
 */
- (void)acceptScheduleSave
{
	[_scriptManager acceptScheduleSave];
}

#pragma mark Group 
/*
 
 group script handler at index 
 
 */
- (MGSScriptManager *)groupAtIndex:(int)idx
{
	if (idx >= 0 && idx < (NSInteger)[_groupScriptManagerArray count]) {
		return [_groupScriptManagerArray objectAtIndex:idx];
	}
	return nil;
}

/*
 
 group with name
 
 */
- (MGSScriptManager *)groupWithName:(NSString *)name
{
	NSInteger idx = [self indexOfGroupWithName:name];
	if (idx == NSNotFound) {
		return nil;
	}
	
	return [self groupAtIndex:idx];
}


/*
 
 active group script count
 
 */
- (NSInteger)groupScriptCount
{
	NSInteger count = [_activeGroupScriptManager count];
	return count;
}
/*
 
 group published script count
 
 */
- (NSInteger)groupPublishedScriptCount
{
	NSInteger count = [_activeGroupScriptManager publishedCount];
	return count;
}


/*
 
 group script at index
 
 */
- (MGSScript *)groupScriptAtIndex:(NSInteger)idx
{
	if (idx >= 0 && idx < [_activeGroupScriptManager count]) {
		return [_activeGroupScriptManager itemAtIndex:idx];
	}
	return nil;
}

/*
 
 group script name at index
 
 */
- (NSString *)groupScriptNameAtIndex:(NSInteger)idx
{
	MGSScript *script = [self groupScriptAtIndex:idx];
	return [script name];
}

/*
 
 group script type at index
 
 */
- (NSString *)groupScriptTypeAtIndex:(NSInteger)idx
{
	MGSScript *script = [self groupScriptAtIndex:idx];
	return [script scriptType];
}

/*
 
 group script name label at index
 
 may return a dictionary or a string
 
 */
- (id)groupScriptNameLabelAtIndex:(NSInteger)idx
{
	MGSScript *script = [self groupScriptAtIndex:idx];
	
	// if no label index then just return name
	if (script.labelIndex == 0) {
		return [script name];
	} 
	
	return [NSDictionary dictionaryWithObjectsAndKeys:[script name], MGSLabelTextCellStringKey, [NSNumber numberWithInteger:script.labelIndex], MGSLabelTextCellLabelIndexKey, nil];
}
/*
 
 group script description label at index
 
 may return a dictionary or a string
 
 */
- (id)groupScriptDescriptionLabelAtIndex:(NSInteger)idx
{
	MGSScript *script = [self groupScriptAtIndex:idx];
	
	// if no label index then just return description
	if (script.labelIndex == 0) {
		return [script description];
	} 
	
	return [NSDictionary dictionaryWithObjectsAndKeys:[script description], MGSLabelTextCellStringKey, [NSNumber numberWithInteger:script.labelIndex], MGSLabelTextCellLabelIndexKey, nil];
}
/*
 
 group script group at index
 
 may return a dictionary or a string
 
 */
- (id)groupScriptGroupAtIndex:(NSInteger)idx
{
	MGSScript *script = [self groupScriptAtIndex:idx];
	
	// if no label index then just return group name
	//if (script.labelIndex == 0) {
		return [script group];
	//} 
	
	//return [NSDictionary dictionaryWithObjectsAndKeys:[script description], MGSLabelTextCellStringKey, [NSNumber numberWithInteger:script.labelIndex], MGSLabelTextCellLabelIndexKey, nil];
}
/*
 
 group script rating label at index
 
 may return a dictionary or a string
 
 */
- (id)groupScriptRatingLabelAtIndex:(NSInteger)idx
{
	MGSScript *script = [self groupScriptAtIndex:idx];
	
	// if no label index then just return rating
	if (script.labelIndex == 0) {
		return [NSNumber numberWithInteger:[script ratingIndex]];
	} 
	
	return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:[script ratingIndex]], MGSLabelLevelIndicatorCellRatingKey, [NSNumber numberWithInteger:script.labelIndex], MGSLabelLevelIndicatorCellLabelIndexKey, nil];
}
/* 
 
 group script description at index
 
 */
- (NSString *)groupScriptDescriptionAtIndex:(NSInteger)idx
{	
	return [[self groupScriptAtIndex:idx] description];
}

/* 
 
 group script UUID at index
 
 */
- (NSString *)groupScriptUUIDAtIndex:(NSInteger)idx
{	
	return [[self groupScriptAtIndex:idx] UUID];
}


/* 
 
 group script rating at index
 
 */
- (NSInteger)groupScriptRatingAtIndex:(NSInteger)idx
{	
	return [[self groupScriptAtIndex:idx] ratingIndex];
}
/* 
 
 group script published at index
 
 */
- (BOOL)groupScriptPublishedAtIndex:(NSInteger)idx
{	
	return [[self groupScriptAtIndex:idx] published];
}

/* 
 
 group script bundled at index
 
 */
- (BOOL)groupScriptBundledAtIndex:(NSInteger)idx
{	
	return [[self groupScriptAtIndex:idx] isBundled];
}

/*
 
 group count
 
 */
- (NSInteger)groupCount
{
	return [_groupScriptManagerArray count];
}

/*
 
 group name at index
 
 */
- (NSString *)groupNameAtIndex:(NSInteger)idx
{
	if (idx < 0 || idx >= (NSInteger)[_groupScriptManagerArray count]) {
		MLog(DEBUGLOG, @"invalid group index %n", idx);
		return nil;
	}
	return [[_groupScriptManagerArray objectAtIndex:idx] name];
}

/*
 
 group display name at index
 
 */
- (NSString *)groupDisplayNameAtIndex:(NSInteger)idx
{
	if (idx < 0 || idx >= (NSInteger)[_groupScriptManagerArray count]) {
		MLog(DEBUGLOG, @"invalid group index %n", idx);
		return nil;
	}
	return [[self groupAtIndex:idx] displayName];
}
/*
 
 group display object at index
 
 */
- (id)groupDisplayObjectAtIndex:(NSInteger)idx
{
	
	if (idx < 0 || idx >= (NSInteger)[_groupScriptManagerArray count]) {
		MLog(DEBUGLOG, @"invalid group index %n", idx);
		return nil;
	}
	return [[self groupAtIndex:idx] displayObject];
}
/*
 
 group name all
 
 */
- (NSString *)groupNameAll
{
	return [[self class] groupNameAll];
}


@end

@implementation MGSClientScriptManager(Private)


/*
 
- buildGroupArray
 
 */
- (void)buildGroupArray
{
	// try and maintain current group selection after build
	NSString *activeGroupName = nil;
	if (_activeGroupScriptManager) {
		activeGroupName = [_activeGroupScriptManager name];
	}

	// array to hold script manager for each group
	_groupScriptManagerArray = [NSMutableArray arrayWithCapacity:2];

	// form script group All.
	// form a group script handler to represent the automatic All group.
	// by default this group contains all the scripts
	MGSScriptManager *allScriptManager = [[MGSScriptManager alloc] initForScriptObjects];
	allScriptManager.name = [self groupNameAll];	
	allScriptManager.hasAllScripts = YES;
	[allScriptManager setDisplayImage:[self imageForGroup:allScriptManager]];

	NSMutableDictionary *groupDict = [NSMutableDictionary dictionaryWithCapacity:100];

	// iterate through all scripts and build managers
	for (int i = 0; i < [_scriptManager count]; i++) {
		
		// get the script
		MGSScript *script = [_scriptManager itemAtIndex:i];
		
		// validate if script is a valid group member
		if (![script isValidGroupMember]) {
			continue;
		}
		
		// get name and add to group set
		NSString *groupName = [script group];
		if (!groupName) {
			groupName = @"?";
		}
		
		MGSScriptManager *groupScriptManager = [groupDict objectForKey:groupName];
		if (!groupScriptManager) {
			
			// note that this instance of MGSscriptManager contains actual script objects
			// not raw script dictionaries
			groupScriptManager = [[MGSScriptManager alloc] initForScriptObjects];
			groupScriptManager.name = groupName;
			groupScriptManager.hasAllScripts = NO;
			[groupScriptManager setDisplayImage:[self imageForGroup:groupScriptManager]];
			
			// add to group dictionary
			[groupDict setObject:groupScriptManager forKey:groupName];
			
			// add to array
			[_groupScriptManagerArray addObject:groupScriptManager];
		}
		[groupScriptManager addItem:script];
		[allScriptManager addItem:script];
	}

	// sort the group script manager array
	NSSortDescriptor *desc = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
	//[_groupScriptManagerArray sortUsingDescriptors:[NSArray arrayWithObject:desc]];
	[allScriptManager sortUsingDescriptors:[NSArray arrayWithObject:desc]];
	[_groupScriptManagerArray makeObjectsPerformSelector:@selector(sortUsingDescriptors:) withObject:[NSArray arrayWithObject:desc]];
	 
	// sorted array of group names
	_groupNames = [NSMutableArray arrayWithArray:[_groupScriptManagerArray valueForKey:@"name"]];
	[_groupNames sortUsingSelector:@selector(caseInsensitiveCompare:)];
	[_groupNames insertObject:allScriptManager.name atIndex:0];

	// _groupscriptManagerArray is sorted by group name
	// ensure first script group is the all group
	[_groupScriptManagerArray insertObject:allScriptManager atIndex:0];

	allScriptManager.groupCount = [self groupCount] - 1;

	// find index of previous active group name.
	// it may no longer exist.
	NSUInteger idx = NSNotFound;
	if (activeGroupName) {
		idx = [self indexOfGroupWithName:activeGroupName];
	}
	
	if (idx == NSNotFound) {
		idx = 0;
	}
	
	// select group
	[self setActiveGroupIndex:idx];
}

/*
 
 image for group
 
 */
- (NSImage *)imageForGroup:(MGSScriptManager *)scriptManager
{
	NSImage *image = nil;
	
	// use user defined image for group if available.
	// otherwise use bundle image.
	// other use default.
	if (scriptManager.hasAllScripts) {
		image = [[self userScriptGroup] imageForAllGroup];
		if (!image) {
			image = [[self bundleScriptGroup] imageForAllGroup];
		}
	} else {
		image = [[self userScriptGroup] imageForGroupName:scriptManager.name];
		if (!image) {
			image = [[self bundleScriptGroup] imageForGroupName:scriptManager.name];
		}
	}
	
	// use default images if reqd
	if (!image) {
		if (scriptManager.hasAllScripts) {
			image = [[self bundleScriptGroup] defaultImageForAllGroup];
		} else {
			image = [[self bundleScriptGroup] defaultImageForGroup];
		}
	}
	
	
	[image setScalesWhenResized:YES];
	[image setSize:NSMakeSize(16, 16)];
	
	return image;
}
/*
 
 user group plist path
 
 */
- (NSString *)userGroupPath
{
	return [[MGSPath userApplicationSupportPath] stringByAppendingPathComponent:@"TaskGroups.plist"];
}
@end


