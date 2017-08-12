//
//  MGSScriptManager.h
//  Mother
//
//  Created by Jonathan on 08/01/2008.
//  Copyright 2008 Mugginsoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSFactoryArrayController.h"
#import "MGSScript.h"


@class MGSScript;
@class MGSImageAndText;

@interface MGSScriptManager : MGSFactoryArrayController {
	NSString *_name;	// handler name
	BOOL _hasScripts;
	BOOL _hasAllScripts;
	NSInteger _groupCount;
	MGSImageAndText *_imageAndText;
}

@property (copy, nonatomic) NSString *name;
@property BOOL hasScripts;
@property (nonatomic) BOOL hasAllScripts;
@property NSInteger groupCount;

+ (NSString *)userDocumentPath;
+ (NSString *)bundleDocumentPath;
+ (NSString *)applicationDocumentPath;

- (NSString *)displayName;
- (MGSImageAndText *)displayObject;
- (void)removeScript:(MGSScript *)script;
- (id)publishedScriptManager;
- (void)setDictionary:(NSMutableDictionary *)dict;

- (NSInteger)publishedCount;
- (void)removeUnpublishedItems;

- (id)initForScriptObjects;

- (NSMutableDictionary *)dictionary;
- (NSMutableDictionary *)mutableDeepCopyOfDictionary;

- (NSCellStateValue)publishedCellState;

- (void)sortUsingDescriptors:(NSArray *)descriptors;
- (void)removeScriptCode;
- (void)setScriptStatus:(MGSScriptStatus)status;
- (NSMutableDictionary *)editDictionaryCopy;
- (NSMutableDictionary *)changeDictionaryCopy;
- (NSMutableArray *)changeArrayCopy;
- (NSDictionary *)scriptDictionaryWithUUIDKeys;
- (void)setDisplayImage:(NSImage *)image;
- (NSArray *)changeArrayScheduleForDelete;

- (NSMutableDictionary *)editDictionaryForScripts:(NSArray *)scripts;
- (NSMutableDictionary *)editDictionaryForScript:(MGSScript *)script;

// scheduling changes to property: published
- (void)acceptSchedulePublished;
- (void)setSchedulePublished:(BOOL)value;
- (void)undoSchedulePublished;

// scheduling delete
- (void)undoScheduleDelete;
- (void)acceptScheduleDelete;

// scheduling save
- (void)acceptScheduleSave;
@end
