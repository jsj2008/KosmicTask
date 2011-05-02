//
//  MGSClientScriptManager.h
//  Mother
//
//  Created by Jonathan on 30/12/2007.
//  Copyright 2007 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MGSScriptManager;
@class MGSScript;
@class MGSScriptGroup;

@interface MGSClientScriptManager : NSObject {
	MGSScriptManager *_scriptManager;				// all scripts
	MGSScriptManager *_activeGroupScriptManager;	// active group script manager
	NSMutableArray *_groupScriptManagerArray;		// array of script managers, one for each group
	
	NSMutableArray *_groupNames;
	
}
+ (NSString *)groupNameAll;
- (MGSScriptManager *)groupWithName:(NSString *)name;
- (MGSScriptGroup *)bundleScriptGroup;
- (MGSScriptGroup *)userScriptGroup;
- (bool)hasScripts;
- (void)setDictionary:(NSMutableDictionary *)aDict;
- (NSInteger)groupScriptCount;
- (MGSScript *)groupScriptAtIndex:(NSInteger)index;
- (NSString *)groupScriptNameAtIndex:(NSInteger)index;
- (NSString *)groupDisplayNameAtIndex:(NSInteger)index;
- (NSString *)groupScriptDescriptionAtIndex:(NSInteger)index;
- (BOOL)groupScriptBundledAtIndex:(NSInteger)index;
- (NSInteger)groupCount;
- (NSString *)groupNameAtIndex:(NSInteger)index;
- (NSString *)groupNameAll;
- (void)setActiveGroupIndex:(NSInteger)index;
- (BOOL)groupScriptPublishedAtIndex:(NSInteger)index;
- (NSInteger)scriptCount;
- (NSInteger)publishedScriptCount;
- (NSInteger)groupPublishedScriptCount;
- (MGSScriptManager *)groupAtIndex:(int)index;
- (MGSClientScriptManager *)mutableDeepCopy;
- (NSMutableDictionary *)mutableDeepCopyOfDictionary;
- (MGSScriptManager *)activeGroup;
- (void)sortUsingDescriptors:(NSArray *)descriptors;
- (NSUInteger)indexOfGroup:(MGSScriptManager *)group;
- (NSUInteger)indexOfGroupWithName:(NSString *)groupName;
- (void)scheduleDeleteScript:(MGSScript *)script;
- (void)updateScript:(MGSScript *)updatedScript;
- (NSInteger)scriptIndexForUUID:(NSString *)UUID;
- (NSMutableDictionary *)editDictionaryCopy;
- (NSString *)groupScriptUUIDAtIndex:(NSInteger)index;
- (NSMutableDictionary *)changeDictionaryCopy;
- (NSMutableArray *)changeArrayCopy;
- (id)groupDisplayObjectAtIndex:(NSInteger)index;
- (void)setImageResourceForGroup:(MGSScriptManager *)scriptHandler name:(NSString *)name location:(NSString *)location;
- (void)imageResourceForGroup:(MGSScriptManager *)scriptHandler name:(NSString **)name location:(NSString **)location;
- (id)groupScriptNameLabelAtIndex:(NSInteger)index;
- (id)groupScriptDescriptionLabelAtIndex:(NSInteger)index;
- (NSInteger)groupScriptRatingAtIndex:(NSInteger)index;
- (id)groupScriptRatingLabelAtIndex:(NSInteger)index;
- (NSMutableDictionary *)localTaskDictionary;
- (void)updateScriptsFromLocalTaskDictionary:(NSMutableDictionary *)localTaskDictionary;
- (MGSScript *)scriptForUUID:(NSString *)UUID;
- (MGSClientScriptManager *)publishedScriptManager;
- (NSMutableDictionary *)editDictionaryForScript:(MGSScript *)script;
- (NSArray *)changeArrayScheduleForDelete;
- (id)groupScriptGroupAtIndex:(NSInteger)idx;
- (NSString *)groupScriptTypeAtIndex:(NSInteger)idx;

// schedule save
- (void)acceptScheduleSave;

// schedule delete
- (void)undoScheduleForDelete;
- (void)acceptScheduleDelete;

// schedule changes for property: published
- (void)acceptSchedulePublished;
- (void)undoSchedulePublished;

// configuration changes
- (void)undoConfigurationChanges;
- (void)acceptConfigurationChanges;

@property (readonly, copy) NSArray *groupNames;

@end
